import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transaction_models.dart';
import '../screens/home_screen.dart';

class TransactionHistoryWidget extends ConsumerWidget {
  final String accountNumber;
  final int? limit;

  const TransactionHistoryWidget({
    Key? key,
    required this.accountNumber,
    this.limit = 5,
  }) : super(key: key);

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
      default:
        return Colors.red;
    }
  }

  IconData _getTransactionIcon(TransactionDTO transaction) {
    final isSent = transaction.getFromAccount == accountNumber;
    return isSent ? Icons.arrow_upward : Icons.arrow_downward;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsyncValue =
        ref.watch(transactionHistoryProvider(accountNumber));

    return transactionsAsyncValue.when(
      loading: () => Center(
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: const CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Padding(
        padding: EdgeInsets.all(16.h),
        child: Text(
          'Error loading transactions: ${err.toString()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (transactions) {
        final displayTransactions =
            limit != null ? transactions.take(limit!).toList() : transactions;

        if (displayTransactions.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 48.w,
                  color: AppTheme.textLight,
                ),
                SizedBox(height: 12.h),
                Text(
                  'No Transactions Yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your transactions will appear here',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayTransactions.length,
          separatorBuilder: (context, index) => Divider(
            height: 1.h,
            color: AppTheme.textLight.withOpacity(0.1),
          ),
          itemBuilder: (context, index) {
            final transaction = displayTransactions[index];
            final isSent = transaction.getFromAccount == accountNumber;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          (isSent ? Colors.red : Colors.green).withOpacity(0.1),
                    ),
                    child: Center(
                      child: Icon(
                        _getTransactionIcon(transaction),
                        size: 20.w,
                        color: isSent ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.getDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${_formatDate(transaction.getDate)} • ${_formatTime(transaction.getDate)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Amount and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isSent ? '-' : '+'}₹${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isSent ? Colors.red : Colors.green,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          transaction.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(transaction.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
