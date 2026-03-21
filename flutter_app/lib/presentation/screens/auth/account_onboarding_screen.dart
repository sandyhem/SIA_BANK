import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/account_models.dart';
import '../../../data/models/auth_models.dart';

class AccountOnboardingScreen extends ConsumerStatefulWidget {
  final int userId;
  final String fullName;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? dateOfBirth;
  final String? panNumber;
  final String? aadhaarNumber;

  const AccountOnboardingScreen({
    Key? key,
    required this.userId,
    this.fullName = '',
    this.phoneNumber,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.dateOfBirth,
    this.panNumber,
    this.aadhaarNumber,
  }) : super(key: key);

  @override
  ConsumerState<AccountOnboardingScreen> createState() =>
      _AccountOnboardingScreenState();
}

class _AccountOnboardingScreenState
    extends ConsumerState<AccountOnboardingScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  late TextEditingController _panController;
  late TextEditingController _aadhaarController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late TextEditingController _accountNameController;
  late TextEditingController _initialBalanceController;

  bool _isSubmitting = false;
  String? _errorMessage;
  String _accountType = 'SAVINGS';
  bool _idDocumentUploaded = false;
  bool _selfieUploaded = false;
  bool _kycSubmitted = false;
  bool _kycRejected = false;
  String _kycStatus = 'NOT_STARTED';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _phoneController = TextEditingController(text: widget.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.address ?? '');
    _dobController = TextEditingController(text: widget.dateOfBirth ?? '');
    _panController = TextEditingController(text: widget.panNumber ?? '');
    _aadhaarController =
        TextEditingController(text: widget.aadhaarNumber ?? '');
    _cityController = TextEditingController(text: widget.city ?? '');
    _stateController = TextEditingController(text: widget.state ?? '');
    _postalCodeController =
        TextEditingController(text: widget.postalCode ?? '');
    _countryController = TextEditingController(text: widget.country ?? 'India');
    _accountNameController = TextEditingController();
    _initialBalanceController = TextEditingController(text: '1000');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _accountNameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final dob = _dobController.text.trim();
    final pan = _panController.text.trim().toUpperCase();
    final aadhaar = _aadhaarController.text.trim();
    final accountName = _accountNameController.text.trim();

    if (fullName.isEmpty) {
      setState(() => _errorMessage = 'Full name is required');
      return false;
    }

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Phone is required');
      return false;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => _errorMessage = 'Phone must be exactly 10 digits');
      return false;
    }

    if (address.isEmpty) {
      setState(() => _errorMessage = 'Address is required');
      return false;
    }

    if (dob.isEmpty) {
      setState(() => _errorMessage = 'Date of birth is required');
      return false;
    }

    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)) {
      setState(() => _errorMessage = 'Date of birth must be YYYY-MM-DD');
      return false;
    }

    if (pan.isEmpty) {
      setState(() => _errorMessage = 'PAN is required');
      return false;
    }

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
      setState(() => _errorMessage = 'PAN format should be like ABCDE1234F');
      return false;
    }

    if (aadhaar.isEmpty) {
      setState(() => _errorMessage = 'Aadhaar is required');
      return false;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      setState(() => _errorMessage = 'Aadhaar must be 12 digits');
      return false;
    }

    if (accountName.isEmpty) {
      setState(() => _errorMessage = 'Account name is required');
      return false;
    }

    if (!_idDocumentUploaded) {
      setState(() => _errorMessage = 'Upload ID document before continuing');
      return false;
    }

    if (!_selfieUploaded) {
      setState(
          () => _errorMessage = 'Upload selfie verification before continuing');
      return false;
    }

    final initialBalance = double.tryParse(
        _initialBalanceController.text.trim() == ''
            ? '0'
            : _initialBalanceController.text.trim());
    if (initialBalance == null || initialBalance <= 0) {
      setState(() => _errorMessage = 'Initial balance must be greater than 0');
      return false;
    }

    return true;
  }

  String _cleanError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }

        final errorField = data['error'];
        if (errorField is String && errorField.trim().isNotEmpty) {
          return errorField.trim();
        }
      }

      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }

      final statusCode = error.response?.statusCode;
      if (statusCode == 403) {
        return 'Account opening is blocked until KYC verification is completed.';
      }

      return error.message ?? 'Request failed';
    }

    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  Future<void> _submitOnboarding() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final api = ref.read(apiServiceProvider);

    try {
      try {
        await api.createCustomer(
          widget.userId,
          CreateCustomerRequest(
            fullName: _fullNameController.text.trim(),
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
        );
      } catch (e) {
        final message = _cleanError(e).toLowerCase();
        if (!message.contains('already exists')) {
          rethrow;
        }
      }

      try {
        final createdAccount = await api.createAccount(
          CreateAccountRequest(
            userId: widget.userId,
            accountType: _accountType,
            accountName: _accountNameController.text.trim(),
            initialBalance: double.parse(_initialBalanceController.text.trim()),
          ),
        );

        if (!mounted) return;
        final simulatedRejected =
            _panController.text.trim().toUpperCase().endsWith('Z');
        if (simulatedRejected) {
          setState(() {
            _kycRejected = true;
            _kycStatus = 'REJECTED';
            _rejectionReason =
                'PAN validation mismatch with uploaded document. Please re-upload clear KYC proof.';
            _isSubmitting = false;
          });
          return;
        }

        final accountStatus = createdAccount.status.toUpperCase();
        setState(() {
          _kycSubmitted = true;
          _kycStatus = accountStatus == 'ACTIVE' ? 'VERIFIED' : 'PENDING';
        });
        final message = accountStatus == 'ACTIVE'
            ? 'Account created successfully.'
            : 'Account created and sent for admin KYC verification. It will be activated after approval.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } catch (e) {
        final message = _cleanError(e);
        final statusCode = e is DioException ? e.response?.statusCode : null;

        if (!mounted) return;
        if (statusCode == 403 ||
            message.toLowerCase().contains('forbidden') ||
            message.toLowerCase().contains('kyc') ||
            message.toLowerCase().contains('active')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile created. Account opening is pending KYC verification.',
              ),
            ),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
          return;
        }
        rethrow;
      }
    } catch (e) {
      setState(() => _errorMessage = _cleanError(e));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildKycStepChip(String label, bool done) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: done
            ? AppTheme.accentColor.withValues(alpha: 0.15)
            : AppTheme.borderColor.withValues(alpha: 0.25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13.sp,
            color: done ? AppTheme.accentColor : AppTheme.textLight,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: done ? AppTheme.accentColor : AppTheme.textLight,
              fontWeight: FontWeight.w600,
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
        title: const Text('Complete Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KYC Journey',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [
                        _buildKycStepChip(
                          'Document Upload',
                          _idDocumentUploaded,
                        ),
                        _buildKycStepChip(
                          'Selfie Match',
                          _selfieUploaded,
                        ),
                        _buildKycStepChip(
                          'Submitted',
                          _kycSubmitted,
                        ),
                        _buildKycStepChip(
                          _kycStatus,
                          _kycStatus == 'VERIFIED' || _kycStatus == 'PENDING',
                        ),
                      ],
                    ),
                    if (_kycRejected && _rejectionReason != null) ...[
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppTheme.dangerColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejection reason',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.dangerColor,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _rejectionReason!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _idDocumentUploaded = true;
                                _kycStatus = 'INITIATED';
                                _errorMessage = null;
                              });
                            },
                      icon: Icon(
                        _idDocumentUploaded
                            ? Icons.check_circle
                            : Icons.upload_file,
                      ),
                      label: Text(_idDocumentUploaded
                          ? 'Document Uploaded'
                          : 'Upload Document'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _selfieUploaded = true;
                                _kycStatus = 'INITIATED';
                                _errorMessage = null;
                              });
                            },
                      icon: Icon(
                        _selfieUploaded
                            ? Icons.check_circle
                            : Icons.camera_alt_outlined,
                      ),
                      label: Text(_selfieUploaded
                          ? 'Selfie Verified'
                          : 'Upload Selfie'),
                    ),
                  ),
                ],
              ),
              if (_kycRejected) ...[
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _kycRejected = false;
                              _kycSubmitted = false;
                              _kycStatus = 'INITIATED';
                              _rejectionReason = null;
                              _idDocumentUploaded = false;
                              _selfieUploaded = false;
                            });
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry KYC'),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Text(
                'One-time setup for account opening',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (10 digits)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City (optional)',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State (optional)',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code (optional)',
                        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country (optional)',
                        prefixIcon: Icon(Icons.public_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _dobController,
                onChanged: (_) {
                  if (_errorMessage != null &&
                      (_errorMessage!.contains('Date of birth') ||
                          _errorMessage!.contains('YYYY-MM-DD'))) {
                    setState(() => _errorMessage = null);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Date Of Birth (YYYY-MM-DD)',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _panController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'PAN',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aadhaar',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
              ),
              SizedBox(height: 20.h),
              DropdownButtonFormField<String>(
                initialValue: _accountType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'SAVINGS', child: Text('SAVINGS')),
                  DropdownMenuItem(value: 'CURRENT', child: Text('CURRENT')),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _accountType = value);
                        }
                      },
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _initialBalanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.dangerColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppTheme.dangerColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOnboarding,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('Create Profile & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
