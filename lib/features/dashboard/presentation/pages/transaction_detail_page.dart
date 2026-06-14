import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import '../../data/services/user_cache.dart';
import '../widgets/category_helper.dart';

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isIncome = transaction.type == TransactionType.income;
    final Color amountColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final String amountPrefix = isIncome ? '+' : '-';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalhes da Transação',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card do Topo: Icone, Titulo e Valor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Categoria Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: transaction.category.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        transaction.category.icon,
                        color: transaction.category.color,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Título da Transação
                    Text(
                      transaction.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Valor Formatado
                    Text(
                      '$amountPrefix${Formatters.currency(transaction.amount)}',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Badge de Status (Pago / Pendente / Recebido)
                    _buildStatusBadge(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Seção de Informações
              const Text(
                'Informações',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Lista de Detalhes
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildDetailItem(
                      icon: Icons.category_outlined,
                      label: 'Categoria',
                      value: transaction.category.namePt,
                      valueColor: transaction.category.color,
                    ),
                    _buildDivider(),
                    _buildDetailItem(
                      icon: Icons.payment_outlined,
                      label: 'Meio de Pagamento',
                      value: transaction.paymentMethod.namePt,
                    ),
                    _buildDivider(),
                    _buildDetailItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Data',
                      value: Formatters.date(transaction.date),
                    ),
                    if (transaction.installmentNumber != null) ...[
                      _buildDivider(),
                      _buildDetailItem(
                        icon: Icons.style_outlined,
                        label: 'Parcela',
                        value: '${transaction.installmentNumber}ª de ${transaction.totalInstallments}',
                        valueColor: Colors.amber,
                      ),
                    ],
                    if (transaction.recurrenceParentId != null) ...[
                      _buildDivider(),
                      _buildDetailItem(
                        icon: Icons.repeat_rounded,
                        label: 'Recorrência',
                        value: 'Frequência Mensal',
                        valueColor: const Color(0xFF8B5CF6),
                      ),
                    ],
                    if (transaction.isShared && transaction.ownerId != null) ...[
                      _buildDivider(),
                      FutureBuilder<String>(
                        future: UserCache.getUsername(transaction.ownerId!),
                        builder: (context, snapshot) {
                          final name = snapshot.data ?? 'Carregando...';
                          return _buildDetailItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Adicionado por',
                            value: name,
                            valueColor: const Color(0xFF6366F1),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Seção de Descrição (Se houver)
              if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                const Text(
                  'Descrição detalhada',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    transaction.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bool isPaid = transaction.isPaid;
    final bool isPending = transaction.isPending;
    final bool isIncome = transaction.type == TransactionType.income;

    Color badgeColor;
    String label;
    IconData icon;

    if (isIncome) {
      badgeColor = const Color(0xFF10B981);
      label = 'Recebido';
      icon = Icons.check_circle_rounded;
    } else if (isPaid) {
      badgeColor = const Color(0xFF10B981);
      label = 'Pago';
      icon = Icons.check_circle_rounded;
    } else if (isPending) {
      badgeColor = const Color(0xFFE11D48);
      label = 'Dívida Pendente';
      icon = Icons.warning_amber_rounded;
    } else {
      badgeColor = Colors.amber;
      label = 'Pendente';
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.04),
    );
  }
}
