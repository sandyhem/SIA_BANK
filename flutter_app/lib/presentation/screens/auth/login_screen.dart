import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/auth_models.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final request = LoginRequest(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final response = await apiService.login(request);

      // Admin users do not manage accounts or balances, so MPIN gating is
      // not applicable. Skip the MPIN prompt entirely for admins.
      final isAdmin = (response.role ?? '').toUpperCase().contains('ADMIN');

      if (!isAdmin) {
        final hasMpin = await apiService.hasMpinForCurrentUser();
        if (!hasMpin) {
          final mpin = await _promptSetupMpin();
          if (mpin == null) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'MPIN setup is required to continue.';
            });
            return;
          }
          await apiService.setMpinForUser(userId: response.userId, mpin: mpin);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome back, User ${response.userId}!')),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() => _errorMessage = _formatErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  Future<String?> _promptSetupMpin() async {
    final mpinController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure1 = true;
    bool obscure2 = true;
    String? inlineError;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Set Your MPIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: mpinController,
                    keyboardType: TextInputType.number,
                    obscureText: obscure1,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: '4-digit MPIN',
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure1
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setLocalState(() => obscure1 = !obscure1);
                        },
                      ),
                    ),
                  ),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: obscure2,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Confirm MPIN',
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure2
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setLocalState(() => obscure2 = !obscure2);
                        },
                      ),
                    ),
                  ),
                  if (inlineError != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        inlineError!,
                        style: TextStyle(
                          color: AppTheme.dangerColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final mpin = mpinController.text.trim();
                    final confirm = confirmController.text.trim();
                    if (!RegExp(r'^\d{4}$').hasMatch(mpin)) {
                      setLocalState(
                        () => inlineError = 'MPIN must be exactly 4 digits',
                      );
                      return;
                    }
                    if (mpin != confirm) {
                      setLocalState(() => inlineError = 'MPIN does not match');
                      return;
                    }
                    Navigator.of(context).pop(mpin);
                  },
                  child: const Text('Save MPIN'),
                ),
              ],
            );
          },
        );
      },
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 36.sp,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Sign in to your SIA Bank account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
              SizedBox(height: 32.h),

              // Username Field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username or Email',
                  hintText: 'Enter username or email',
                  prefixIcon: const Icon(Icons.person_outline),
                  enabled: !_isLoading,
                ),
              ),
              SizedBox(height: 16.h),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
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
                  enabled: !_isLoading,
                ),
              ),
              SizedBox(height: 8.h),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: _buildErrorBanner(_errorMessage!),
                ),

              SizedBox(height: 24.h),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                          'Login',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 32.h),

              // Sign Up Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 14.sp,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14.sp,
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
