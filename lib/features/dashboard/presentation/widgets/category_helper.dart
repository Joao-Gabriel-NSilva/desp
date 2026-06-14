import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';

extension TransactionCategoryExtension on TransactionCategory {
  String get namePt {
    switch (this) {
      case TransactionCategory.food:
        return 'Alimentação';
      case TransactionCategory.transport:
        return 'Transporte';
      case TransactionCategory.leisure:
        return 'Lazer';
      case TransactionCategory.utilities:
        return 'Serviços';
      case TransactionCategory.salary:
        return 'Salário';
      case TransactionCategory.subscription:
        return 'Assinaturas';
      case TransactionCategory.other:
        return 'Outros';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionCategory.food:
        return Icons.restaurant_rounded;
      case TransactionCategory.transport:
        return Icons.directions_car_rounded;
      case TransactionCategory.leisure:
        return Icons.sports_esports_rounded;
      case TransactionCategory.utilities:
        return Icons.lightbulb_rounded;
      case TransactionCategory.salary:
        return Icons.monetization_on_rounded;
      case TransactionCategory.subscription:
        return Icons.subscriptions_rounded;
      case TransactionCategory.other:
        return Icons.help_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TransactionCategory.food:
        return const Color(0xFFF97316); // Orange 500
      case TransactionCategory.transport:
        return const Color(0xFF3B82F6); // Blue 500
      case TransactionCategory.leisure:
        return const Color(0xFFEC4899); // Pink 500
      case TransactionCategory.utilities:
        return const Color(0xFFEAB308); // Yellow 500
      case TransactionCategory.salary:
        return const Color(0xFF10B981); // Emerald 500
      case TransactionCategory.subscription:
        return const Color(0xFF8B5CF6); // Violet 500
      case TransactionCategory.other:
        return const Color(0xFF64748B); // Slate 500
    }
  }
}

extension TransactionPaymentMethodExtension on TransactionPaymentMethod {
  String get namePt {
    switch (this) {
      case TransactionPaymentMethod.debit:
        return 'Dívida/Débito';
      case TransactionPaymentMethod.credit:
        return 'C. Crédito';
      case TransactionPaymentMethod.pix:
        return 'Pix';
      case TransactionPaymentMethod.other:
        return 'Outro';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionPaymentMethod.debit:
        return Icons.payment_rounded;
      case TransactionPaymentMethod.credit:
        return Icons.credit_card_rounded;
      case TransactionPaymentMethod.pix:
        return Icons.qr_code_rounded;
      case TransactionPaymentMethod.other:
        return Icons.account_balance_wallet_rounded;
    }
  }
}
