import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../data/models/transaction_models.dart';

class BeneficiaryWorkflowState {
  final bool verified;
  final DateTime? verifiedAt;
  final DateTime activationTime;
  final double dailyCap;
  final double usedToday;
  final DateTime usageDate;

  const BeneficiaryWorkflowState({
    required this.verified,
    required this.verifiedAt,
    required this.activationTime,
    required this.dailyCap,
    required this.usedToday,
    required this.usageDate,
  });

  BeneficiaryWorkflowState copyWith({
    bool? verified,
    DateTime? verifiedAt,
    DateTime? activationTime,
    double? dailyCap,
    double? usedToday,
    DateTime? usageDate,
  }) {
    return BeneficiaryWorkflowState(
      verified: verified ?? this.verified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      activationTime: activationTime ?? this.activationTime,
      dailyCap: dailyCap ?? this.dailyCap,
      usedToday: usedToday ?? this.usedToday,
      usageDate: usageDate ?? this.usageDate,
    );
  }

  bool get isActive => verified && DateTime.now().isAfter(activationTime);
}

class AccountControlState {
  final String nickname;
  final bool isFrozen;
  final double dailyLimit;

  const AccountControlState({
    required this.nickname,
    required this.isFrozen,
    required this.dailyLimit,
  });

  AccountControlState copyWith({
    String? nickname,
    bool? isFrozen,
    double? dailyLimit,
  }) {
    return AccountControlState(
      nickname: nickname ?? this.nickname,
      isFrozen: isFrozen ?? this.isFrozen,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}

final apiServiceProvider = Provider((ref) => ApiService());

final beneficiariesProvider =
    FutureProvider.autoDispose<List<PayeeDTO>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getBeneficiaries();
});

final beneficiaryWorkflowProvider =
    StateProvider<Map<String, BeneficiaryWorkflowState>>(
  (ref) => <String, BeneficiaryWorkflowState>{},
);

final accountControlProvider = StateProvider<Map<String, AccountControlState>>(
  (ref) => <String, AccountControlState>{},
);

final dashboardLastUpdatedProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

final accountInsightsProvider = FutureProvider.autoDispose
    .family<AccountInsightsDTO, String>((ref, accountNumber) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAccountInsights(accountNumber);
});
