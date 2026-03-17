import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/transaction_models.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final String? sourceAccountNumber;

  const TransferScreen({Key? key, this.sourceAccountNumber}) : super(key: key);

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  late TextEditingController _fromAccountController;
  late TextEditingController _toAccountController;
  late TextEditingController _amountController;
  late TextEditingController _narrationController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<String> _savedBeneficiaries = const <String>[];
  static const double _dailyTransferLimit = 1000000.0;

  @override
  void initState() {
    super.initState();
    _fromAccountController = TextEditingController(
      text: widget.sourceAccountNumber ?? '',
    );
    _toAccountController = TextEditingController();
    _amountController = TextEditingController();
    _narrationController = TextEditingController();
    _loadSavedBeneficiaries();
  }

  @override
  void dispose() {
    _fromAccountController.dispose();
    _toAccountController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
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
        setState(() {
          _isLoading = false;
          _errorMessage =
              'MPIN is not set for this account. Please register/login again to configure MPIN.';
        });
        return;
      }

      final isMpinVerified = await _promptAndVerifyMpin();
      if (!isMpinVerified) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid MPIN. Transfer cancelled.';
        });
        return;
      }

      final amount = double.parse(_amountController.text);
      final withinLimit = await _validateDailyLimit(amount);
      if (!withinLimit) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final request = TransferRequestDTO(
        fromAccount: _fromAccountController.text,
        toAccount: _toAccountController.text,
        amount: amount,
        narration: _narrationController.text.isEmpty
            ? 'Transfer from ${_fromAccountController.text} to ${_toAccountController.text}'
            : _narrationController.text,
      );

      final response = await apiService.transferFunds(request);

      // YONO-style quick transfer support: remember successful recipients.
      if (_toAccountController.text.trim() !=
          _fromAccountController.text.trim()) {
        await apiService.saveBeneficiaryForCurrentUser(
          _toAccountController.text.trim(),
        );
        await _loadSavedBeneficiaries();
      }

      setState(() => _successMessage = response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer completed successfully!')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Transfer failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedBeneficiaries() async {
    final apiService = ref.read(apiServiceProvider);
    final beneficiaries =
        await apiService.getSavedBeneficiariesForCurrentUser();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedBeneficiaries = beneficiaries;
    });
  }

  bool _validateInputs() {
    if (_fromAccountController.text.isEmpty ||
        _toAccountController.text.isEmpty ||
        _amountController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return false;
    }

    if (_fromAccountController.text == _toAccountController.text) {
      setState(
        () => _errorMessage = 'From and To accounts cannot be the same',
      );
      return false;
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
    final transactions =
        await apiService.getTransactionHistory(_fromAccountController.text);
    final now = DateTime.now();

    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    double todaySent = 0;
    for (final txn in transactions) {
      if (txn.getFromAccount != _fromAccountController.text) {
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
    if (projected > _dailyTransferLimit) {
      setState(() {
        _errorMessage =
            'Daily transfer limit exceeded. Today sent: ₹${todaySent.toStringAsFixed(2)}, limit: ₹${_dailyTransferLimit.toStringAsFixed(2)}';
      });
      return false;
    }

    return true;
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_fromAccountController.text.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Number',
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
                                _fromAccountController.text,
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
                                        text: _fromAccountController.text),
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
                      controller: _fromAccountController,
                      decoration: const InputDecoration(
                        labelText: 'Enter account number',
                        prefixIcon: Icon(Icons.account_balance),
                        hintText: '1234567890',
                        border: InputBorder.none,
                      ),
                      enabled:
                          !_isLoading && widget.sourceAccountNumber == null,
                    ),
                  ],
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
                        hintText: '0987654321',
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
                  hintText: '1000',
                ),
                enabled: !_isLoading,
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
                  labelText: 'e.g., Room rent, Salary',
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
