import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/services/auth_service.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/category_helper.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list_item.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

  void _showEditTransaction(BuildContext context, Transaction transaction, DateTime currentMonth) {
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
                  ));
            },
          ),
        );
      },
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
          final transactions = state.transactions;
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

                    // Seletor de Mês/Ano (com DatePicker no click)
                    SliverToBoxAdapter(
                      child: Padding(
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
                                  _showEditTransaction(context, transaction, currentMonth);
                                },
                                onDelete: () {
                                  context.read<DashboardBloc>().add(
                                        DeleteTransaction(
                                          transactionId: transaction.id,
                                          targetMonth: currentMonth,
                                        ),
                                      );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${transaction.title}" excluído.'),
                                      backgroundColor: const Color(0xFF1E293B),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
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
}
