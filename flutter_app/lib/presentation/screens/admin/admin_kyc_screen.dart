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
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'PENDING_REVIEW';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  List<CustomerDTO> _applyFilters(List<CustomerDTO> customers) {
    final query = _searchController.text.trim().toLowerCase();

    return customers.where((customer) {
      final status = customer.kycStatus.toUpperCase();
      final matchesStatus = switch (_statusFilter) {
        'ALL' => true,
        'VERIFIED' => status == 'VERIFIED',
        'REJECTED' => status == 'REJECTED',
        'UNDER_REVIEW' => status == 'UNDER_REVIEW',
        _ => status != 'VERIFIED',
      };

      if (!matchesStatus) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final fullName = customer.fullName.toLowerCase();
      final cif = customer.cifNumber.toLowerCase();
      final userId = customer.userId.toString();
      final phone = (customer.phoneNumber ?? '').toLowerCase();
      final pan = (customer.panNumber ?? '').toLowerCase();
      return fullName.contains(query) ||
          cif.contains(query) ||
          userId.contains(query) ||
          phone.contains(query) ||
          pan.contains(query);
    }).toList();
  }

  Future<void> _showCustomerDetails(CustomerDTO customer) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(customer.fullName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Customer ID', customer.customerId.toString()),
                _detailRow('User ID', customer.userId.toString()),
                _detailRow('CIF', customer.cifNumber),
                _detailRow('KYC Status', customer.kycStatus),
                if ((customer.customerStatus ?? '').isNotEmpty)
                  _detailRow('Customer Status', customer.customerStatus!),
                if ((customer.phoneNumber ?? '').isNotEmpty)
                  _detailRow('Phone', customer.phoneNumber!),
                if ((customer.address ?? '').isNotEmpty)
                  _detailRow('Address', customer.address!),
                if ((customer.panNumber ?? '').isNotEmpty)
                  _detailRow('PAN', customer.panNumber!),
                if ((customer.aadhaarNumber ?? '').isNotEmpty)
                  _detailRow('Aadhaar', customer.aadhaarNumber!),
                if ((customer.createdAt ?? '').isNotEmpty)
                  _detailRow('Created At', customer.createdAt!),
                if ((customer.kycVerifiedAt ?? '').isNotEmpty)
                  _detailRow('KYC Verified At', customer.kycVerifiedAt!),
                if ((customer.kycVerifiedBy ?? '').isNotEmpty)
                  _detailRow('KYC Verified By', customer.kycVerifiedBy!),
              ],
            ),
          ),
          actions: [
            if (customer.kycStatus.toUpperCase() != 'UNDER_REVIEW')
              TextButton(
                onPressed: _updating
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _updateKyc(customer, 'UNDER_REVIEW');
                      },
                child: const Text('Mark Under Review'),
              ),
            if (customer.kycStatus.toUpperCase() != 'REJECTED')
              TextButton(
                onPressed: _updating
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _updateKyc(customer, 'REJECTED');
                      },
                child: const Text('Reject'),
              ),
            if (customer.kycStatus.toUpperCase() != 'VERIFIED')
              ElevatedButton(
                onPressed: _updating
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _updateKyc(customer, 'VERIFIED');
                      },
                child: const Text('Verify'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
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
          final filteredCustomers = _applyFilters(customers);

          if (filteredCustomers.isEmpty) {
            return const Center(
              child: Text('No customers match current filters.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminCustomersProvider.future),
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: filteredCustomers.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Search Customer',
                            hintText: 'Name / CIF / User ID / Phone / PAN',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'KYC Status Filter',
                            prefixIcon: Icon(Icons.filter_alt_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'PENDING_REVIEW',
                              child: Text('Pending + Under Review + Rejected'),
                            ),
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Text('All Customers'),
                            ),
                            DropdownMenuItem(
                              value: 'VERIFIED',
                              child: Text('Verified'),
                            ),
                            DropdownMenuItem(
                              value: 'UNDER_REVIEW',
                              child: Text('Under Review'),
                            ),
                            DropdownMenuItem(
                              value: 'REJECTED',
                              child: Text('Rejected'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _statusFilter = value);
                          },
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Results: ${filteredCustomers.length}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final customer = filteredCustomers[index - 1];
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
                                  : () => _showCustomerDetails(customer),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('View'),
                            ),
                          ),
                          SizedBox(width: 10.w),
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
