import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_models.dart';
import '../home_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedAccountNumber = widget.initialAccountNumber ?? '';
  }

  bool _isWithinDateRange(String dateString) {
    if (dateString.isEmpty || _selectedDateRange == 'all') return true;

    try {
      final txnDate = DateTime.parse(dateString);
      final today = DateTime.now();
      final diffDays = today.difference(txnDate).inDays;

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
    } catch (e) {
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

      return matchesSearch && matchesFilter && matchesDate;
    }).toList();
  }

  double _calculateTotal(List<TransactionDTO> transactions, String type) {
    return transactions
        .where((t) =>
            (type == 'sent' && t.getFromAccount == _selectedAccountNumber) ||
            (type == 'received' && t.getToAccount == _selectedAccountNumber))
        .fold(0.0, (sum, t) => sum + t.amount);
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

            // Set initial account if not set
            if (_selectedAccountNumber.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedAccountNumber = accounts.first.accountNumber;
                });
              });
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Selector
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

                  // Filters Section
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Search Field
                  TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by description or account...',
                      hintStyle: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textLight,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18.w,
                        color: AppTheme.textLight,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(
                          color: AppTheme.textLight.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Transaction Type Filter
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

                  // Date Range Filter
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

                  // Transactions List
                  ref
                      .watch(transactionHistoryProvider(_selectedAccountNumber))
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Text(
                            'Error loading transactions: ${err.toString()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        data: (transactions) {
                          final filteredTransactions = _filterTransactions(
                              transactions, _selectedAccountNumber);

                          if (filteredTransactions.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.h),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 48.w,
                                      color: AppTheme.textLight,
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      'No Transactions Found',
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

                          // Summary
                          final sentTotal = _calculateTotal(
                            filteredTransactions,
                            'sent',
                          );
                          final receivedTotal = _calculateTotal(
                            filteredTransactions,
                            'received',
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary Stats
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      'Total',
                                      filteredTransactions.length.toString(),
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

                              // Transactions List
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.textLight.withOpacity(0.1),
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                padding: EdgeInsets.all(12.w),
                                child: Column(
                                  children: [
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: filteredTransactions.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                        height: 1.h,
                                        color:
                                            AppTheme.textLight.withOpacity(0.1),
                                      ),
                                      itemBuilder: (context, index) {
                                        final transaction =
                                            filteredTransactions[index];
                                        final isSent =
                                            transaction.getFromAccount ==
                                                _selectedAccountNumber;

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40.w,
                                                height: 40.w,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: (isSent
                                                          ? Colors.red
                                                          : Colors.green)
                                                      .withOpacity(0.1),
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
                                                        color:
                                                            AppTheme.textDark,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      isSent
                                                          ? 'To: ${transaction.getToAccount}'
                                                          : 'From: ${transaction.getFromAccount}',
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
                                                    transaction.status
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: transaction.status
                                                                  .toUpperCase() ==
                                                              'SUCCESS'
                                                          ? Colors.green
                                                          : Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                ],
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
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textLight.withOpacity(0.2),
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
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textLight.withOpacity(0.2),
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
        color: color.withOpacity(0.1),
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
