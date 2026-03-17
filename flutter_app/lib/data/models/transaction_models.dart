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
  final String? date;

  @JsonKey(name: 'status')
  final String status; // PENDING, COMPLETED, FAILED, SUCCESS

  @JsonKey(name: 'narration')
  final String? narration;

  @JsonKey(name: 'fromAccountNumber')
  final String? fromAccountNumber;

  @JsonKey(name: 'fromAccount')
  final String? fromAccount;

  @JsonKey(name: 'toAccountNumber')
  final String? toAccountNumber;

  @JsonKey(name: 'toAccount')
  final String? toAccount;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'reference')
  final String? reference;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  TransactionDTO({
    required this.transactionId,
    required this.type,
    required this.amount,
    this.date,
    required this.status,
    this.narration,
    this.fromAccountNumber,
    this.fromAccount,
    this.toAccountNumber,
    this.toAccount,
    this.description,
    this.reference,
    this.createdAt,
  });

  String get getFromAccount => fromAccountNumber ?? fromAccount ?? '';
  String get getToAccount => toAccountNumber ?? toAccount ?? '';
  String get getDescription => description ?? narration ?? 'Transfer';
  String get getDate => createdAt ?? date ?? '';

  factory TransactionDTO.fromJson(Map<String, dynamic> json) => TransactionDTO(
        transactionId: (json['transactionId'] ?? json['id'] ?? '').toString(),
        type:
            (json['type'] ?? json['transactionType'] ?? 'TRANSFER').toString(),
        amount: (json['amount'] is num)
            ? (json['amount'] as num).toDouble()
            : double.tryParse('${json['amount'] ?? 0}') ?? 0,
        date: (json['date'] ?? json['transactionDate'])?.toString(),
        status: (json['status'] ?? 'PENDING').toString(),
        narration: json['narration']?.toString(),
        fromAccountNumber:
            (json['fromAccountNumber'] ?? json['senderAccount'])?.toString(),
        fromAccount: json['fromAccount']?.toString(),
        toAccountNumber:
            (json['toAccountNumber'] ?? json['receiverAccount'])?.toString(),
        toAccount: json['toAccount']?.toString(),
        description: json['description']?.toString(),
        reference: (json['reference'] ?? json['referenceNumber'])?.toString(),
        createdAt: (json['createdAt'] ?? json['timestamp'])?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'type': type,
        'amount': amount,
        'date': date,
        'status': status,
        'narration': narration,
        'fromAccountNumber': fromAccountNumber,
        'fromAccount': fromAccount,
        'toAccountNumber': toAccountNumber,
        'toAccount': toAccount,
        'description': description,
        'reference': reference,
        'createdAt': createdAt,
      };
}

@JsonSerializable()
class TransferRequestDTO {
  // Backend contract expects fromAccountNumber.
  @JsonKey(name: 'fromAccountNumber')
  final String fromAccount;

  // Backend contract expects toAccountNumber.
  @JsonKey(name: 'toAccountNumber')
  final String toAccount;

  @JsonKey(name: 'amount')
  final double amount;

  // Backend contract expects description.
  @JsonKey(name: 'description')
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
