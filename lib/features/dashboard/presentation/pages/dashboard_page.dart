import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/family_service.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/category_helper.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/search_and_filters_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isFiltersExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<DashboardBloc>();
        final targetMonth = bloc.state is DashboardLoaded
            ? (bloc.state as DashboardLoaded).targetMonth
            : DateTime.now();
        bloc.add(LoadDashboard(targetMonth: targetMonth));
      }
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return months[month - 1];
  }

  void _showAddTransaction(BuildContext context, DateTime currentMonth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: BlocProvider.of<DashboardBloc>(context),
          child: AddTransactionDialog(
            initialDate: currentMonth,
            onSave: (transaction, totalInstallments, isRecurring) {
              context.read<DashboardBloc>().add(AddTransaction(
                    transaction: transaction,
                    totalInstallments: totalInstallments,
                    isRecurring: isRecurring,
                    targetMonth: currentMonth,
                  ));
            },
          ),
        );
      },
    );
  }

  void _showEditTransaction(BuildContext context, Transaction transaction, DateTime currentMonth, EditScope editScope) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: BlocProvider.of<DashboardBloc>(context),
          child: AddTransactionDialog(
            initialTransaction: transaction,
            onSave: (updatedTx, totalInstallments, isRecurring) {
              context.read<DashboardBloc>().add(UpdateTransaction(
                    transaction: updatedTx,
                    targetMonth: currentMonth,
                    editScope: editScope,
                  ));
            },
          ),
        );
      },
    );
  }

  Future<void> _handleEditClick(BuildContext context, Transaction transaction, DateTime currentMonth) async {
    final bool isRecurring = transaction.recurrenceParentId != null;
    final bool isInstallment = transaction.installmentParentId != null;

    if (!isRecurring && !isInstallment) {
      _showEditTransaction(context, transaction, currentMonth, EditScope.onlyThis);
      return;
    }

    final EditScope? scope = await showDialog<EditScope>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          isRecurring ? 'Editar Despesa Recorrente' : 'Editar Compra Parcelada',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isRecurring
              ? 'Esta é uma despesa recorrente. O que você deseja editar?'
              : 'Esta é uma despesa parcelada. O que você deseja editar?',
          style: const TextStyle(color: Colors.white70),
        ),
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(EditScope.onlyThis),
            child: const Text('Apenas esta ocorrência', style: TextStyle(color: Color(0xFF6366F1))),
          ),
          if (isRecurring)
            TextButton(
              onPressed: () => Navigator.of(context).pop(EditScope.thisAndFuture),
              child: const Text('Esta e as futuras', style: TextStyle(color: Color(0xFF6366F1))),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(EditScope.all),
            child: Text(
              isRecurring ? 'Toda a série' : 'Todas as parcelas',
              style: const TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );

    if (scope != null && context.mounted) {
      _showEditTransaction(context, transaction, currentMonth, scope);
    }
  }

  Future<DeleteScope?> _showDeleteScopeDialog(BuildContext context, Transaction transaction) async {
    final bool isRecurring = transaction.recurrenceParentId != null;
    final bool isInstallment = transaction.installmentParentId != null;

    if (!isRecurring && !isInstallment) {
      return showDialog<DeleteScope>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Excluir Transação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Deseja realmente excluir "${transaction.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(DeleteScope.onlyThis),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE11D48)),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
    }

    return showDialog<DeleteScope>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          isRecurring ? 'Excluir Despesa Recorrente' : 'Excluir Compra Parcelada',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isRecurring
              ? 'Esta é uma despesa recorrente. Como deseja excluí-la?'
              : 'Esta é uma despesa parcelada. Como deseja excluí-la?',
          style: const TextStyle(color: Colors.white70),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(DeleteScope.onlyThis),
            child: const Text('Apenas esta', style: TextStyle(color: Color(0xFF6366F1))),
          ),
          if (isRecurring)
            TextButton(
              onPressed: () => Navigator.of(context).pop(DeleteScope.thisAndFuture),
              child: const Text('Esta e as futuras', style: TextStyle(color: Color(0xFF6366F1))),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(DeleteScope.all),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE11D48)),
            child: Text(isRecurring ? 'Toda a série' : 'Todas as parcelas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<UserProfile?>(
      future: AuthService.instance.getCurrentUser(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final String currentUserId = user?.uid ?? '';
        final String username = user?.username ?? 'Usuário';
        final String initials = (username.length >= 2)
            ? username.substring(0, 2).toUpperCase()
            : (username.isNotEmpty ? username[0].toUpperCase() : 'JS');

        return BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
        if (state is DashboardInitial || state is DashboardLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ),
          );
        }

        if (state is DashboardError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Erro: ${state.message}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        if (state is DashboardLoaded) {
          final transactions = state.filteredTransactions;
          final currentMonth = state.targetMonth;
          final hasUnpaidExpenses = transactions.any((t) => t.type == TransactionType.expense && !t.isPaid);

          return Scaffold(
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(LoadDashboard(targetMonth: currentMonth));
                },
                color: theme.primaryColor,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header (Usuario & Avatar)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bem-vindo de volta,',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  username,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                Scaffold.of(context).openDrawer();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.primaryColor.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF1E293B),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Filtros e Período Colapsável (Data, Membros e Busca)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFiltersExpanded = !_isFiltersExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Período & Filtros',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Icon(
                                    _isFiltersExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: const Color(0xFF64748B),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ClipRect(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: _isFiltersExpanded
                                  ? Column(
                                      children: [
                                        // Seletor de Mês/Ano (com DatePicker no click)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.cardTheme.color,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.04),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white60),
                                                  onPressed: () {
                                                    final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                                                    context.read<DashboardBloc>().add(LoadDashboard(targetMonth: prevMonth));
                                                  },
                                                ),
                                                InkWell(
                                                  onTap: () async {
                                                    final DateTime? picked = await showDatePicker(
                                                      context: context,
                                                      initialDate: currentMonth,
                                                      firstDate: DateTime(2020),
                                                      lastDate: DateTime(2030),
                                                      helpText: 'SELECIONE O MÊS E ANO',
                                                      builder: (context, child) {
                                                        return Theme(
                                                          data: theme.copyWith(
                                                            colorScheme: theme.colorScheme.copyWith(
                                                              primary: theme.primaryColor,
                                                              onPrimary: Colors.white,
                                                              surface: const Color(0xFF1E293B),
                                                              onSurface: Colors.white,
                                                            ),
                                                          ),
                                                          child: child!,
                                                        );
                                                      },
                                                    );
                                                    if (picked != null && context.mounted) {
                                                      final target = DateTime(picked.year, picked.month);
                                                      context.read<DashboardBloc>().add(LoadDashboard(targetMonth: target));
                                                    }
                                                  },
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          '${_getMonthName(currentMonth.month)} de ${currentMonth.year}',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Icon(
                                                          Icons.arrow_drop_down_rounded,
                                                          color: Colors.white60,
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white60),
                                                  onPressed: () {
                                                    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                                                    context.read<DashboardBloc>().add(LoadDashboard(targetMonth: nextMonth));
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (user?.familyId != null)
                                          _buildMemberFilterChips(context, currentUserId, user!.familyId!, state.selectedMemberId),
                                        const SearchAndFiltersBar(),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cards Resumo
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          children: [
                            // Card Saldo Principal
                            SummaryCard(
                              title: 'Saldo Geral do Mês',
                              value: state.totalBalance,
                              icon: Icons.account_balance_wallet_rounded,
                              accentColor: theme.primaryColor,
                              gradientColors: const [
                                Color(0xFF6366F1), // Indigo
                                Color(0xFF4F46E5),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Cards Receita/Despesa Lado a Lado
                            Row(
                              children: [
                                Expanded(
                                  child: SummaryCard(
                                    title: 'Receitas',
                                    value: state.totalIncome,
                                    icon: Icons.trending_up_rounded,
                                    accentColor: const Color(0xFF10B981),
                                    gradientColors: const [
                                      Color(0xFF10B981), // Emerald
                                      Color(0xFF059669),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SummaryCard(
                                    title: 'Despesas',
                                    value: state.totalExpenses,
                                    icon: Icons.trending_down_rounded,
                                    accentColor: const Color(0xFFF43F5E),
                                    gradientColors: const [
                                      Color(0xFFF43F5E), // Rose
                                      Color(0xFFE11D48),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Gráfico/Divisão por Categorias
                    if (state.categoryExpenses.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                          child: Text(
                            'Distribuição de Gastos',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.04),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: state.categoryExpenses.entries.map((entry) {
                              final category = entry.key;
                              final amount = entry.value;
                              final totalExp = state.totalExpenses;
                              final double pct = totalExp > 0 ? (amount / totalExp) : 0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              category.icon,
                                              color: category.color,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              category.namePt,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${(pct * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: category.color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 8,
                                        backgroundColor: const Color(0xFF334155).withValues(alpha: 0.3),
                                        valueColor: AlwaysStoppedAnimation<Color>(category.color),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

                    // Recentes
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transações do Mês',
                              style: theme.textTheme.titleMedium,
                            ),
                            Row(
                              children: [
                                if (hasUnpaidExpenses) ...[
                                  TextButton.icon(
                                    onPressed: () async {
                                      final bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Quitar Todas as Despesas'),
                                          content: const Text(
                                              'Deseja marcar todas as despesas deste mês como pagas?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: TextButton.styleFrom(
                                                  foregroundColor: const Color(0xFF10B981)),
                                              child: const Text('Quitar todas'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true && context.mounted) {
                                        context.read<DashboardBloc>().add(
                                            MarkAllTransactionsAsPaid(targetMonth: currentMonth));
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Todas as despesas do mês foram marcadas como pagas!'),
                                            backgroundColor: Color(0xFF10B981),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.done_all_rounded, size: 16),
                                    label: const Text('Quitar todas'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF10B981),
                                      textStyle: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                if (transactions.isNotEmpty)
                                  Text(
                                    '${transactions.length} itens',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (transactions.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 64),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 64,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhuma transação cadastrada para este mês.',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final transaction = transactions[index];
                              return TransactionListItem(
                                transaction: transaction,
                                currentUserId: currentUserId,
                                onTogglePaid: (isPaid) {
                                  context.read<DashboardBloc>().add(
                                        ToggleTransactionPaidStatus(
                                          transactionId: transaction.id,
                                          isPaid: isPaid,
                                          targetMonth: currentMonth,
                                        ),
                                      );
                                },
                                onEdit: () {
                                  _handleEditClick(context, transaction, currentMonth);
                                },
                                onDelete: () async {
                                  final scope = await _showDeleteScopeDialog(context, transaction);
                                  if (scope != null && context.mounted) {
                                    context.read<DashboardBloc>().add(
                                          DeleteTransaction(
                                            transactionId: transaction.id,
                                            targetMonth: currentMonth,
                                            deleteScope: scope,
                                            transaction: transaction,
                                          ),
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('"${transaction.title}" excluído.'),
                                        backgroundColor: const Color(0xFF1E293B),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return true;
                                  }
                                  return false;
                                },
                              );
                            },
                            childCount: transactions.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 90),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'dashboard_fab',
              onPressed: () {
                _showAddTransaction(context, currentMonth);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nova transação',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
      },
    );
  }

  Widget _buildMemberFilterChips(BuildContext context, String currentUserId, String familyId, String? selectedFilter) {
    return StreamBuilder<List<UserProfile>>(
      stream: FamilyService.instance.getFamilyMembersStream(familyId),
      builder: (context, snapshot) {
        final List<Map<String, String>> filterOptions = [
          {'id': currentUserId, 'name': 'Eu'},
          {'id': 'all', 'name': 'Todos'},
        ];

        if (snapshot.hasData) {
          for (var member in snapshot.data!) {
            if (member.uid != currentUserId) {
              filterOptions.add({'id': member.uid, 'name': member.username});
            }
          }
        }

        final activeFilter = selectedFilter ?? currentUserId;

        return Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filterOptions.length,
            itemBuilder: (context, index) {
              final option = filterOptions[index];
              final isSelected = activeFilter == option['id'];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    option['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6366F1),
                  backgroundColor: const Color(0xFF1E293B),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.04),
                      width: 1,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context.read<DashboardBloc>().add(ChangeMemberFilter(option['id']));
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
