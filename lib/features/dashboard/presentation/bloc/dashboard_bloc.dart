import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/services/auth_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TransactionRepository repository;
  String? _selectedMemberId;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<AddTransaction>(_onAddTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<ToggleTransactionPaidStatus>(_onToggleTransactionPaidStatus);
    on<LoadDebts>(_onLoadDebts);
    on<QuitDebt>(_onQuitDebt);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<MarkAllTransactionsAsPaid>(_onMarkAllTransactionsAsPaid);
    on<ChangeMemberFilter>(_onChangeMemberFilter);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    // Preservar o filtro atual
    if (event.selectedMemberId != null) {
      _selectedMemberId = event.selectedMemberId;
    } else if (state is DashboardLoaded) {
      _selectedMemberId = (state as DashboardLoaded).selectedMemberId;
    }

    if (!event.isSilent) {
      emit(DashboardLoading());
    }
    try {
      final transactions = await repository.getTransactionsByMonth(
        event.targetMonth.year,
        event.targetMonth.month,
      );
      final debts = await repository.getPendingDebts();

      final currentUser = await AuthService.instance.getCurrentUser();
      final currentUserId = currentUser?.uid;

      emit(DashboardLoaded(
        transactions: transactions,
        debts: debts,
        targetMonth: event.targetMonth,
        selectedMemberId: _selectedMemberId,
        currentUserId: currentUserId,
      ));
    } catch (e) {
      emit(DashboardError('Erro ao carregar dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final baseTx = event.transaction;

      if (event.totalInstallments != null && event.totalInstallments! > 1) {
        // Fluxo de Compra Parcelada
        final List<Transaction> installmentTxs = [];
        final totalVal = baseTx.amount;
        // Divide o valor total pelas parcelas de forma simples
        final double installmentAmount = double.parse((totalVal / event.totalInstallments!).toStringAsFixed(2));

        for (int i = 1; i <= event.totalInstallments!; i++) {
          final installmentDate = _addMonths(baseTx.date, i - 1);
          final title = '${baseTx.title} ($i/${event.totalInstallments})';

          installmentTxs.add(
            baseTx.copyWith(
              id: '${baseTx.id}_$i',
              title: title,
              amount: installmentAmount,
              date: installmentDate,
              installmentNumber: i,
              totalInstallments: event.totalInstallments,
              installmentParentId: baseTx.id,
              groupId: baseTx.id,
              isPaid: i == 1 ? baseTx.isPaid : false,
              isPending: baseTx.isPending,
            ),
          );
        }
        await repository.saveTransactions(installmentTxs);
      } else if (event.isRecurring) {
        // Fluxo de Recorrência Contínua (gera 24 parcelas/meses por padrão no SQLite)
        final List<Transaction> recurringTxs = [];

        for (int i = 1; i <= 24; i++) {
          final recurringDate = _addMonths(baseTx.date, i - 1);

          recurringTxs.add(
            baseTx.copyWith(
              id: '${baseTx.id}_$i',
              date: recurringDate,
              recurrenceParentId: baseTx.id,
              groupId: baseTx.id,
              isPaid: i == 1 ? baseTx.isPaid : false,
              isPending: false,
            ),
          );
        }
        await repository.saveTransactions(recurringTxs);
      } else {
        // Transação Normal (Única)
        await repository.saveTransaction(baseTx);
      }

      // Recarrega o estado com o mês alvo atualizado
      add(LoadDashboard(targetMonth: event.targetMonth));
    } catch (e) {
      emit(DashboardError('Erro ao adicionar transação: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.saveTransactionWithScope(event.transaction, event.editScope);
      add(LoadDashboard(targetMonth: event.targetMonth));
    } catch (e) {
      emit(DashboardError('Erro ao atualizar transação: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.deleteTransactionWithScope(event.transaction, event.deleteScope);
      add(LoadDashboard(targetMonth: event.targetMonth));
    } catch (e) {
      emit(DashboardError('Erro ao deletar transação: ${e.toString()}'));
    }
  }

  Future<void> _onToggleTransactionPaidStatus(
    ToggleTransactionPaidStatus event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.updateTransactionPaidStatus(event.transactionId, event.isPaid);
      add(LoadDashboard(targetMonth: event.targetMonth, isSilent: true));
    } catch (e) {
      emit(DashboardError('Erro ao alterar status de pagamento: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDebts(
    LoadDebts event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      try {
        final debts = await repository.getPendingDebts();
        emit(DashboardLoaded(
          transactions: currentState.transactions,
          debts: debts,
          targetMonth: currentState.targetMonth,
          selectedMemberId: _selectedMemberId,
          currentUserId: currentState.currentUserId,
        ));
      } catch (e) {
        emit(DashboardError('Erro ao carregar dívidas: ${e.toString()}'));
      }
    }
  }

  Future<void> _onQuitDebt(
    QuitDebt event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      try {
        await repository.updateTransactionPaidStatus(event.transactionId, true);
        add(LoadDashboard(targetMonth: currentState.targetMonth, isSilent: true));
      } catch (e) {
        emit(DashboardError('Erro ao quitar dívida: ${e.toString()}'));
      }
    }
  }

  Future<void> _onMarkAllTransactionsAsPaid(
    MarkAllTransactionsAsPaid event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.markAllTransactionsAsPaidForMonth(
        event.targetMonth.year,
        event.targetMonth.month,
      );
      add(LoadDashboard(targetMonth: event.targetMonth));
    } catch (e) {
      emit(DashboardError('Erro ao quitar todas as despesas: ${e.toString()}'));
    }
  }

  void _onChangeMemberFilter(
    ChangeMemberFilter event,
    Emitter<DashboardState> emit,
  ) {
    _selectedMemberId = event.selectedMemberId;
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(DashboardLoaded(
        transactions: currentState.transactions,
        debts: currentState.debts,
        targetMonth: currentState.targetMonth,
        selectedMemberId: _selectedMemberId,
        currentUserId: currentState.currentUserId,
      ));
    }
  }

  // Helper para adicionar meses a uma data respeitando limites do mês
  DateTime _addMonths(DateTime date, int months) {
    int year = date.year;
    int month = date.month + months;
    while (month > 12) {
      year += 1;
      month -= 12;
    }
    int day = date.day;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }
}
