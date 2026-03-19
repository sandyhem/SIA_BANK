import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/auth_models.dart';

class UserProfileViewData {
  final String username;
  final CustomerDTO? customer;

  const UserProfileViewData({
    required this.username,
    this.customer,
  });
}

final userProfileViewProvider =
    FutureProvider.autoDispose<UserProfileViewData>((ref) async {
  final api = ref.read(apiServiceProvider);
  final userId = await api.getCurrentUserId();
  if (userId == null || userId <= 0) {
    throw Exception('No active session found. Please login again.');
  }

  final username = (await api.getCurrentUsername())?.trim();
  CustomerDTO? customer;
  try {
    customer = await api.getCustomerByUserId(userId);
  } on DioException catch (e) {
    if (e.response?.statusCode != 404) {
      rethrow;
    }
  }

  return UserProfileViewData(
    username:
        (username == null || username.isEmpty) ? 'Account Holder' : username,
    customer: customer,
  );
});

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileViewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(
              'Failed to load profile: $error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.refresh(userProfileViewProvider.future),
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _buildHeaderCard(context, data),
              SizedBox(height: 12.h),
              _buildCustomerCard(data.customer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, UserProfileViewData data) {
    final initial =
        data.username.isNotEmpty ? data.username[0].toUpperCase() : 'U';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.username,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Verified Banking Customer',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(CustomerDTO? customer) {
    return Container(
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
            'Banking Profile',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          if (customer == null)
            Text(
              'No customer profile linked yet. Complete onboarding to create your banking profile.',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 12.sp,
              ),
            )
          else ...[
            _buildFieldRow('Full Name', customer.fullName),
            _buildFieldRow('CIF Number', customer.cifNumber),
            _buildFieldRow('KYC Status', customer.kycStatus),
            if ((customer.customerStatus ?? '').isNotEmpty)
              _buildFieldRow('Customer Status', customer.customerStatus!),
            if ((customer.phoneNumber ?? '').isNotEmpty)
              _buildFieldRow('Phone', customer.phoneNumber!),
            if ((customer.address ?? '').isNotEmpty)
              _buildFieldRow('Address', customer.address!),
            if ((customer.panNumber ?? '').isNotEmpty)
              _buildFieldRow('PAN', customer.panNumber!),
            if ((customer.aadhaarNumber ?? '').isNotEmpty)
              _buildFieldRow('Aadhaar', customer.aadhaarNumber!),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
