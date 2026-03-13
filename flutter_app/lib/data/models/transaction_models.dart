import 'package:json_annotation/json_annotation.dart';

part 'transaction_models.g.dart';

@JsonSerializable()
class TransactionDTO {
  @JsonKey(name: 'transactionId')
  final String transactionId;

  @JsonKey(name: 'type')
  final String type; // TRANSFER, DEPOSIT, WITHDRAWAL, BILL_PAY

  @JsonKey(name: 'amount')
  final double amount;

  @JsonKey(name: 'date')
  final String date;

  @JsonKey(name: 'status')
  final String status; // PENDING, COMPLETED, FAILED

  @JsonKey(name: 'narration')
  final String? narration;

  @JsonKey(name: 'fromAccount')
  final String? fromAccount;

  @JsonKey(name: 'toAccount')
  final String? toAccount;

  @JsonKey(name: 'reference')
  final String? reference;

  TransactionDTO({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
    this.narration,
    this.fromAccount,
    this.toAccount,
    this.reference,
  });

  factory TransactionDTO.fromJson(Map<String, dynamic> json) =>
      _$TransactionDTOFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionDTOToJson(this);
}

@JsonSerializable()
class TransferRequestDTO {
  @JsonKey(name: 'fromAccount')
  final String fromAccount;

  @JsonKey(name: 'toAccount')
  final String toAccount;

  @JsonKey(name: 'amount')
  final double amount;

  @JsonKey(name: 'narration')
  final String? narration;

  TransferRequestDTO({
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    this.narration,
  });

  factory TransferRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$TransferRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$TransferRequestDTOToJson(this);
}

@JsonSerializable()
class RecurringTransferDTO {
  @JsonKey(name: 'recurringTransferId')
  final String recurringTransferId;

  @JsonKey(name: 'fromAccount')
  final String fromAccount;

  @JsonKey(name: 'toAccount')
  final String toAccount;

  @JsonKey(name: 'amount')
  final double amount;

  @JsonKey(name: 'frequency')
  final String frequency; // daily, weekly, monthly, yearly

  @JsonKey(name: 'startDate')
  final String startDate;

  @JsonKey(name: 'endDate')
  final String? endDate;

  @JsonKey(name: 'status')
  final String status; // active, paused, completed

  @JsonKey(name: 'narration')
  final String? narration;

  @JsonKey(name: 'nextScheduledDate')
  final String? nextScheduledDate;

  RecurringTransferDTO({
    required this.recurringTransferId,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.status,
    this.narration,
    this.nextScheduledDate,
  });

  factory RecurringTransferDTO.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransferDTOFromJson(json);

  Map<String, dynamic> toJson() => _$RecurringTransferDTOToJson(this);
}

@JsonSerializable()
class BillPaymentDTO {
  @JsonKey(name: 'paymentId')
  final String paymentId;

  @JsonKey(name: 'fromAccount')
  final String fromAccount;

  @JsonKey(name: 'providerCode')
  final String providerCode;

  @JsonKey(name: 'billReference')
  final String billReference;

  @JsonKey(name: 'amount')
  final double amount;

  @JsonKey(name: 'dueDate')
  final String? dueDate;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'paymentDate')
  final String? paymentDate;

  BillPaymentDTO({
    required this.paymentId,
    required this.fromAccount,
    required this.providerCode,
    required this.billReference,
    required this.amount,
    this.dueDate,
    required this.status,
    this.paymentDate,
  });

  factory BillPaymentDTO.fromJson(Map<String, dynamic> json) =>
      _$BillPaymentDTOFromJson(json);

  Map<String, dynamic> toJson() => _$BillPaymentDTOToJson(this);
}

@JsonSerializable()
class AlertDTO {
  @JsonKey(name: 'alertId')
  final String alertId;

  @JsonKey(name: 'severity')
  final String severity; // low, medium, high, critical

  @JsonKey(name: 'type')
  final String type; // unusual_activity, large_transaction, kyc_pending

  @JsonKey(name: 'description')
  final String description;

  @JsonKey(name: 'timestamp')
  final String timestamp;

  @JsonKey(name: 'actionRequired')
  final bool actionRequired;

  @JsonKey(name: 'actionUrl')
  final String? actionUrl;

  AlertDTO({
    required this.alertId,
    required this.severity,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.actionRequired,
    this.actionUrl,
  });

  factory AlertDTO.fromJson(Map<String, dynamic> json) =>
      _$AlertDTOFromJson(json);

  Map<String, dynamic> toJson() => _$AlertDTOToJson(this);
}
