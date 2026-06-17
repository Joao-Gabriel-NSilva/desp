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
  final String searchQuery;
  final TransactionCategory? selectedCategory;
  final TransactionPaymentMethod? selectedPaymentMethod;
  final bool? selectedPaidStatus; // null: todos, true: pago, false: não pago

  const DashboardLoaded({
    required this.transactions,
    required this.debts,
    required this.targetMonth,
    this.selectedMemberId,
    this.currentUserId,
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedPaymentMethod,
    this.selectedPaidStatus,
  });

  String? get activeFilter => selectedMemberId ?? currentUserId;

  List<Transaction> get filteredTransactions {
    List<Transaction> list = transactions;

    // 1. Filtro por Membro
    final filter = activeFilter;
    if (filter != 'all' && filter != null) {
      list = list.where((t) {
        if (t.ownerId == filter) return true;
        if (t.ownerId == null && filter == currentUserId) return true;
        return false;
      }).toList();
    }

    // 2. Filtro por Busca (título ou descrição)
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((t) {
        final titleMatch = t.title.toLowerCase().contains(query);
        final descMatch = t.description?.toLowerCase().contains(query) ?? false;
        return titleMatch || descMatch;
      }).toList();
    }

    // 3. Filtro por Categoria
    if (selectedCategory != null) {
      list = list.where((t) => t.category == selectedCategory).toList();
    }

    // 4. Filtro por Método de Pagamento
    if (selectedPaymentMethod != null) {
      list = list.where((t) => t.paymentMethod == selectedPaymentMethod).toList();
    }

    // 5. Filtro por Status de Pagamento
    if (selectedPaidStatus != null) {
      list = list.where((t) => t.isPaid == selectedPaidStatus).toList();
    }

    return list;
  }

  List<Transaction> get filteredDebts {
    List<Transaction> list = debts;

    // 1. Filtro por Membro
    final filter = activeFilter;
    if (filter != 'all' && filter != null) {
      list = list.where((t) {
        if (t.ownerId == filter) return true;
        if (t.ownerId == null && filter == currentUserId) return true;
        return false;
      }).toList();
    }

    // 2. Filtro por Busca (título ou descrição)
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((t) {
        final titleMatch = t.title.toLowerCase().contains(query);
        final descMatch = t.description?.toLowerCase().contains(query) ?? false;
        return titleMatch || descMatch;
      }).toList();
    }

    // 3. Filtro por Categoria
    if (selectedCategory != null) {
      list = list.where((t) => t.category == selectedCategory).toList();
    }

    // 4. Filtro por Método de Pagamento
    if (selectedPaymentMethod != null) {
      list = list.where((t) => t.paymentMethod == selectedPaymentMethod).toList();
    }

    // 5. Filtro por Status de Pagamento (Dívidas são sempre isPaid = false, mas para compatibilidade de filtros)
    if (selectedPaidStatus != null) {
      list = list.where((t) => t.isPaid == selectedPaidStatus).toList();
    }

    return list;
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
  List<Object?> get props => [
        transactions,
        debts,
        targetMonth,
        selectedMemberId,
        currentUserId,
        searchQuery,
        selectedCategory,
        selectedPaymentMethod,
        selectedPaidStatus,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
