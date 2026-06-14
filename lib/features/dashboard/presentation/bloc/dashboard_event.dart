import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final DateTime targetMonth;
  final bool isSilent;

  const LoadDashboard({required this.targetMonth, this.isSilent = false});

  @override
  List<Object?> get props => [targetMonth, isSilent];
}

class AddTransaction extends DashboardEvent {
  final Transaction transaction;
  final int? totalInstallments;
  final bool isRecurring;
  final DateTime targetMonth; // para atualizar a UI do mês correto

  const AddTransaction({
    required this.transaction,
    this.totalInstallments,
    this.isRecurring = false,
    required this.targetMonth,
  });

  @override
  List<Object?> get props => [transaction, totalInstallments, isRecurring, targetMonth];
}

class ToggleTransactionPaidStatus extends DashboardEvent {
  final String transactionId;
  final bool isPaid;
  final DateTime targetMonth;

  const ToggleTransactionPaidStatus({
    required this.transactionId,
    required this.isPaid,
    required this.targetMonth,
  });

  @override
  List<Object?> get props => [transactionId, isPaid, targetMonth];
}

class DeleteTransaction extends DashboardEvent {
  final String transactionId;
  final DateTime targetMonth;

  const DeleteTransaction({
    required this.transactionId,
    required this.targetMonth,
  });

  @override
  List<Object?> get props => [transactionId, targetMonth];
}

class LoadDebts extends DashboardEvent {}

class QuitDebt extends DashboardEvent {
  final String transactionId;

  const QuitDebt({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

class UpdateTransaction extends DashboardEvent {
  final Transaction transaction;
  final DateTime targetMonth;

  const UpdateTransaction({
    required this.transaction,
    required this.targetMonth,
  });

  @override
  List<Object?> get props => [transaction, targetMonth];
}

class MarkAllTransactionsAsPaid extends DashboardEvent {
  final DateTime targetMonth;

  const MarkAllTransactionsAsPaid({required this.targetMonth});

  @override
  List<Object?> get props => [targetMonth];
}
