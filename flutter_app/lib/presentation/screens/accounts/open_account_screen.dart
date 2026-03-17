import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/account_models.dart';

class OpenAccountScreen extends ConsumerStatefulWidget {
  final int userId;

  const OpenAccountScreen({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<OpenAccountScreen> createState() => _OpenAccountScreenState();
}

class _OpenAccountScreenState extends ConsumerState<OpenAccountScreen> {
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _initialBalanceController =
      TextEditingController(text: '1000');

  String _accountType = 'SAVINGS';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _accountNameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  String _cleanError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
      return error.message ?? 'Request failed';
    }
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  Future<void> _openAccount() async {
    final accountName = _accountNameController.text.trim();
    final initialBalance = double.tryParse(
        _initialBalanceController.text.trim() == ''
            ? '0'
            : _initialBalanceController.text.trim());

    if (accountName.isEmpty) {
      setState(() => _errorMessage = 'Account name is required');
      return;
    }
    if (initialBalance == null || initialBalance <= 0) {
      setState(() => _errorMessage = 'Initial balance must be greater than 0');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final createdAccount = await api.createAccount(
        CreateAccountRequest(
          userId: widget.userId,
          accountType: _accountType,
          accountName: accountName,
          initialBalance: initialBalance,
        ),
      );

      if (!mounted) return;
      final isActive = createdAccount.status.toUpperCase() == 'ACTIVE';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Account created successfully.'
                : 'Account created. It will become active once KYC is verified.',
          ),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      setState(() => _errorMessage = _cleanError(e));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a new account',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16.h),
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
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _initialBalanceController,
                enabled: !_isSubmitting,
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
                  onPressed: _isSubmitting ? null : _openAccount,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('Open Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
