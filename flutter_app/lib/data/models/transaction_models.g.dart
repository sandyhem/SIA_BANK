// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionDTO _$TransactionDTOFromJson(Map<String, dynamic> json) =>
    TransactionDTO(
      transactionId: json['transactionId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      status: json['status'] as String,
      narration: json['narration'] as String?,
      fromAccount: json['fromAccount'] as String?,
      toAccount: json['toAccount'] as String?,
      reference: json['reference'] as String?,
    );

Map<String, dynamic> _$TransactionDTOToJson(TransactionDTO instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'type': instance.type,
      'amount': instance.amount,
      'date': instance.date,
      'status': instance.status,
      'narration': instance.narration,
      'fromAccount': instance.fromAccount,
      'toAccount': instance.toAccount,
      'reference': instance.reference,
    };

TransferRequestDTO _$TransferRequestDTOFromJson(Map<String, dynamic> json) =>
    TransferRequestDTO(
      fromAccount: json['fromAccountNumber'] as String,
      toAccount: json['toAccountNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      narration: json['description'] as String?,
    );

Map<String, dynamic> _$TransferRequestDTOToJson(TransferRequestDTO instance) =>
    <String, dynamic>{
      'fromAccountNumber': instance.fromAccount,
      'toAccountNumber': instance.toAccount,
      'amount': instance.amount,
      'description': instance.narration,
    };

RecurringTransferDTO _$RecurringTransferDTOFromJson(
        Map<String, dynamic> json) =>
    RecurringTransferDTO(
      recurringTransferId: json['recurringTransferId'] as String,
      fromAccount: json['fromAccount'] as String,
      toAccount: json['toAccount'] as String,
      amount: (json['amount'] as num).toDouble(),
      frequency: json['frequency'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
      status: json['status'] as String,
      narration: json['narration'] as String?,
      nextScheduledDate: json['nextScheduledDate'] as String?,
    );

Map<String, dynamic> _$RecurringTransferDTOToJson(
        RecurringTransferDTO instance) =>
    <String, dynamic>{
      'recurringTransferId': instance.recurringTransferId,
      'fromAccount': instance.fromAccount,
      'toAccount': instance.toAccount,
      'amount': instance.amount,
      'frequency': instance.frequency,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'status': instance.status,
      'narration': instance.narration,
      'nextScheduledDate': instance.nextScheduledDate,
    };

BillPaymentDTO _$BillPaymentDTOFromJson(Map<String, dynamic> json) =>
    BillPaymentDTO(
      paymentId: json['paymentId'] as String,
      fromAccount: json['fromAccount'] as String,
      providerCode: json['providerCode'] as String,
      billReference: json['billReference'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: json['dueDate'] as String?,
      status: json['status'] as String,
      paymentDate: json['paymentDate'] as String?,
    );

Map<String, dynamic> _$BillPaymentDTOToJson(BillPaymentDTO instance) =>
    <String, dynamic>{
      'paymentId': instance.paymentId,
      'fromAccount': instance.fromAccount,
      'providerCode': instance.providerCode,
      'billReference': instance.billReference,
      'amount': instance.amount,
      'dueDate': instance.dueDate,
      'status': instance.status,
      'paymentDate': instance.paymentDate,
    };

AlertDTO _$AlertDTOFromJson(Map<String, dynamic> json) => AlertDTO(
      alertId: json['alertId'] as String,
      severity: json['severity'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      timestamp: json['timestamp'] as String,
      actionRequired: json['actionRequired'] as bool,
      actionUrl: json['actionUrl'] as String?,
    );

Map<String, dynamic> _$AlertDTOToJson(AlertDTO instance) => <String, dynamic>{
      'alertId': instance.alertId,
      'severity': instance.severity,
      'type': instance.type,
      'description': instance.description,
      'timestamp': instance.timestamp,
      'actionRequired': instance.actionRequired,
      'actionUrl': instance.actionUrl,
    };
