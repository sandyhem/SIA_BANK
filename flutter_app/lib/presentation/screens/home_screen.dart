import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/account_models.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/transaction_models.dart';
import 'admin/admin_kyc_screen.dart';
import 'accounts/open_account_screen.dart';
import 'accounts/transfer_screen.dart';
import 'accounts/transaction_history_screen.dart';
import 'auth/account_onboarding_screen.dart';
import 'profile/user_profile_screen.dart';

// Providers for state management
final currentUserIdProvider = FutureProvider.autoDispose<int>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final userId = await apiService.getCurrentUserId();
  if (userId == null) {
    throw Exception('No active session found. Please login again.');
  }
  return userId;
});

final currentUserRoleProvider = FutureProvider.autoDispose<String>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  try {
    // Try to ensure session state is hydrated, but do not fail role lookup if this throws.
    await ref.watch(currentUserIdProvider.future);
  } catch (_) {
    // Ignore and continue with best-effort role resolution.
  }

  try {
    final role = await apiService.getCurrentRole();
    if (role == null || role.trim().isEmpty) {
      return 'USER';
    }
    return role.toUpperCase();
  } catch (_) {
    // Fail-safe role for UI continuity.
    return 'USER';
  }
});

final userKycProvider = FutureProvider.autoDispose<UserKycDTO>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  final kyc = await apiService.getUserKycStatus(userId);
  await apiService.setCachedKycStatus(kyc.status);
  return kyc;
});

final currentCustomerProvider =
    FutureProvider.autoDispose<CustomerDTO?>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  try {
    return await apiService.getCustomerByUserId(userId);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return null;
    }
    rethrow;
  } catch (e) {
    final message = e.toString().toLowerCase();
    if (message.contains('not found')) {
      return null;
    }
    rethrow;
  }
});

final accountsProvider =
    FutureProvider.autoDispose<List<AccountDTO>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  final accounts = await apiService.getAccountsByCustomer(userId);

  // Enforce one account per type in UI list to avoid duplicate account types.
  final uniqueByType = <String, AccountDTO>{};
  for (final account in accounts) {
    uniqueByType.putIfAbsent(account.type.toUpperCase(), () => account);
  }
  return uniqueByType.values.toList();
});

final selectedAccountProvider = StateProvider<AccountDTO?>((ref) => null);
final balanceVisibilityProvider =
    StateProvider<Map<String, bool>>((ref) => <String, bool>{});

final currentUsernameProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCurrentUsername();
});

