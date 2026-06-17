import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import '../../data/services/user_cache.dart';
import '../pages/transaction_detail_page.dart';
import 'category_helper.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Future<bool> Function() onDelete;
  final ValueChanged<bool>? onTogglePaid;
  final VoidCallback? onEdit;
  final String? currentUserId;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onDelete,
    this.onTogglePaid,
    this.onEdit,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == TransactionType.income;
    final Color amountColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final String amountPrefix = isIncome ? '+' : '-';
    final bool canModify = !transaction.isShared ||
        transaction.ownerId == null ||
        transaction.ownerId == currentUserId;

    return Dismissible(
      key: Key(transaction.id),
      direction: canModify ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (direction) async {
        return await onDelete();
      },
      onDismissed: (_) {},
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFF43F5E),
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
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
                builder: (context) => TransactionDetailPage(transaction: transaction),
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
                color: transaction.category.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.category.icon,
                color: transaction.category.color,
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
                    transaction.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.2,
                      decoration: (!isIncome && transaction.isPaid) ? TextDecoration.lineThrough : null,
                      color: (!isIncome && transaction.isPaid) ? Colors.white38 : Colors.white,
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
                          color: transaction.category.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: transaction.category.color.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          transaction.category.namePt,
                          style: TextStyle(
                            color: transaction.category.color,
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
                              transaction.paymentMethod.icon,
                              color: Colors.white60,
                              size: 10,
                            ),
                            Text(
                              transaction.paymentMethod.namePt,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Pill Parcelas
                      if (transaction.installmentNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${transaction.installmentNumber}/${transaction.totalInstallments}x',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // Pill Recorrência
                      if (transaction.recurrenceParentId != null)
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
                      if (transaction.isShared)
                        transaction.ownerId != null
                            ? FutureBuilder<String>(
                                future: UserCache.getUsername(transaction.ownerId!),
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

            // 3. Valor e Ações (Lado Direito)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$amountPrefix${Formatters.currency(transaction.amount).replaceAll('R\$ ', '')}',
                  style: TextStyle(
                    color: (!isIncome && transaction.isPaid) ? Colors.white38 : amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.5,
                    decoration: (!isIncome && transaction.isPaid) ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onTogglePaid != null && !isIncome && canModify) ...[
                      InkWell(
                        onTap: () => onTogglePaid!(!transaction.isPaid),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            transaction.isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: transaction.isPaid ? const Color(0xFF10B981) : Colors.white38,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                    if (canModify) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            onEdit?.call();
                          } else if (value == 'delete') {
                            await onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 16, color: Colors.white70),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 16, color: Color(0xFFF43F5E)),
                                SizedBox(width: 8),
                                Text('Excluir', style: TextStyle(color: Color(0xFFF43F5E))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
