// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountDTO _$AccountDTOFromJson(Map<String, dynamic> json) => AccountDTO(
      accountNumber: json['accountNumber'] as String,
      customerId: (json['customerId'] as num).toInt(),
      balance: (json['balance'] as num).toDouble(),
      status: json['status'] as String,
      type: json['type'] as String,
      createdAt: json['createdAt'] as String?,
      currency: json['currency'] as String?,
      lastTransactionDate: json['lastTransactionDate'] as String?,
    );

Map<String, dynamic> _$AccountDTOToJson(AccountDTO instance) =>
    <String, dynamic>{
      'accountNumber': instance.accountNumber,
      'customerId': instance.customerId,
      'balance': instance.balance,
      'status': instance.status,
      'type': instance.type,
      'createdAt': instance.createdAt,
      'currency': instance.currency,
      'lastTransactionDate': instance.lastTransactionDate,
    };

CreateAccountRequest _$CreateAccountRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAccountRequest(
      customerId: (json['customerId'] as num).toInt(),
      accountType: json['accountType'] as String,
      initialBalance: (json['initialBalance'] as num).toDouble(),
    );

Map<String, dynamic> _$CreateAccountRequestToJson(
        CreateAccountRequest instance) =>
    <String, dynamic>{
      'customerId': instance.customerId,
      'accountType': instance.accountType,
      'initialBalance': instance.initialBalance,
    };

DebitRequestDTO _$DebitRequestDTOFromJson(Map<String, dynamic> json) =>
    DebitRequestDTO(
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      transactionId: json['transactionId'] as String?,
    );

Map<String, dynamic> _$DebitRequestDTOToJson(DebitRequestDTO instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'description': instance.description,
      'transactionId': instance.transactionId,
    };

CreditRequestDTO _$CreditRequestDTOFromJson(Map<String, dynamic> json) =>
    CreditRequestDTO(
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      transactionId: json['transactionId'] as String?,
    );

Map<String, dynamic> _$CreditRequestDTOToJson(CreditRequestDTO instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'description': instance.description,
      'transactionId': instance.transactionId,
    };

BeneficiaryDTO _$BeneficiaryDTOFromJson(Map<String, dynamic> json) =>
    BeneficiaryDTO(
      beneficiaryId: (json['beneficiaryId'] as num).toInt(),
      accountNumber: json['accountNumber'] as String,
      name: json['name'] as String,
      bankName: json['bankName'] as String,
      status: json['status'] as String,
      addedAt: json['addedAt'] as String?,
    );

Map<String, dynamic> _$BeneficiaryDTOToJson(BeneficiaryDTO instance) =>
    <String, dynamic>{
      'beneficiaryId': instance.beneficiaryId,
      'accountNumber': instance.accountNumber,
      'name': instance.name,
      'bankName': instance.bankName,
      'status': instance.status,
      'addedAt': instance.addedAt,
    };
