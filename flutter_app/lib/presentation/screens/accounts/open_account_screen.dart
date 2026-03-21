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
  bool _isLoadingExistingAccounts = true;
  String? _errorMessage;
  bool _isAccountNameManuallyEdited = false;
  final Set<String> _ownedTypes = <String>{};
  List<AccountDTO> _existingAccounts = const <AccountDTO>[];
  static const List<String> _supportedTypes = <String>['SAVINGS', 'CURRENT'];
  static const Map<String, double> _minimumBalanceByType = <String, double>{
    'SAVINGS': 1000,
    'CURRENT': 5000,
  };

  @override
  void initState() {
    super.initState();
    _loadExistingAccounts();
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  double get _minimumRequiredBalance {
    return _minimumBalanceByType[_accountType] ?? 1000;
  }

  String _defaultAccountNameForType(String type) {
    switch (type.toUpperCase()) {
      case 'CURRENT':
        return 'Current Account';
      case 'SAVINGS':
      default:
        return 'Savings Account';
    }
  }

  void _syncSuggestedAccountName({required String type, bool force = false}) {
    if (_isAccountNameManuallyEdited && !force) {
      return;
    }

    final suggestion = _defaultAccountNameForType(type);
    _accountNameController.text = suggestion;
    _accountNameController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
  }

  void _syncMinimumBalanceHint() {
    final parsed = double.tryParse(_initialBalanceController.text.trim());
    if (parsed == null || parsed < _minimumRequiredBalance) {
      final formatted = _minimumRequiredBalance.toStringAsFixed(0);
      _initialBalanceController.text = formatted;
      _initialBalanceController.selection = TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      );
    }
  }

  Future<void> _loadExistingAccounts() async {
    setState(() {
      _isLoadingExistingAccounts = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final accounts = await api.getAccountsByCustomer(widget.userId);
      final owned = accounts.map((a) => a.type.toUpperCase()).toSet();

      String selected = _accountType;
      if (owned.contains(selected)) {
        selected = _supportedTypes.firstWhere(
          (type) => !owned.contains(type),
          orElse: () => _accountType,
        );
      }

      if (!mounted) return;
      setState(() {
        _ownedTypes
          ..clear()
          ..addAll(owned);
        _existingAccounts = accounts;
        _accountType = selected;
      });
      _syncSuggestedAccountName(type: selected, force: true);
      _syncMinimumBalanceHint();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _cleanError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoadingExistingAccounts = false);
      }
    }
  }

  bool get _allSupportedTypesAlreadyOwned {
    return _supportedTypes.every((type) => _ownedTypes.contains(type));
  }

  bool _isTypeSelectable(String type) {
    return !_ownedTypes.contains(type.toUpperCase());
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

    if (!_isTypeSelectable(_accountType)) {
      setState(() {
        _errorMessage =
            'You already have a $_accountType account. Please choose another account type.';
      });
      return;
    }

    if (initialBalance == null || initialBalance <= 0) {
      setState(() => _errorMessage = 'Initial balance must be greater than 0');
      return;
    }

    if (initialBalance < _minimumRequiredBalance) {
      setState(() {
        _errorMessage =
            'Minimum opening balance for $_accountType is ₹${_minimumRequiredBalance.toStringAsFixed(0)}';
      });
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
              if (_isLoadingExistingAccounts)
                const LinearProgressIndicator(minHeight: 2),
              if (_ownedTypes.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  'Existing account types: ${_ownedTypes.join(', ')}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
              if (_allSupportedTypesAlreadyOwned) ...[
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'You already have all available account types.',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: _accountType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: _supportedTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        enabled: _isTypeSelectable(type),
                        child: Text(
                          _isTypeSelectable(type)
                              ? type
                              : '$type (Already exists)',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting || _allSupportedTypesAlreadyOwned
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _accountType = value);
                          _syncSuggestedAccountName(type: value);
                          _syncMinimumBalanceHint();
                        }
                      },
              ),
              SizedBox(height: 12.h),
              if (_existingAccounts.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Accounts',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ..._existingAccounts.map(
                        (acc) => Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${acc.type.toUpperCase()} • ${acc.accountNumber}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${acc.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              TextField(
                controller: _accountNameController,
                enabled: !_isSubmitting,
                onChanged: (value) {
                  final trimmed = value.trim();
                  final suggestion = _defaultAccountNameForType(_accountType);
                  _isAccountNameManuallyEdited =
                      trimmed.isNotEmpty && trimmed != suggestion;
                },
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
              SizedBox(height: 6.h),
              Text(
                'Minimum for $_accountType: ₹${_minimumRequiredBalance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textLight,
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
                  onPressed: _isSubmitting ||
                          _allSupportedTypesAlreadyOwned ||
                          _isLoadingExistingAccounts
                      ? null
                      : _openAccount,
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
