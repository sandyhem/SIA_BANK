import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/auth_models.dart';

final adminCustomersProvider = FutureProvider<List<CustomerDTO>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final customers = await api.getAllCustomers();
  customers.sort((a, b) => (a.fullName).compareTo(b.fullName));
  return customers;
});

class AdminKycScreen extends ConsumerStatefulWidget {
  const AdminKycScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends ConsumerState<AdminKycScreen> {
  bool _updating = false;

  Future<void> _updateKyc(CustomerDTO customer, String newStatus) async {
    setState(() => _updating = true);
    try {
      final api = ref.read(apiServiceProvider);
      final adminUsername = await api.getCurrentUsername();
      await api.updateCustomerKycStatus(
        cifNumber: customer.cifNumber,
        adminUsername: adminUsername,
        request: UpdateKycStatusRequest(
          kycStatus: newStatus,
          verifiedBy: adminUsername,
          remarks: 'Updated via admin console',
        ),
      );

      ref.invalidate(adminCustomersProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KYC updated to $newStatus for ${customer.fullName}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.dangerColor,
          content: Text('Failed to update KYC: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED':
        return AppTheme.accentColor;
      case 'REJECTED':
        return AppTheme.dangerColor;
      case 'UNDER_REVIEW':
        return AppTheme.warningColor;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(adminCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin KYC Verification')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load customers: $error')),
        data: (customers) {
          final pendingCustomers = customers
              .where((c) => c.kycStatus.toUpperCase() != 'VERIFIED')
              .toList();

          if (pendingCustomers.isEmpty) {
            return const Center(
              child:
                  Text('No pending KYC records. All customers are verified.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminCustomersProvider.future),
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: pendingCustomers.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final customer = pendingCustomers[index];
                return Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.fullName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(customer.kycStatus)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              customer.kycStatus,
                              style: TextStyle(
                                color: _statusColor(customer.kycStatus),
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text('CIF: ${customer.cifNumber}'),
                      Text('User ID: ${customer.userId}'),
                      if ((customer.phoneNumber ?? '').isNotEmpty)
                        Text('Phone: ${customer.phoneNumber}'),
                      if ((customer.address ?? '').isNotEmpty)
                        Text('Address: ${customer.address}'),
                      if ((customer.panNumber ?? '').isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Row(
                            children: [
                              Icon(Icons.credit_card,
                                  size: 14.sp, color: AppTheme.textLight),
                              SizedBox(width: 4.w),
                              Text(
                                'PAN: ${customer.panNumber}',
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      if ((customer.aadhaarNumber ?? '').isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Row(
                            children: [
                              Icon(Icons.fingerprint,
                                  size: 14.sp, color: AppTheme.textLight),
                              SizedBox(width: 4.w),
                              Text(
                                'Aadhaar: ${customer.aadhaarNumber}',
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _updating
                                  ? null
                                  : () => _updateKyc(customer, 'REJECTED'),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.dangerColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _updating
                                  ? null
                                  : () => _updateKyc(customer, 'VERIFIED'),
                              icon: const Icon(Icons.check),
                              label: const Text('Verify'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
