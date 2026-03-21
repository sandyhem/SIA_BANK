import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_models.dart';
import '../home_screen.dart';
import 'transfer_screen.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String? initialAccountNumber;

  const TransactionHistoryScreen({
    Key? key,
    this.initialAccountNumber,
  }) : super(key: key);

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  late String _selectedAccountNumber;
  String _selectedFilter = 'all';
  String _selectedDateRange = 'all';
  String _searchQuery = '';
  DateTime _statementMonth = DateTime.now();
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedAccountNumber = widget.initialAccountNumber ?? '';
  }

  Future<void> _refreshTransactions() async {
    if (_selectedAccountNumber.isEmpty) {
      return;
    }
    ref.invalidate(transactionHistoryProvider(_selectedAccountNumber));
    await ref.read(transactionHistoryProvider(_selectedAccountNumber).future);
    if (mounted) {
      setState(() => _lastUpdated = DateTime.now());
    }
  }

  bool _isWithinDateRange(String dateString) {
    if (dateString.isEmpty || _selectedDateRange == 'all') {
      return true;
    }

    try {
      final txnDate = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final txnDay = DateTime(txnDate.year, txnDate.month, txnDate.day);
      final diffDays = today.difference(txnDay).inDays;

      switch (_selectedDateRange) {
        case 'today':
          return diffDays == 0;
        case 'week':
          return diffDays <= 7;
        case 'month':
          return diffDays <= 30;
        case 'year':
          return diffDays <= 365;
        default:
          return true;
      }
    } catch (_) {
      return true;
    }
  }

  bool _matchesStatementMonth(String raw) {
    if (raw.trim().isEmpty) {
      return true;
    }
    try {
      final dt = DateTime.parse(raw).toLocal();
      return dt.year == _statementMonth.year &&
          dt.month == _statementMonth.month;
    } catch (_) {
      return true;
    }
  }

  List<TransactionDTO> _filterTransactions(
    List<TransactionDTO> transactions,
    String accountNumber,
  ) {
    return transactions.where((transaction) {
      final matchesSearch = transaction.getDescription
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          transaction.getFromAccount.contains(_searchQuery) ||
          transaction.getToAccount.contains(_searchQuery);

      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'sent' &&
              transaction.getFromAccount == accountNumber) ||
          (_selectedFilter == 'received' &&
              transaction.getToAccount == accountNumber);

      final matchesDate = _isWithinDateRange(transaction.getDate);
      final matchesMonth = _matchesStatementMonth(transaction.getDate);

      return matchesSearch && matchesFilter && matchesDate && matchesMonth;
    }).toList();
  }

  double _calculateTotal(List<TransactionDTO> transactions, String type) {
    return transactions
        .where((t) =>
            (type == 'sent' && t.getFromAccount == _selectedAccountNumber) ||
            (type == 'received' && t.getToAccount == _selectedAccountNumber))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String _resolveRepeatTargetAccount(TransactionDTO transaction) {
    final isSent = transaction.getFromAccount == _selectedAccountNumber;
    return isSent ? transaction.getToAccount : transaction.getFromAccount;
  }

  Future<void> _openRepeatTransfer(TransactionDTO transaction) async {
    final targetAccount = _resolveRepeatTargetAccount(transaction).trim();
    if (targetAccount.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Unable to identify beneficiary account for this transaction.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransferScreen(
          sourceAccountNumber: _selectedAccountNumber,
          initialToAccountNumber: targetAccount,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refreshTransactions();
  }

  String _normalizeStatus(String status) {
    final value = status.trim().toUpperCase();
    if (value == 'COMPLETED') {
      return 'SUCCESS';
    }
    if (value == 'INITIATED' ||
        value == 'PENDING' ||
        value == 'SUCCESS' ||
        value == 'FAILED' ||
        value == 'REVERSED') {
      return value;
    }
    return 'SUCCESS';
  }

  List<String> _statusTimelineFor(String status) {
    final normalized = _normalizeStatus(status);
    if (normalized == 'FAILED') {
      return const ['INITIATED', 'PENDING', 'FAILED'];
    }
    if (normalized == 'REVERSED') {
      return const ['INITIATED', 'PENDING', 'SUCCESS', 'REVERSED'];
    }
    if (normalized == 'PENDING') {
      return const ['INITIATED', 'PENDING'];
    }
    if (normalized == 'INITIATED') {
      return const ['INITIATED'];
    }
    return const ['INITIATED', 'PENDING', 'SUCCESS'];
  }

  Future<void> _exportMonthlyStatement(
      List<TransactionDTO> transactions) async {
    final monthLabel = DateFormat('yyyy_MM').format(_statementMonth);
    final buffer = StringBuffer()
      ..writeln('SIA BANK MONTHLY STATEMENT')
      ..writeln('Account: $_selectedAccountNumber')
      ..writeln('Month: ${DateFormat('MMMM yyyy').format(_statementMonth)}')
      ..writeln(
          'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}')
      ..writeln('')
      ..writeln('id,type,status,amount,from,to,date,description');

    for (final t in transactions) {
      buffer.writeln(
        '${t.transactionId},${t.type},${_normalizeStatus(t.status)},${t.amount.toStringAsFixed(2)},${t.getFromAccount},${t.getToAccount},${t.getDate},${t.getDescription.replaceAll(',', ' ')}',
      );
    }

    try {
      final file =
          File('${Directory.systemTemp.path}/sia_statement_$monthLabel.csv');
      await file.writeAsString(buffer.toString());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statement exported: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statement export failed: $e')),
      );
    }
  }

  Future<void> _downloadReceipt(TransactionDTO transaction) async {
    final receipt = StringBuffer()
      ..writeln('SIA BANK RECEIPT')
      ..writeln('Transaction ID: ${transaction.transactionId}')
      ..writeln('Status: ${_normalizeStatus(transaction.status)}')
      ..writeln('Type: ${transaction.type}')
      ..writeln('Amount: ₹${transaction.amount.toStringAsFixed(2)}')
      ..writeln('From: ${transaction.getFromAccount}')
      ..writeln('To: ${transaction.getToAccount}')
      ..writeln('Date: ${transaction.getDate}')
      ..writeln('Description: ${transaction.getDescription}');

    try {
      final file = File(
          '${Directory.systemTemp.path}/receipt_${transaction.transactionId}.txt');
      await file.writeAsString(receipt.toString());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt saved: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt download failed: $e')),
      );
    }
  }

  Widget _buildTimeline(String status) {
    final timeline = _statusTimelineFor(status);
    return Wrap(
      spacing: 6.w,
      runSpacing: 4.h,
      children: timeline
          .map(
            (step) => Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: step == timeline.last
                    ? AppTheme.primaryColor.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.12),
              ),
              child: Text(
                step,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: step == timeline.last
                      ? AppTheme.primaryColor
                      : AppTheme.textLight,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsyncValue = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: accountsAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error loading accounts: ${err.toString()}'),
          ),
          data: (accounts) {
            if (accounts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 64.w,
                      color: AppTheme.textLight,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No Accounts Found',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Please create an account first',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_selectedAccountNumber.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedAccountNumber = accounts.first.accountNumber;
                });
              });
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: _refreshTransactions,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Account',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedAccountNumber,
                      items: accounts
                          .map((account) => DropdownMenuItem(
                                value: account.accountNumber,
                                child: Text(
                                  '${account.accountNumber} - ${account.type.toUpperCase()}',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedAccountNumber = value;
                            _searchQuery = '';
                            _selectedFilter = 'all';
                            _selectedDateRange = 'all';
                          });
                        }
                      },
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        color: AppTheme.bgLight,
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passbook & Statement',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Month: ${DateFormat('MMMM yyyy').format(_statementMonth)}',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _statementMonth = DateTime(
                                      _statementMonth.year,
                                      _statementMonth.month - 1,
                                      1,
                                    );
                                  });
                                },
                                child: const Text('Prev'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _statementMonth = DateTime(
                                      _statementMonth.year,
                                      _statementMonth.month + 1,
                                      1,
                                    );
                                  });
                                },
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                          Text(
                            'Last updated: ${DateFormat('dd MMM, hh:mm a').format(_lastUpdated)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search by description or account...',
                        prefixIcon: Icon(Icons.search, size: 18.w),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            'All',
                            'all',
                            _selectedFilter == 'all',
                            () => setState(() => _selectedFilter = 'all'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildFilterChip(
                            'Sent',
                            'sent',
                            _selectedFilter == 'sent',
                            () => setState(() => _selectedFilter = 'sent'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildFilterChip(
                            'Received',
                            'received',
                            _selectedFilter == 'received',
                            () => setState(() => _selectedFilter = 'received'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDateChip('All Time', 'all'),
                          SizedBox(width: 8.w),
                          _buildDateChip('Today', 'today'),
                          SizedBox(width: 8.w),
                          _buildDateChip('Last 7 Days', 'week'),
                          SizedBox(width: 8.w),
                          _buildDateChip('Last 30 Days', 'month'),
                          SizedBox(width: 8.w),
                          _buildDateChip('Last Year', 'year'),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ref
                        .watch(
                            transactionHistoryProvider(_selectedAccountNumber))
                        .when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(
                            child: Text(
                              'Error loading transactions: ${err.toString()}',
                            ),
                          ),
                          data: (transactions) {
                            final filtered = _filterTransactions(
                                transactions, _selectedAccountNumber);

                            if (filtered.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.h),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox,
                                          size: 48.w,
                                          color: AppTheme.textLight),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'No transactions for selected filters',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final sentTotal = _calculateTotal(filtered, 'sent');
                            final receivedTotal =
                                _calculateTotal(filtered, 'received');

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _exportMonthlyStatement(filtered),
                                    icon: const Icon(Icons.download_outlined),
                                    label:
                                        const Text('Export Monthly Statement'),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total',
                                        filtered.length.toString(),
                                        Colors.blue,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Sent',
                                        '₹${sentTotal.toStringAsFixed(2)}',
                                        Colors.red,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Received',
                                        '₹${receivedTotal.toStringAsFixed(2)}',
                                        Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1.h,
                                    color: AppTheme.textLight
                                        .withValues(alpha: 0.2),
                                  ),
                                  itemBuilder: (context, index) {
                                    final transaction = filtered[index];
                                    final isSent = transaction.getFromAccount ==
                                        _selectedAccountNumber;
                                    final normalizedStatus =
                                        _normalizeStatus(transaction.status);

                                    return Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12.h),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40.w,
                                                height: 40.w,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: (isSent
                                                          ? Colors.red
                                                          : Colors.green)
                                                      .withValues(alpha: 0.1),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    isSent
                                                        ? Icons.arrow_upward
                                                        : Icons.arrow_downward,
                                                    size: 18.w,
                                                    color: isSent
                                                        ? Colors.red
                                                        : Colors.green,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      transaction
                                                          .getDescription,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      isSent
                                                          ? 'To: ${transaction.getToAccount}'
                                                          : 'From: ${transaction.getSenderName}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 11.sp,
                                                        color:
                                                            AppTheme.textLight,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${isSent ? '−' : '+'}₹${transaction.amount.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isSent
                                                          ? Colors.red
                                                          : Colors.green,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2.h),
                                                  Text(
                                                    normalizedStatus,
                                                    style: TextStyle(
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: normalizedStatus ==
                                                              'SUCCESS'
                                                          ? Colors.green
                                                          : (normalizedStatus ==
                                                                      'PENDING' ||
                                                                  normalizedStatus ==
                                                                      'INITIATED'
                                                              ? Colors.orange
                                                              : Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.h),
                                          _buildTimeline(transaction.status),
                                          SizedBox(height: 8.h),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Wrap(
                                              spacing: 4.w,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _downloadReceipt(
                                                          transaction),
                                                  icon: Icon(
                                                    Icons.receipt_long,
                                                    size: 16.sp,
                                                  ),
                                                  label: const Text('Receipt'),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _openRepeatTransfer(
                                                          transaction),
                                                  icon: Icon(
                                                    Icons.repeat,
                                                    size: 16.sp,
                                                  ),
                                                  label: Text(
                                                    isSent
                                                        ? 'Repeat Transfer'
                                                        : 'Pay Back',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textLight.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, String value) {
    final isSelected = _selectedDateRange == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDateRange = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textLight.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
