import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  food,
  transport,
  leisure,
  utilities,
  salary,
  subscription, // Assinaturas
  other
}

enum TransactionPaymentMethod {
  debit,
  credit,
  pix,
  other
}

class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;
  final TransactionPaymentMethod paymentMethod;
  final bool isPending;
  final bool isPaid;
  final int? installmentNumber;
  final int? totalInstallments;
  final String? installmentParentId;
  final String? recurrenceParentId;
  final String? ownerId;
  final String? familyId;
  final bool isShared;
  final String? description;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.isPending,
    required this.isPaid,
    this.installmentNumber,
    this.totalInstallments,
    this.installmentParentId,
    this.recurrenceParentId,
    this.ownerId,
    this.familyId,
    this.isShared = false,
    this.description,
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    TransactionCategory? category,
    TransactionPaymentMethod? paymentMethod,
    bool? isPending,
    bool? isPaid,
    int? installmentNumber,
    int? totalInstallments,
    String? installmentParentId,
    String? recurrenceParentId,
    String? ownerId,
    String? familyId,
    bool? isShared,
    String? description,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPending: isPending ?? this.isPending,
      isPaid: isPaid ?? this.isPaid,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      installmentParentId: installmentParentId ?? this.installmentParentId,
      recurrenceParentId: recurrenceParentId ?? this.recurrenceParentId,
      ownerId: ownerId ?? this.ownerId,
      familyId: familyId ?? this.familyId,
      isShared: isShared ?? this.isShared,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        date,
        type,
        category,
        paymentMethod,
        isPending,
        isPaid,
        installmentNumber,
        totalInstallments,
        installmentParentId,
        recurrenceParentId,
        ownerId,
        familyId,
        isShared,
        description,
      ];
}
