import 'package:json_annotation/json_annotation.dart';

part 'account_models.g.dart';

@JsonSerializable()
class AccountDTO {
  @JsonKey(name: 'accountNumber')
  final String accountNumber;

  // Backend may return either `userId` or legacy `customerId`.
  final int customerId;

  @JsonKey(name: 'balance')
  final double balance;

  @JsonKey(name: 'status')
  final String status; // active, inactive, closed

  @JsonKey(name: 'type')
  final String type; // savings, checking, investment

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'currency')
  final String? currency;

  @JsonKey(name: 'lastTransactionDate')
  final String? lastTransactionDate;

  AccountDTO({
    required this.accountNumber,
    required this.customerId,
    required this.balance,
    required this.status,
    required this.type,
    this.createdAt,
    this.currency,
    this.lastTransactionDate,
  });

  factory AccountDTO.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['customerId'] ?? json['userId'];
    final dynamic typeValue = json['type'] ?? json['accountType'];
    final dynamic balanceValue = json['balance'];

    return AccountDTO(
      accountNumber: (json['accountNumber'] ?? '') as String,
      customerId: idValue is num
          ? idValue.toInt()
          : int.tryParse(idValue?.toString() ?? '') ?? 0,
      balance: balanceValue is num
          ? balanceValue.toDouble()
          : double.tryParse(balanceValue?.toString() ?? '') ?? 0,
      status: (json['status'] ?? 'UNKNOWN').toString(),
      type: (typeValue ?? 'SAVINGS').toString(),
      createdAt: json['createdAt']?.toString(),
      currency: json['currency']?.toString(),
      lastTransactionDate:
          (json['lastTransactionDate'] ?? json['updatedAt'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$AccountDTOToJson(this);
}

@JsonSerializable()
class CreateAccountRequest {
  @JsonKey(name: 'userId')
  final int userId;

  @JsonKey(name: 'accountType')
  final String accountType;

  @JsonKey(name: 'initialBalance')
  final double initialBalance;

  @JsonKey(name: 'accountName')
  final String? accountName;

  CreateAccountRequest({
    required this.userId,
    required this.accountType,
    required this.initialBalance,
    this.accountName,
  });

  factory CreateAccountRequest.fromJson(Map<String, dynamic> json) {
    final dynamic userIdValue = json['userId'] ?? json['customerId'];
    return CreateAccountRequest(
      userId: userIdValue is num
          ? userIdValue.toInt()
          : int.tryParse(userIdValue?.toString() ?? '') ?? 0,
      accountType: (json['accountType'] ?? 'SAVINGS').toString(),
      initialBalance: (json['initialBalance'] as num).toDouble(),
      accountName: json['accountName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'accountType': accountType,
        'initialBalance': initialBalance,
        if (accountName != null && accountName!.trim().isNotEmpty)
          'accountName': accountName,
      };
}

@JsonSerializable()
class DebitRequestDTO {
  @JsonKey(name: 'amount')
  final double amount;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'transactionId')
  final String? transactionId;

  DebitRequestDTO({
    required this.amount,
    this.description,
    this.transactionId,
  });

  factory DebitRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$DebitRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$DebitRequestDTOToJson(this);
}

@JsonSerializable()
class CreditRequestDTO {
  @JsonKey(name: 'amount')
  final double amount;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'transactionId')
  final String? transactionId;

  CreditRequestDTO({
    required this.amount,
    this.description,
    this.transactionId,
  });

  factory CreditRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$CreditRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CreditRequestDTOToJson(this);
}

@JsonSerializable()
class BeneficiaryDTO {
  @JsonKey(name: 'beneficiaryId')
  final int beneficiaryId;

  @JsonKey(name: 'accountNumber')
  final String accountNumber;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'bankName')
  final String bankName;

  @JsonKey(name: 'status')
  final String status; // verified, pending_verification

  @JsonKey(name: 'addedAt')
  final String? addedAt;

  BeneficiaryDTO({
    required this.beneficiaryId,
    required this.accountNumber,
    required this.name,
    required this.bankName,
    required this.status,
    this.addedAt,
  });

  factory BeneficiaryDTO.fromJson(Map<String, dynamic> json) =>
      _$BeneficiaryDTOFromJson(json);

  Map<String, dynamic> toJson() => _$BeneficiaryDTOToJson(this);
}
