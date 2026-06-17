import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final DateTime targetMonth;
  final bool isSilent;
  final String? selectedMemberId;

  const LoadDashboard({
    required this.targetMonth,
    this.isSilent = false,
    this.selectedMemberId,
  });

  @override
  List<Object?> get props => [targetMonth, isSilent, selectedMemberId];
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
  final DeleteScope deleteScope;
  final Transaction transaction;

  const DeleteTransaction({
    required this.transactionId,
    required this.targetMonth,
    this.deleteScope = DeleteScope.onlyThis,
    required this.transaction,
  });

  @override
  List<Object?> get props => [transactionId, targetMonth, deleteScope, transaction];
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
  final EditScope editScope;

  const UpdateTransaction({
    required this.transaction,
    required this.targetMonth,
    this.editScope = EditScope.onlyThis,
  });

  @override
  List<Object?> get props => [transaction, targetMonth, editScope];
}

class MarkAllTransactionsAsPaid extends DashboardEvent {
  final DateTime targetMonth;

  const MarkAllTransactionsAsPaid({required this.targetMonth});

  @override
  List<Object?> get props => [targetMonth];
}

class ChangeMemberFilter extends DashboardEvent {
  final String? selectedMemberId;

  const ChangeMemberFilter(this.selectedMemberId);

  @override
  List<Object?> get props => [selectedMemberId];
}
