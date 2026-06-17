import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import 'category_helper.dart';

class SearchAndFiltersBar extends StatefulWidget {
  const SearchAndFiltersBar({super.key});

  @override
  State<SearchAndFiltersBar> createState() => _SearchAndFiltersBarState();
}

class _SearchAndFiltersBarState extends State<SearchAndFiltersBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<DashboardBloc>();
    final initialQuery = bloc.state is DashboardLoaded
        ? (bloc.state as DashboardLoaded).searchQuery
        : '';
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterBottomSheet(
    BuildContext context,
    DashboardLoaded currentState,
  ) {
    // Valores temporários para edição antes de aplicar
    TransactionCategory? tempCategory = currentState.selectedCategory;
    TransactionPaymentMethod? tempPaymentMethod = currentState.selectedPaymentMethod;
    bool? tempPaidStatus = currentState.selectedPaidStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        final modalTheme = Theme.of(modalContext);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtros Avançados',
                        style: modalTheme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Seção: Status de Pagamento
                  Text(
                    'Status de Pagamento',
                    style: modalTheme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Todos',
                        isSelected: tempPaidStatus == null,
                        onSelected: () => setModalState(() => tempPaidStatus = null),
                        theme: modalTheme,
                      ),
                      _buildFilterChip(
                        label: 'Pagas',
                        isSelected: tempPaidStatus == true,
                        onSelected: () => setModalState(() => tempPaidStatus = true),
                        theme: modalTheme,
                        selectedColor: const Color(0xFF10B981),
                      ),
                      _buildFilterChip(
                        label: 'Não Pagas',
                        isSelected: tempPaidStatus == false,
                        onSelected: () => setModalState(() => tempPaidStatus = false),
                        theme: modalTheme,
                        selectedColor: const Color(0xFFF43F5E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Seção: Categoria
                  Text(
                    'Categoria',
                    style: modalTheme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildFilterChip(
                            label: 'Todas',
                            isSelected: tempCategory == null,
                            onSelected: () => setModalState(() => tempCategory = null),
                            theme: modalTheme,
                          ),
                        ),
                        ...TransactionCategory.values.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat.icon,
                                    size: 16,
                                    color: tempCategory == cat ? Colors.white : cat.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(cat.namePt),
                                ],
                              ),
                              selected: tempCategory == cat,
                              onSelected: (_) => setModalState(() => tempCategory = cat),
                              backgroundColor: const Color(0xFF1E293B),
                              selectedColor: cat.color,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: tempCategory == cat ? Colors.white : const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: tempCategory == cat
                                      ? cat.color
                                      : Colors.white.withValues(alpha: 0.04),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seção: Método de Pagamento
                  Text(
                    'Método de Pagamento',
                    style: modalTheme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildFilterChip(
                            label: 'Todos',
                            isSelected: tempPaymentMethod == null,
                            onSelected: () => setModalState(() => tempPaymentMethod = null),
                            theme: modalTheme,
                          ),
                        ),
                        ...TransactionPaymentMethod.values.map((method) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    method.icon,
                                    size: 16,
                                    color: tempPaymentMethod == method ? Colors.white : const Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(method.namePt),
                                ],
                              ),
                              selected: tempPaymentMethod == method,
                              onSelected: (_) => setModalState(() => tempPaymentMethod = method),
                              backgroundColor: const Color(0xFF1E293B),
                              selectedColor: const Color(0xFF6366F1),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: tempPaymentMethod == method ? Colors.white : const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: tempPaymentMethod == method
                                      ? const Color(0xFF6366F1)
                                      : Colors.white.withValues(alpha: 0.04),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ações
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempCategory = null;
                              tempPaymentMethod = null;
                              tempPaidStatus = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFF334155)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Limpar Tudo', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<DashboardBloc>().add(ChangeAdvancedFilters(
                                  selectedCategory: tempCategory,
                                  selectedPaymentMethod: tempPaymentMethod,
                                  selectedPaidStatus: tempPaidStatus,
                                ));
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Aplicar Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required ThemeData theme,
    Color selectedColor = const Color(0xFF6366F1),
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: selectedColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? selectedColor : Colors.white.withValues(alpha: 0.04),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) return const SizedBox.shrink();

        // Sincroniza a busca da barra de texto se alterado fora (limpeza, etc)
        if (_searchController.text != state.searchQuery) {
          _searchController.text = state.searchQuery;
        }

        final hasActiveFilters = state.selectedCategory != null ||
            state.selectedPaymentMethod != null ||
            state.selectedPaidStatus != null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // Barra de Busca
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      context.read<DashboardBloc>().add(ChangeAdvancedFilters(
                            searchQuery: value,
                          ));
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Buscar por título ou descrição...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context.read<DashboardBloc>().add(const ChangeAdvancedFilters(
                                      searchQuery: '',
                                    ));
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Botão de Filtro
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => _openFilterBottomSheet(context, state),
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasActiveFilters
                              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.04),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: hasActiveFilters ? const Color(0xFF6366F1) : Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
