import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      await api.addBeneficiary(
        nickname: _nicknameController.text.trim(),
        accountNumber: _accountController.text.trim(),
        bankName: _bankController.text.trim(),
        ifscCode: _ifscController.text.trim().isEmpty
            ? null
            : _ifscController.text.trim(),
      );
      _nicknameController.clear();
      _accountController.clear();
      _ifscController.clear();
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beneficiary added.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add beneficiary: $e')),
        );
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
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final beneficiariesAsync = ref.watch(beneficiariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beneficiaries')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
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
                        : null,
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No beneficiaries added yet.'),
                  );
                }
                return Column(
                  children: items.map((b) {
                    return Card(
                      child: ListTile(
                        title: Text(b.nickname),
                        subtitle: Text(
                            '${b.accountNumber}\n${b.bankName}${(b.ifscCode ?? '').isEmpty ? '' : ' • ${b.ifscCode}'}'),
                        isThreeLine: true,
                        leading: IconButton(
                          icon:
                              Icon(b.favorite ? Icons.star : Icons.star_border),
                          onPressed: () => _toggleFavorite(b),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransferScreen(
                                      sourceAccountNumber:
                                          widget.sourceAccountNumber,
                                      initialToAccountNumber: b.accountNumber,
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
