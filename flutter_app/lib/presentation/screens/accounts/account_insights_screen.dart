import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/transaction_models.dart';
import '../home_screen.dart';

class AccountInsightsScreen extends ConsumerStatefulWidget {
  const AccountInsightsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountInsightsScreen> createState() =>
      _AccountInsightsScreenState();
}

class _AccountInsightsScreenState extends ConsumerState<AccountInsightsScreen> {
  String? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account Insights')),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts found.'));
          }

          _selectedAccount ??= accounts.first.accountNumber;
          final insightsAsync =
              ref.watch(accountInsightsProvider(_selectedAccount!));

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              DropdownButtonFormField<String>(
                value: _selectedAccount,
                decoration: const InputDecoration(labelText: 'Account'),
                items: accounts
                    .map((a) => DropdownMenuItem<String>(
                          value: a.accountNumber,
                          child: Text(
                              '${a.accountNumber} - ${a.type.toUpperCase()}'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedAccount = v);
                },
              ),
              SizedBox(height: 16.h),
              insightsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Failed to load insights: $e'),
                data: (insights) => _buildInsights(context, insights),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInsights(BuildContext context, AccountInsightsDTO insights) {
    Widget tile(String label, String value, Color color) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
            SizedBox(height: 4.h),
            Text(value,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Column(
      children: [
        tile(
            'Total Transactions', '${insights.totalTransactions}', Colors.blue),
        SizedBox(height: 10.h),
        tile('Total Sent', '₹${insights.totalSent.toStringAsFixed(2)}',
            Colors.red),
        SizedBox(height: 10.h),
        tile('Total Received', '₹${insights.totalReceived.toStringAsFixed(2)}',
            Colors.green),
        SizedBox(height: 10.h),
        tile('Successful Sent',
            '₹${insights.totalSuccessSent.toStringAsFixed(2)}', Colors.orange),
        SizedBox(height: 10.h),
        tile(
            'Successful Received',
            '₹${insights.totalSuccessReceived.toStringAsFixed(2)}',
            Colors.teal),
        SizedBox(height: 10.h),
        tile(
          'Last Transaction',
          (insights.lastTransactionAt == null ||
                  insights.lastTransactionAt!.isEmpty)
              ? 'No transaction yet'
              : insights.lastTransactionAt!,
          Colors.indigo,
        ),
      ],
    );
  }
}
