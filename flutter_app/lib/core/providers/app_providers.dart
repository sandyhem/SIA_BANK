import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../data/models/transaction_models.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final beneficiariesProvider =
    FutureProvider.autoDispose<List<PayeeDTO>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getBeneficiaries();
});

final accountInsightsProvider = FutureProvider.autoDispose
    .family<AccountInsightsDTO, String>((ref, accountNumber) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAccountInsights(accountNumber);
});
