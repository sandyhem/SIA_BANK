import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/transaction_models.dart';
import 'transfer_screen.dart';

class BeneficiariesScreen extends ConsumerStatefulWidget {
  final String? sourceAccountNumber;

  const BeneficiariesScreen({Key? key, this.sourceAccountNumber})
      : super(key: key);

  @override
  ConsumerState<BeneficiariesScreen> createState() =>
      _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends ConsumerState<BeneficiariesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _accountController = TextEditingController();
  final _bankController = TextEditingController();
  final _ifscController = TextEditingController();

  bool _isSubmitting = false;
  String? _statusMessage;
  bool _isError = false;

  static const double _defaultDailyCap = 50000;
  static const Duration _activationDelay = Duration(minutes: 10);

  @override
  void dispose() {
    _nicknameController.dispose();
    _accountController.dispose();
    _bankController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(beneficiariesProvider);
    await ref.read(beneficiariesProvider.future);
  }

  Future<void> _addBeneficiary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(apiServiceProvider);
      final accountNumber = _accountController.text.trim();
      await api.addBeneficiary(
        nickname: _nicknameController.text.trim(),
        accountNumber: accountNumber,
        bankName: _bankController.text.trim(),
        ifscCode: _ifscController.text.trim().isEmpty
            ? null
            : _ifscController.text.trim(),
      );

      final workflowMap = Map<String, BeneficiaryWorkflowState>.from(
          ref.read(beneficiaryWorkflowProvider));
      workflowMap[accountNumber] = BeneficiaryWorkflowState(
        verified: false,
        verifiedAt: null,
        activationTime: DateTime.now().add(_activationDelay),
        dailyCap: _defaultDailyCap,
        usedToday: 0,
        usageDate: DateTime.now(),
      );
      ref.read(beneficiaryWorkflowProvider.notifier).state = workflowMap;

      _nicknameController.clear();
      _accountController.clear();
      _bankController.clear();
      _ifscController.clear();
      await _reload();
      if (mounted) {
        setState(() {
          _isError = false;
          _statusMessage =
              'Beneficiary added. Verify with OTP to activate transfers.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = 'Failed to add beneficiary: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteBeneficiary(PayeeDTO b) async {
    try {
      await ref.read(apiServiceProvider).removeBeneficiary(b.id);
      final workflowMap = Map<String, BeneficiaryWorkflowState>.from(
          ref.read(beneficiaryWorkflowProvider));
      workflowMap.remove(b.accountNumber);
      ref.read(beneficiaryWorkflowProvider.notifier).state = workflowMap;
      await _reload();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = 'Failed to delete: $e';
        });
      }
    }
  }

  Future<void> _toggleFavorite(PayeeDTO b) async {
    try {
      await ref.read(apiServiceProvider).setBeneficiaryFavorite(
            beneficiaryId: b.id,
            favorite: !b.favorite,
          );
      await _reload();
    } catch (e) {
      ref.invalidate(beneficiariesProvider);
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = 'Failed to update favorite: $e';
        });
      }
    }
  }

  Future<void> _verifyBeneficiary(PayeeDTO b) async {
    final otpController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verify Beneficiary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter OTP sent to your registered mobile.'),
              SizedBox(height: 8.h),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: '6-digit OTP',
                  counterText: '',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Demo OTP: 123456',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Verify OTP'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    if (otpController.text.trim() != '123456') {
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = true;
        _statusMessage = 'Invalid OTP. Please retry verification.';
      });
      return;
    }

    final workflowMap = Map<String, BeneficiaryWorkflowState>.from(
        ref.read(beneficiaryWorkflowProvider));
    final now = DateTime.now();
    workflowMap[b.accountNumber] = (workflowMap[b.accountNumber] ??
            BeneficiaryWorkflowState(
              verified: false,
              verifiedAt: null,
              activationTime: now.add(_activationDelay),
              dailyCap: _defaultDailyCap,
              usedToday: 0,
              usageDate: now,
            ))
        .copyWith(
      verified: true,
      verifiedAt: now,
      activationTime: now.add(_activationDelay),
    );
    ref.read(beneficiaryWorkflowProvider.notifier).state = workflowMap;

    if (!mounted) {
      return;
    }
    setState(() {
      _isError = false;
      _statusMessage =
          'Beneficiary verified. Activation in ${_activationDelay.inMinutes} minutes.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final beneficiariesAsync = ref.watch(beneficiariesProvider);
    final workflows = ref.watch(beneficiaryWorkflowProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beneficiaries')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            if (_statusMessage != null)
              Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _isError
                      ? Colors.red.withOpacity(0.08)
                      : Colors.green.withOpacity(0.08),
                  border: Border.all(
                    color: _isError ? Colors.red : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _isError ? Colors.red : Colors.green[800],
                  ),
                ),
              ),
            Text(
              'Add Beneficiary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10.h),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Beneficiary Name',
                      hintText: 'Enter beneficiary display name',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nickname required'
                        : null,
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _accountController,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      hintText: 'Enter beneficiary account number',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Account number required'
                        : (v.trim().length < 8
                            ? 'Enter a valid account number'
                            : null),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _bankController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      hintText: 'Enter beneficiary bank name',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Bank name required'
                        : null,
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _ifscController,
                    decoration:
                        const InputDecoration(labelText: 'IFSC (optional)'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'New beneficiaries require OTP verification and have a temporary daily cap of ₹50,000.',
                      style:
                          TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _addBeneficiary,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(
                          _isSubmitting ? 'Saving...' : 'Save Beneficiary'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Saved Beneficiaries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10.h),
            beneficiariesAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => Container(
                    height: 84.h,
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 44.w, color: Colors.grey),
                        SizedBox(height: 8.h),
                        const Text('No beneficiaries added yet.'),
                        SizedBox(height: 4.h),
                        Text(
                          'Add and verify a beneficiary to transfer funds quickly.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: items.map((b) {
                    final workflow = workflows[b.accountNumber];
                    final isVerified = workflow?.verified == true;
                    final isActive = workflow?.isActive == true;
                    final activationText = workflow == null
                        ? 'Verification required'
                        : isActive
                            ? 'Active beneficiary'
                            : 'Activation at ${DateFormat('dd MMM, hh:mm a').format(workflow.activationTime)}';

                    return Card(
                      child: ListTile(
                        title: Text(b.nickname),
                        subtitle: Text(
                            '${b.accountNumber}\n${b.bankName}${(b.ifscCode ?? '').isEmpty ? '' : ' • ${b.ifscCode}'}\n$activationText${workflow == null ? '' : ' • Cap ₹${workflow.dailyCap.toStringAsFixed(0)}'}'),
                        isThreeLine: true,
                        leading: IconButton(
                          icon:
                              Icon(b.favorite ? Icons.star : Icons.star_border),
                          onPressed: () => _toggleFavorite(b),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        titleTextStyle: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isVerified)
                              IconButton(
                                icon: const Icon(Icons.verified_user_outlined),
                                tooltip: 'Verify beneficiary',
                                onPressed: () => _verifyBeneficiary(b),
                              ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: !isActive
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TransferScreen(
                                            sourceAccountNumber:
                                                widget.sourceAccountNumber,
                                            initialToAccountNumber:
                                                b.accountNumber,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteBeneficiary(b),
                            ),
                          ],
                        ),
                        subtitleTextStyle:
                            TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
