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

  const DashboardLoaded({
    required this.transactions,
    required this.debts,
    required this.targetMonth,
  });

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalBalance => totalIncome - totalExpenses;

  double get totalDebtsAmount => debts.fold(0.0, (sum, t) => sum + t.amount);

  Map<TransactionCategory, double> get categoryExpenses {
    final Map<TransactionCategory, double> distribution = {};
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        distribution[t.category] = (distribution[t.category] ?? 0.0) + t.amount;
      }
    }
    return distribution;
  }

  @override
  List<Object?> get props => [transactions, debts, targetMonth];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
