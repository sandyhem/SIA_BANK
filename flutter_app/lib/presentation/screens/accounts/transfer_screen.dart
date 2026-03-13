import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/transaction_models.dart';
import '../../../data/services/api_service.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _fromAccountController = TextEditingController();
    _toAccountController = TextEditingController();
    _amountController = TextEditingController();
    _narrationController = TextEditingController();
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
      final request = TransferRequestDTO(
        fromAccount: _fromAccountController.text,
        toAccount: _toAccountController.text,
        amount: double.parse(_amountController.text),
        narration: _narrationController.text.isEmpty ? null : _narrationController.text,
      );

      final response = await apiService.transferFunds(request);

      setState(() => _successMessage = response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer completed successfully!')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Transfer failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
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
        () =>
            _errorMessage = 'From and To accounts cannot be the same',
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
              TextField(
                controller: _fromAccountController,
                decoration: const InputDecoration(
                  labelText: 'Enter account number',
                  prefixIcon: Icon(Icons.account_balance),
                  hintText: '1234567890',
                ),
                enabled: !_isLoading,
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
              TextField(
                controller: _toAccountController,
                decoration: const InputDecoration(
                  labelText: 'Recipient account number',
                  prefixIcon: Icon(Icons.person),
                  hintText: '0987654321',
                ),
                enabled: !_isLoading,
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
