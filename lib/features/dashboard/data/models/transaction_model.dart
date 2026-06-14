import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.date,
    required super.type,
    required super.category,
    required super.paymentMethod,
    required super.isPending,
    required super.isPaid,
    super.installmentNumber,
    super.totalInstallments,
    super.installmentParentId,
    super.recurrenceParentId,
    super.ownerId,
    super.familyId,
    super.isShared,
    super.description,
  });

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      type: transaction.type,
      category: transaction.category,
      paymentMethod: transaction.paymentMethod,
      isPending: transaction.isPending,
      isPaid: transaction.isPaid,
      installmentNumber: transaction.installmentNumber,
      totalInstallments: transaction.totalInstallments,
      installmentParentId: transaction.installmentParentId,
      recurrenceParentId: transaction.recurrenceParentId,
      ownerId: transaction.ownerId,
      familyId: transaction.familyId,
      isShared: transaction.isShared,
      description: transaction.description,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values.byName(map['type'] as String),
      category: TransactionCategory.values.byName(map['category'] as String),
      paymentMethod: TransactionPaymentMethod.values.byName(map['paymentMethod'] as String),
      isPending: map['isPending'] == true || map['isPending'] == 1,
      isPaid: map['isPaid'] == true || map['isPaid'] == 1,
      installmentNumber: map['installmentNumber'] as int?,
      totalInstallments: map['totalInstallments'] as int?,
      installmentParentId: map['installmentParentId'] as String?,
      recurrenceParentId: map['recurrenceParentId'] as String?,
      ownerId: map['ownerId'] as String?,
      familyId: map['familyId'] as String?,
      isShared: map['isShared'] == true || map['isShared'] == 1,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'category': category.name,
      'paymentMethod': paymentMethod.name,
      'isPending': isPending ? 1 : 0,
      'isPaid': isPaid ? 1 : 0,
      'installmentNumber': installmentNumber,
      'totalInstallments': totalInstallments,
      'installmentParentId': installmentParentId,
      'recurrenceParentId': recurrenceParentId,
      'ownerId': ownerId,
      'familyId': familyId,
      'isShared': isShared ? 1 : 0,
      'description': description,
    };
  }
}
