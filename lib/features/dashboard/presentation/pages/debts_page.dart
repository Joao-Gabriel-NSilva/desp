import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/services/user_cache.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/category_helper.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/family_service.dart';
import '../../domain/entities/user_profile.dart';
import 'transaction_detail_page.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  String? _currentUserId;
  String? _familyId;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Força atualização das dívidas ao abrir a aba
    context.read<DashboardBloc>().add(LoadDebts());
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?.uid;
        _familyId = user?.familyId;
      });
    }
  }

  void _showAddDebt(BuildContext context, DateTime currentMonth) {
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
            defaultIsPending: true,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardInitial || state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Text(
                'Erro: ${state.message}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (state is DashboardLoaded) {
            final debts = state.filteredDebts;

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dívidas & Pendências',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Itens fixos que aparecem até serem quitados.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_familyId != null && _currentUserId != null)
                    SliverToBoxAdapter(
                      child: _buildMemberFilterChips(context, _currentUserId!, _familyId!, state.selectedMemberId),
                    ),

                  // Total Acumulado Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE11D48), // Deep Rose
                              Color(0xFFBE123C),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Pendente',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              Formatters.currency(state.totalDebtsAmount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Lista de Pendências
                  if (debts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 64,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Parabéns! Tudo quitado.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Nenhuma pendência ou dívida em aberto no momento.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
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
                            final debt = debts[index];
                            final bool canModify = !debt.isShared ||
                                debt.ownerId == null ||
                                debt.ownerId == _currentUserId;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => TransactionDetailPage(transaction: debt),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 1. Icone da Categoria (com background)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: debt.category.color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          debt.category.icon,
                                          color: debt.category.color,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // 2. Informações do Meio (Título e Pills)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              debt.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: -0.2,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                // Pill Categoria
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: debt.category.color.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: debt.category.color.withValues(alpha: 0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    debt.category.namePt,
                                                    style: TextStyle(
                                                      color: debt.category.color,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                // Pill Meio Pagamento
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: Colors.white.withValues(alpha: 0.08),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Wrap(
                                                    spacing: 4,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                      Icon(
                                                        debt.paymentMethod.icon,
                                                        color: Colors.white60,
                                                        size: 10,
                                                      ),
                                                      Text(
                                                        debt.paymentMethod.namePt,
                                                        style: const TextStyle(
                                                          color: Colors.white60,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Pill Parcelas (se aplicável)
                                                if (debt.installmentNumber != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${debt.installmentNumber}/${debt.totalInstallments}x',
                                                      style: const TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                // Pill Recorrência (se aplicável)
                                                if (debt.recurrenceParentId != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      'Recorrente',
                                                      style: TextStyle(
                                                        color: Color(0xFF8B5CF6),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                // Pill Compartilhado (Família) com Nome do Membro
                                                if (debt.isShared)
                                                  debt.ownerId != null
                                                      ? FutureBuilder<String>(
                                                          future: UserCache.getUsername(debt.ownerId!),
                                                          builder: (context, snapshot) {
                                                            final name = snapshot.data ?? '...';
                                                            return Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Wrap(
                                                                spacing: 4,
                                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                                children: [
                                                                  const Icon(
                                                                    Icons.people_outline_rounded,
                                                                    color: Color(0xFF6366F1),
                                                                    size: 10,
                                                                  ),
                                                                  Text(
                                                                    name,
                                                                    style: const TextStyle(
                                                                      color: Color(0xFF6366F1),
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: const Wrap(
                                                            spacing: 4,
                                                            crossAxisAlignment: WrapCrossAlignment.center,
                                                            children: [
                                                              Icon(
                                                                Icons.people_outline_rounded,
                                                                color: Color(0xFF6366F1),
                                                                size: 10,
                                                              ),
                                                              Text(
                                                                'Família',
                                                                style: TextStyle(
                                                                  color: Color(0xFF6366F1),
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // 3. Valor e Ação (Lado Direito)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '-${Formatters.currency(debt.amount).replaceAll('R\$ ', '')}',
                                            style: const TextStyle(
                                              color: Color(0xFFF43F5E),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          canModify
                                              ? InkWell(
                                                  onTap: () async {
                                                    final bool? confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Quitar Dívida'),
                                                        content: Text('Deseja marcar a dívida "${debt.title}" como quitada?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(context).pop(false),
                                                            child: const Text('Cancelar'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () => Navigator.of(context).pop(true),
                                                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                                                            child: const Text('Quitar'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true && context.mounted) {
                                                      context
                                                          .read<DashboardBloc>()
                                                          .add(QuitDebt(transactionId: debt.id));
                                                      
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Dívida "${debt.title}" quitada com sucesso!'),
                                                          backgroundColor: const Color(0xFF10B981),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(4.0),
                                                    child: Icon(
                                                      Icons.check_circle_outline_rounded,
                                                      color: Color(0xFF10B981),
                                                      size: 22,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: debts.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            return FloatingActionButton.extended(
              heroTag: 'debts_fab',
              onPressed: () {
                _showAddDebt(context, state.targetMonth);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nova dívida',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            );
          }
          return const SizedBox.shrink();
        },
      ),
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
