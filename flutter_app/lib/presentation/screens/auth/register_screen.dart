import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/auth_models.dart';
import 'account_onboarding_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late TextEditingController _panController;
  late TextEditingController _aadhaarController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _mpinController;
  late TextEditingController _confirmMpinController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureMpin = true;
  bool _obscureConfirmMpin = true;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController(text: 'India');
    _panController = TextEditingController();
    _aadhaarController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _mpinController = TextEditingController();
    _confirmMpinController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mpinController.dispose();
    _confirmMpinController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final request = RegisterRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final response = await apiService.register(request);
      await apiService.setMpinForUser(
        userId: response.userId,
        mpin: _mpinController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration successful for ${_usernameController.text}',
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AccountOnboardingScreen(
              userId: response.userId,
              fullName:
                  '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
              phoneNumber: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              postalCode: _postalCodeController.text.trim(),
              country: _countryController.text.trim(),
              dateOfBirth: _dobController.text.trim(),
              panNumber: _panController.text.trim().toUpperCase(),
              aadhaarNumber: _aadhaarController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = _formatErrorMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateInputs() {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _dobController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _panController.text.trim().isEmpty ||
        _aadhaarController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _mpinController.text.isEmpty ||
        _confirmMpinController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return false;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim())) {
      setState(() => _errorMessage = 'Phone must be exactly 10 digits');
      return false;
    }

    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(_dobController.text.trim())) {
      setState(() => _errorMessage = 'Date of birth must be YYYY-MM-DD');
      return false;
    }

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$')
        .hasMatch(_panController.text.trim().toUpperCase())) {
      setState(() => _errorMessage = 'PAN format should be like ABCDE1234F');
      return false;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(_aadhaarController.text.trim())) {
      setState(() => _errorMessage = 'Aadhaar must be 12 digits');
      return false;
    }

    final postal = _postalCodeController.text.trim();
    if (postal.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(postal)) {
      setState(() => _errorMessage = 'Postal code must be 6 digits');
      return false;
    }

    if (!_emailController.text.trim().contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return false;
    }

    if (_usernameController.text.trim().length < 3) {
      setState(() => _errorMessage = 'Username must be at least 3 characters');
      return false;
    }

    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return false;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(_mpinController.text)) {
      setState(() => _errorMessage = 'MPIN must be exactly 4 digits');
      return false;
    }

    if (_mpinController.text != _confirmMpinController.text) {
      setState(() => _errorMessage = 'MPIN does not match');
      return false;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please agree to terms and conditions');
      return false;
    }

    return true;
  }

  String _formatErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppTheme.dangerColor, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.dangerColor,
                fontSize: 12.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join SIA Bank',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Create an account to get started',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 32.h),

              // First Name
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'John',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 16.h),

              // Last Name
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Doe',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'john@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              Text(
                'Identity & Contact Details',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 10.h),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              TextField(
                controller: _dobController,
                keyboardType: TextInputType.datetime,
                onChanged: (_) {
                  if (_errorMessage != null &&
                      _errorMessage!.contains('Date of birth')) {
                    setState(() => _errorMessage = null);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Date Of Birth',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'House/Street/Area',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        hintText: 'State',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code',
                        hintText: '6 digits',
                        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        hintText: 'Country',
                        prefixIcon: Icon(Icons.public_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              TextField(
                controller: _panController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'PAN',
                  hintText: 'ABCDE1234F',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              TextField(
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aadhaar Number',
                  hintText: '12-digit Aadhaar',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              // Username
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'johndoe123',
                  prefixIcon: Icon(Icons.account_circle_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 8 characters',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildErrorBanner(_errorMessage!),
                ),

              // MPIN
              TextField(
                controller: _mpinController,
                keyboardType: TextInputType.number,
                obscureText: _obscureMpin,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Set 4-digit MPIN',
                  hintText: 'Enter 4-digit MPIN',
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureMpin
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscureMpin = !_obscureMpin);
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Confirm MPIN
              TextField(
                controller: _confirmMpinController,
                keyboardType: TextInputType.number,
                obscureText: _obscureConfirmMpin,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Confirm MPIN',
                  hintText: 'Re-enter 4-digit MPIN',
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmMpin
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(
                        () => _obscureConfirmMpin = !_obscureConfirmMpin,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              // Terms Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _agreedToTerms = value ?? false);
                          },
                    activeColor: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'I agree to ',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' and ',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  GestureDetector(
                    onTap:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
