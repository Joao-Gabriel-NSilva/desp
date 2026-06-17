import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<Transaction> transactions;
  final List<Transaction> debts;
  final DateTime targetMonth;
  final String? selectedMemberId; // UID do membro selecionado, 'all' para todos, ou null (padrão)
  final String? currentUserId; // UID do próprio usuário logado

  const DashboardLoaded({
    required this.transactions,
    required this.debts,
    required this.targetMonth,
    this.selectedMemberId,
    this.currentUserId,
  });

  String? get activeFilter => selectedMemberId ?? currentUserId;

  List<Transaction> get filteredTransactions {
    final filter = activeFilter;
    if (filter == 'all' || filter == null) return transactions;
    return transactions.where((t) {
      if (t.ownerId == filter) return true;
      if (t.ownerId == null && filter == currentUserId) return true;
      return false;
    }).toList();
  }

  List<Transaction> get filteredDebts {
    final filter = activeFilter;
    if (filter == 'all' || filter == null) return debts;
    return debts.where((t) {
      if (t.ownerId == filter) return true;
      if (t.ownerId == null && filter == currentUserId) return true;
      return false;
    }).toList();
  }

  double get totalIncome => filteredTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalBalance => totalIncome - totalExpenses;

  double get totalDebtsAmount => filteredDebts.fold(0.0, (sum, t) => sum + t.amount);

  Map<TransactionCategory, double> get categoryExpenses {
    final Map<TransactionCategory, double> distribution = {};
    for (var t in filteredTransactions) {
      if (t.type == TransactionType.expense) {
        distribution[t.category] = (distribution[t.category] ?? 0.0) + t.amount;
      }
    }
    return distribution;
  }

  @override
  List<Object?> get props => [transactions, debts, targetMonth, selectedMemberId, currentUserId];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