final transactionHistoryProvider = FutureProvider.autoDispose
    .family<List<TransactionDTO>, String>((ref, accountNumber) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getTransactionHistory(accountNumber);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsyncValue = ref.watch(currentUserIdProvider);
    final roleAsyncValue = ref.watch(currentUserRoleProvider);

    if (userIdAsyncValue.isLoading || roleAsyncValue.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userIdAsyncValue.hasError || userIdAsyncValue.valueOrNull == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Session expired. Please login again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () async {
                    final apiService = ref.read(apiServiceProvider);
                    await apiService.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: const Text('Back To Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (roleAsyncValue.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to resolve user role. Please login again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () async {
                    final apiService = ref.read(apiServiceProvider);
                    await apiService.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: const Text('Back To Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAdmin = roleAsyncValue.requireValue.toUpperCase() == 'ADMIN';
    final accountsAsyncValue = isAdmin ? null : ref.watch(accountsProvider);
    final kycAsyncValue = isAdmin ? null : ref.watch(userKycProvider);
    final customerAsyncValue =
        isAdmin ? null : ref.watch(currentCustomerProvider);
    final currentUserId = userIdAsyncValue.requireValue;
    final usernameAsync = ref.watch(currentUsernameProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(10.w),
          child: usernameAsync.when(
            data: (username) {
              final initial = (username?.isNotEmpty == true)
                  ? username![0].toUpperCase()
                  : 'U';
              return CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
            loading: () => CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
            error: (_, __) => const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showProfileMenu(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'Admin Dashboard' : 'Welcome back,',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  usernameAsync.when(
                    data: (username) => Text(
                      username ?? 'SIA Bank',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    loading: () => Text(
                      'SIA Bank',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    error: (_, __) => Text(
                      'SIA Bank',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14.sp, color: AppTheme.accentColor),
                      SizedBox(width: 6.w),
                      Text(
                        'Secure Session Active',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!isAdmin)
              customerAsyncValue!.when(
                data: (customer) {
                  if (customer == null) {
                    return _buildCreateAccountPrompt(
                      context,
                      userId: currentUserId,
                      username: usernameAsync.valueOrNull,
                    );
                  }
                  return accountsAsyncValue!.when(
                    data: (accounts) {
                      if (accounts.isEmpty) {
                        return _buildNoAccountsPrompt(
                          context,
                          userId: currentUserId,
                        );
                      }
                      return _buildAccountsSection(context, ref, accounts);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Error loading profile: $error')),
              ),

            SizedBox(height: 16.h),

            // KYC Status (admin users are exempt from KYC gating)
            isAdmin
                ? _buildAdminBanner(context)
                : customerAsyncValue!.valueOrNull == null
                    ? _buildPendingProfileBanner(context)
                    : kycAsyncValue!.when(
                        data: (kyc) => _buildKycStatusBanner(context, kyc),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Text(
                            'Unable to fetch KYC status: $error',
                            style: TextStyle(
                              color: AppTheme.dangerColor,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),

            SizedBox(height: 32.h),

            // Quick Actions
            _buildQuickActions(context, ref, isAdmin: isAdmin),

            SizedBox(height: 32.h),

            if (isAdmin) _buildAdminOperations(context),

            if (isAdmin) SizedBox(height: 32.h),

            if (!isAdmin)
              // Recent Transactions
              accountsAsyncValue!.when(
                data: (accounts) {
                  if (customerAsyncValue!.valueOrNull == null) {
                    return const SizedBox.shrink();
                  }
                  if (accounts.isNotEmpty) {
                    final selectedAccount =
                        ref.watch(selectedAccountProvider) ?? accounts.first;
                    return _buildRecentTransactions(
                        context, ref, selectedAccount);
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => const SizedBox.shrink(),
              ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsSection(
      BuildContext context, WidgetRef ref, List<AccountDTO> accounts) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'Your Accounts',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 238.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return _buildAccountCard(context, ref, account, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(
      BuildContext context, WidgetRef ref, AccountDTO account, int index) {
    final colors = [
      [AppTheme.primaryColor, const Color(0xFF818CF8)],
      [AppTheme.accentColor, const Color(0xFF34D399)],
      [AppTheme.warningColor, const Color(0xFFFBBF24)],
      [AppTheme.dangerColor, const Color(0xFFF87171)],
    ];

    final colorPair = colors[index % colors.length];
    final visibilityMap = ref.watch(balanceVisibilityProvider);
    final isBalanceVisible = visibilityMap[account.accountNumber] ?? false;

    return Container(
      width: 300.w,
      margin: EdgeInsets.only(right: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colorPair,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: colorPair[0].withOpacity(0.3),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.type.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Savings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Center(
                  child:
                      Icon(Icons.account_balance_wallet, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                isBalanceVisible
                    ? '₹ ${account.balance.toStringAsFixed(2)}'
                    : '₹ ••••••',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              InkWell(
                onTap: () async {
                  if (isBalanceVisible) {
                    final updated = Map<String, bool>.from(visibilityMap);
                    updated[account.accountNumber] = false;
                    ref.read(balanceVisibilityProvider.notifier).state =
                        updated;
                    return;
                  }

                  final verified = await _promptAndVerifyMpin(context, ref);
                  if (!verified) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Invalid MPIN. Balance remains hidden.'),
                        ),
                      );
                    }
                    return;
                  }

                  final updated = Map<String, bool>.from(visibilityMap);
                  updated[account.accountNumber] = true;
                  ref.read(balanceVisibilityProvider.notifier).state = updated;
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBalanceVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white70,
                      size: 14.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isBalanceVisible ? 'Hide Balance' : 'View via MPIN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Number',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      account.accountNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: account.accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account number copied!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(Icons.copy, color: Colors.white70, size: 16.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _promptAndVerifyMpin(BuildContext context, WidgetRef ref) async {
    final mpinController = TextEditingController();
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Verify MPIN'),
              content: TextField(
                controller: mpinController,
                keyboardType: TextInputType.number,
                obscureText: obscure,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit MPIN',
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

  Widget _buildQuickActions(BuildContext context, WidgetRef ref,
      {required bool isAdmin}) {
    const int columns = 2;
    final List<Widget> actions = isAdmin
        ? [
            _buildActionButton(
              context,
              'KYC Admin',
              Icons.verified_user,
              columns: columns,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminKycScreen(),
                  ),
                );
              },
            ),
          ]
        : [
            _buildActionButton(
              context,
              'Send Money',
              Icons.send,
              columns: columns,
              onTap: () async {
                final role = ref.read(currentUserRoleProvider).valueOrNull;
                final isAdmin = (role ?? '').toUpperCase() == 'ADMIN';
                final kycAsync = ref.read(userKycProvider);
                final kyc = kycAsync.valueOrNull;
                if (!isAdmin &&
                    kyc != null &&
                    kyc.status.toUpperCase() != 'VERIFIED') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Transfer is disabled until your KYC is VERIFIED.',
                      ),
                    ),
                  );
                  return;
                }

                final selectedAccount = ref.read(selectedAccountProvider);
                final transferResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => TransferScreen(
                      sourceAccountNumber: selectedAccount?.accountNumber,
                    ),
                  ),
                );

                if (transferResult == true) {
                  ref.invalidate(accountsProvider);
                  if (selectedAccount != null) {
                    ref.invalidate(
                      transactionHistoryProvider(selectedAccount.accountNumber),
                    );
                  }
                }
              },
            ),
            _buildActionButton(
              context,
              'History',
              Icons.history,
              columns: columns,
              onTap: () {
                final accounts = ref.read(accountsProvider).valueOrNull ?? [];
                final account = ref.read(selectedAccountProvider) ??
                    (accounts.isNotEmpty ? accounts.first : null);
                if (account == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No account available yet.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionHistoryScreen(
                      initialAccountNumber: account.accountNumber,
                    ),
                  ),
                );
              },
            ),
          ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            alignment: WrapAlignment.spaceBetween,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOperations(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Operations',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Manage customer KYC approvals/rejections from the admin console.',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textLight,
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminKycScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.verified_user),
                label: const Text('Open KYC Admin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingProfileBanner(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppTheme.warningColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.pending_actions, color: AppTheme.warningColor),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Complete your customer profile and submit account request. '
                'Admin will verify KYC before account activation.',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountPrompt(
    BuildContext context, {
    required int? userId,
    required String? username,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finish Account Setup',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your user exists, but no customer/account profile is linked yet.',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: userId == null
                    ? null
                    : () {
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AccountOnboardingScreen(
                              userId: userId,
                              fullName: (username ?? '').trim(),
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Create Profile & Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccountsPrompt(
    BuildContext context, {
    required int? userId,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No Bank Account Yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your customer profile is ready. Open your first account to start banking.',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: userId == null
                    ? null
                    : () {
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OpenAccountScreen(
                              userId: userId,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.add_card),
                label: const Text('Open Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBanner(BuildContext context) {
    final color = AppTheme.primaryColor;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.admin_panel_settings, color: color),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADMIN MODE',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Admin users can manage customer KYC from the profile menu.',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon, {
    required int columns,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth - (48.w); // 24.w left + 24.w right
    final spacingTotal = (columns - 1) * 12.w;
    final width = (containerWidth - spacingTotal) / columns;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: onTap,
                child: Icon(icon, color: AppTheme.primaryColor, size: 24.sp),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    WidgetRef ref,
    AccountDTO account,
  ) {
    final transactionsAsyncValue =
        ref.watch(transactionHistoryProvider(account.accountNumber));

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TransactionHistoryScreen(
                        initialAccountNumber: account.accountNumber,
                      ),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        transactionsAsyncValue.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textLight,
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: transactions.take(5).length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return _buildTransactionTile(context, txn);
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
      BuildContext context, TransactionDTO transaction) {
    final isDebit =
        transaction.type == 'TRANSFER' || transaction.type == 'WITHDRAWAL';
    final icon = isDebit ? Icons.arrow_upward : Icons.arrow_downward;
    final color = isDebit ? AppTheme.dangerColor : AppTheme.accentColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 20.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.narration ?? transaction.type,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  transaction.date ?? 'Unknown date',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? '-' : '+'}₹ ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  transaction.status,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKycStatusBanner(BuildContext context, UserKycDTO kyc) {
    final normalized = kyc.status.toUpperCase();
    final bool isVerified = normalized == 'VERIFIED';
    final Color color =
        isVerified ? AppTheme.accentColor : AppTheme.warningColor;
    final String subtitle = isVerified
        ? 'KYC is verified. All banking features are available.'
        : 'KYC status is $normalized. Complete verification to unlock full features.';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.pending_actions,
              color: color,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC: $normalized',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),
            FutureBuilder<String?>(
              future: ref.read(apiServiceProvider).getCurrentRole(),
              builder: (context, snapshot) {
                final isAdmin = (snapshot.data ?? '').toUpperCase() == 'ADMIN';
                if (!isAdmin) {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('KYC Admin'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminKycScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.dangerColor),
              title: const Text('Logout',
                  style: TextStyle(color: AppTheme.dangerColor)),
              onTap: () async {
                final apiService = ref.read(apiServiceProvider);
                await apiService.logout();
                ref.invalidate(currentUserRoleProvider);
                ref.invalidate(currentUserIdProvider);
                ref.invalidate(userKycProvider);
                ref.invalidate(accountsProvider);
                ref.invalidate(selectedAccountProvider);
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
