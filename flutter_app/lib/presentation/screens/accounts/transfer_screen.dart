import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/account_models.dart';
import '../../../data/models/transaction_models.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final String? sourceAccountNumber;
  final String? initialToAccountNumber;

  const TransferScreen({
    Key? key,
    this.sourceAccountNumber,
    this.initialToAccountNumber,
  }) : super(key: key);

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  late TextEditingController _toAccountController;
  late TextEditingController _amountController;
  late TextEditingController _narrationController;

  bool _isLoading = false;
  bool _isLoadingAccounts = true;
  String? _errorMessage;
  String? _successMessage;
  List<String> _savedBeneficiaries = const <String>[];
  List<AccountDTO> _accounts = const <AccountDTO>[];
  String? _selectedFromAccount;
  static const double _dailyTransferLimit = 1000000.0;
  static const List<double> _quickAmounts = <double>[500, 1000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _toAccountController = TextEditingController();
    if ((widget.initialToAccountNumber ?? '').trim().isNotEmpty) {
      _toAccountController.text = widget.initialToAccountNumber!.trim();
    }
    _amountController = TextEditingController();
    _narrationController = TextEditingController();
    _selectedFromAccount = widget.sourceAccountNumber?.trim();
    _loadAccounts();
    _loadSavedBeneficiaries();
  }

  AccountDTO? get _selectedAccountModel {
    final selected = _selectedFromAccount;
    if (selected == null || selected.trim().isEmpty) {
      return null;
    }
    for (final account in _accounts) {
      if (account.accountNumber == selected) {
        return account;
      }
    }
    return null;
  }

  void _applyQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(2);
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    setState(() {
      _errorMessage = null;
    });
  }

  void _useMaximumTransferable() {
    final selected = _selectedAccountModel;
    if (selected == null) {
      setState(() {
        _errorMessage = 'Select a source account first.';
      });
      return;
    }

    if (selected.balance <= 0) {
      setState(() {
        _errorMessage = 'Selected account has insufficient balance.';
      });
      return;
    }

    _applyQuickAmount(selected.balance);
  }

  @override
  void dispose() {
    _toAccountController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoadingAccounts = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final userId = await api.getCurrentUserId();
      if (userId == null || userId <= 0) {
        throw Exception('No active session found. Please login again.');
      }

      final accounts = await api.getAccountsByCustomer(userId);
      if (!mounted) {
        return;
      }

      final selected = _selectedFromAccount;
      final hasSelected =
          selected != null && accounts.any((a) => a.accountNumber == selected);

      setState(() {
        _accounts = accounts;
        _selectedFromAccount = hasSelected
            ? selected
            : (accounts.isNotEmpty ? accounts.first.accountNumber : null);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to load accounts: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingAccounts = false);
      }
    }
  }

  Future<void> _handleTransfer() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final hasMpin = await apiService.hasMpinForCurrentUser();
      if (!hasMpin) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage =
              'MPIN is not set for this account. Please register/login again to configure MPIN.';
        });
        return;
      }

      final isMpinVerified = await _promptAndVerifyMpin();
      if (!isMpinVerified) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid MPIN. Transfer cancelled.';
        });
        return;
      }

      final amount = double.parse(_amountController.text);
      final withinLimit = await _validateDailyLimit(amount);
      if (!withinLimit) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final request = TransferRequestDTO(
        fromAccount: _selectedFromAccount!.trim(),
        toAccount: _toAccountController.text,
        amount: amount,
        narration: _narrationController.text.isEmpty
            ? 'Digital funds transfer'
            : _narrationController.text,
      );

      final response = await apiService.transferFunds(request);

      // YONO-style quick transfer support: remember successful recipients.
      if (_toAccountController.text.trim() != _selectedFromAccount!.trim()) {
        try {
          await apiService.addBeneficiary(
            nickname: 'Quick Pay ${_toAccountController.text.trim()}',
            accountNumber: _toAccountController.text.trim(),
            bankName: 'SIA Bank',
          );
        } catch (_) {
          // Best effort only. Local fallback still preserves UX.
        }
        await apiService.saveBeneficiaryForCurrentUser(
          _toAccountController.text.trim(),
        );
        await _loadSavedBeneficiaries();
      }

      if (!mounted) {
        return;
      }
      setState(() => _successMessage = response);
      _updateBeneficiaryUsage(amount);

      if (mounted) {
        ref.invalidate(beneficiariesProvider);
        await _showPaymentSuccessAnimation(
          amount: amount,
          toAccount: _toAccountController.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pop(_selectedFromAccount!.trim());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Transfer failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSavedBeneficiaries() async {
    final apiService = ref.read(apiServiceProvider);
    List<String> beneficiaries;
    try {
      final backendBeneficiaries = await apiService.getBeneficiaries();
      beneficiaries = backendBeneficiaries
          .map((b) => b.accountNumber)
          .where((value) => value.trim().isNotEmpty)
          .toSet()
          .toList();
      beneficiaries.sort();
    } catch (_) {
      beneficiaries = await apiService.getSavedBeneficiariesForCurrentUser();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _savedBeneficiaries = beneficiaries;
    });
  }

  bool _validateInputs() {
    if ((_selectedFromAccount ?? '').isEmpty ||
        _toAccountController.text.isEmpty ||
        _amountController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return false;
    }

    if (_selectedFromAccount!.trim() == _toAccountController.text.trim()) {
      setState(
        () => _errorMessage = 'From and To accounts cannot be the same',
      );
      return false;
    }

    final controls = ref.read(accountControlProvider);
    final control = controls[_selectedFromAccount!.trim()];
    if (control?.isFrozen == true) {
      setState(() {
        _errorMessage =
            'This account is frozen. Unfreeze it in account settings before transferring.';
      });
      return false;
    }

    final workflows = ref.read(beneficiaryWorkflowProvider);
    final beneficiary = workflows[_toAccountController.text.trim()];
    if (beneficiary != null) {
      if (!beneficiary.verified) {
        setState(() {
          _errorMessage =
              'Beneficiary not verified. Complete OTP verification first.';
        });
        return false;
      }
      if (!beneficiary.isActive) {
        setState(() {
          _errorMessage =
              'Beneficiary is in cooling period. Activation at ${DateFormat('dd MMM, hh:mm a').format(beneficiary.activationTime)}.';
        });
        return false;
      }
    }

    try {
      final amount = double.parse(_amountController.text);
      if (amount <= 0) {
        setState(() => _errorMessage = 'Amount must be greater than 0');
        return false;
      }
    } catch (e) {
      setState(() => _errorMessage = 'Invalid amount');
      return false;
    }

    return true;
  }

  Future<bool> _promptAndVerifyMpin() async {
    final mpinController = TextEditingController();
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Enter MPIN'),
              content: TextField(
                controller: mpinController,
                keyboardType: TextInputType.number,
                obscureText: obscure,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: '4-digit MPIN',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setLocalState(() => obscure = !obscure);
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return false;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(mpinController.text)) {
      return false;
    }
    final apiService = ref.read(apiServiceProvider);
    return apiService.verifyMpinForCurrentUser(mpinController.text);
  }

  Future<bool> _validateDailyLimit(double newAmount) async {
    final apiService = ref.read(apiServiceProvider);
    final sourceAccount = _selectedFromAccount!.trim();
    final transactions = await apiService.getTransactionHistory(sourceAccount);
    final now = DateTime.now();

    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    double todaySent = 0;
    for (final txn in transactions) {
      if (txn.getFromAccount != sourceAccount) {
        continue;
      }
      final status = txn.status.toUpperCase();
      if (status != 'SUCCESS' && status != 'COMPLETED') {
        continue;
      }
      final rawDate = txn.getDate;
      if (rawDate.isEmpty) {
        continue;
      }
      DateTime? parsed;
      try {
        parsed = DateTime.parse(rawDate);
      } catch (_) {
        parsed = null;
      }
      if (parsed == null || !isSameDay(parsed, now)) {
        continue;
      }
      todaySent += txn.amount;
    }

    final projected = todaySent + newAmount;
    final controls = ref.read(accountControlProvider);
    final customLimit = controls[sourceAccount]?.dailyLimit;
    final effectiveLimit = customLimit ?? _dailyTransferLimit;
    if (projected > effectiveLimit) {
      setState(() {
        _errorMessage =
            'Daily transfer limit exceeded. Today sent: ₹${todaySent.toStringAsFixed(2)}, limit: ₹${effectiveLimit.toStringAsFixed(2)}';
      });
      return false;
    }

    final workflows = ref.read(beneficiaryWorkflowProvider);
    final toAccount = _toAccountController.text.trim();
    final beneficiary = workflows[toAccount];
    if (beneficiary != null) {
      final isSameDayUsage = beneficiary.usageDate.year == now.year &&
          beneficiary.usageDate.month == now.month &&
          beneficiary.usageDate.day == now.day;
      final usedToday = isSameDayUsage ? beneficiary.usedToday : 0.0;
      final projectedForBeneficiary = usedToday + newAmount;
      if (projectedForBeneficiary > beneficiary.dailyCap) {
        setState(() {
          _errorMessage =
              'Beneficiary cap exceeded. Used: ₹${usedToday.toStringAsFixed(2)} / ₹${beneficiary.dailyCap.toStringAsFixed(2)}';
        });
        return false;
      }
    }

    return true;
  }

  void _updateBeneficiaryUsage(double amount) {
    final toAccount = _toAccountController.text.trim();
    final workflows = Map<String, BeneficiaryWorkflowState>.from(
        ref.read(beneficiaryWorkflowProvider));
    final beneficiary = workflows[toAccount];
    if (beneficiary == null) {
      return;
    }

    final now = DateTime.now();
    final isSameDayUsage = beneficiary.usageDate.year == now.year &&
        beneficiary.usageDate.month == now.month &&
        beneficiary.usageDate.day == now.day;
    final base = isSameDayUsage ? beneficiary.usedToday : 0.0;

    workflows[toAccount] = beneficiary.copyWith(
      usedToday: base + amount,
      usageDate: now,
    );
    ref.read(beneficiaryWorkflowProvider.notifier).state = workflows;
  }

  Future<void> _showPaymentSuccessAnimation({
    required double amount,
    required String toAccount,
  }) async {
    if (!mounted) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.7, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              onEnd: () {
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (!navigator.mounted) {
                    return;
                  }
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                });
              },
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Colors.green.withOpacity(0.12),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 42.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Payment Successful',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'INR ${amount.toStringAsFixed(2)} sent to $toAccount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
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
              // Progress Indicator
              Text(
                'Transfer Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 24.h),

              // From Account
              Text(
                'From Account',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: _isLoadingAccounts
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: const LinearProgressIndicator(minHeight: 2),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedFromAccount,
                          hint: const Text('Select account'),
                          items: _accounts
                              .map(
                                (account) => DropdownMenuItem<String>(
                                  value: account.accountNumber,
                                  child: Text(
                                    '${account.accountNumber} • ${account.type.toUpperCase()}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _isLoading ||
                                  _accounts.isEmpty ||
                                  widget.sourceAccountNumber != null
                              ? null
                              : (value) {
                                  setState(() => _selectedFromAccount = value);
                                },
                        ),
                      ),
              ),
              if (!_isLoadingAccounts && _accounts.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    'No eligible account available for transfer.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              SizedBox(height: 20.h),

              // To Account
              Text(
                'To Account',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              if (_savedBeneficiaries.isNotEmpty) ...[
                Text(
                  'Saved Beneficiaries',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _savedBeneficiaries
                      .map(
                        (beneficiary) => ActionChip(
                          label: Text(
                            beneficiary,
                            style: TextStyle(fontSize: 11.sp),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _toAccountController.text = beneficiary;
                                  });
                                },
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 10.h),
              ],
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_toAccountController.text.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recipient Account Number',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textLight,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _toAccountController.text,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Monaco',
                                  letterSpacing: 1.0,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_outlined),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                        text: _toAccountController.text),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Account number copied!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                iconSize: 18.sp,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    TextField(
                      controller: _toAccountController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient account number',
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Enter beneficiary account number',
                        border: InputBorder.none,
                      ),
                      enabled: !_isLoading,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Amount
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                  prefixText: '₹ ',
                  hintText: 'Amount in INR',
                ),
                enabled: !_isLoading,
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _quickAmounts
                          .map(
                            (amount) => ActionChip(
                              label: Text(
                                '₹${amount.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 11.sp),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => _applyQuickAmount(amount),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _useMaximumTransferable,
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Use Max'),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Narration/Reference
              Text(
                'Reference/Narration (Optional)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _narrationController,
                decoration: const InputDecoration(
                  labelText: 'Payment reference',
                  hintText: 'Optional note for statement records',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
                enabled: !_isLoading,
              ),
              SizedBox(height: 8.h),
              Text(
                'Add a note so the recipient knows what this transfer is for',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textLight,
                ),
              ),
              SizedBox(height: 24.h),

              // Error/Success Messages
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppTheme.dangerColor),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppTheme.dangerColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),

              if (_successMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppTheme.accentColor),
                    ),
                    child: Text(
                      _successMessage!,
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),

              // Transfer Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleTransfer,
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
                          'Confirm Transfer',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),

              // Info Box
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer Information',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _buildInfoRow('Processing Time', 'Instant to 2 hours'),
                    SizedBox(height: 6.h),
                    _buildInfoRow('Charges', 'No charges'),
                    SizedBox(height: 6.h),
                    _buildInfoRow('Limit', '₹ 10,00,000 per day'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppTheme.textLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
