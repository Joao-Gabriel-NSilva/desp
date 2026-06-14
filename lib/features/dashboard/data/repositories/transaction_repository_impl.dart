import 'dart:convert';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../services/firestore_sync_service.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    final model = TransactionModel.fromEntity(transaction);
    await db.insert(
      'transactions',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sincroniza com Firestore
    if (model.isShared) {
      await FirestoreSyncService.instance.uploadTransaction(model);
    } else {
      await FirestoreSyncService.instance.deleteTransaction(model.id);
    }
  }

  @override
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var transaction in transactions) {
        final model = TransactionModel.fromEntity(transaction);
        batch.insert(
          'transactions',
          model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });

    // Sincroniza no Firestore
    for (var transaction in transactions) {
      if (transaction.isShared) {
        await FirestoreSyncService.instance.uploadTransaction(transaction);
      } else {
        await FirestoreSyncService.instance.deleteTransaction(transaction.id);
      }
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Sincroniza no Firestore
    await FirestoreSyncService.instance.deleteTransaction(id);
  }

  @override
  Future<void> updateTransactionPaidStatus(String id, bool isPaid) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      {'isPaid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Sincroniza no Firestore se for compartilhada
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final txModel = TransactionModel.fromMap(maps.first);
      if (txModel.isShared) {
        await FirestoreSyncService.instance.uploadTransaction(txModel);
      }
    }
  }

  @override
  Future<void> markAllTransactionsAsPaidForMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final monthStr = month.toString().padLeft(2, '0');
    final queryPattern = '$year-$monthStr%';
    await db.update(
      'transactions',
      {'isPaid': 1},
      where: 'date LIKE ? AND isPending = 0 AND type = ?',
      whereArgs: [queryPattern, 'expense'],
    );

    // Sincroniza as transações compartilhadas daquele mês no Firestore
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date LIKE ? AND isPending = 0 AND type = ? AND isShared = 1',
      whereArgs: [queryPattern, 'expense'],
    );
    for (var map in maps) {
      final txModel = TransactionModel.fromMap(map);
      await FirestoreSyncService.instance.uploadTransaction(txModel);
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final monthStr = month.toString().padLeft(2, '0');
    final queryPattern = '$year-$monthStr%';

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date LIKE ? AND isPending = 0',
      whereArgs: [queryPattern],
      orderBy: 'date DESC',
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<List<Transaction>> getPendingDebts() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'isPending = 1 AND isPaid = 0',
      orderBy: 'date DESC',
    );

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<String> exportData() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return jsonEncode(maps);
  }

  @override
  Future<void> importData(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      throw const FormatException('Formato de backup inválido. Deve ser uma lista.');
    }

    for (var item in decoded) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Item do backup inválido.');
      }
      if (!item.containsKey('id') ||
          !item.containsKey('title') ||
          !item.containsKey('amount') ||
          !item.containsKey('date') ||
          !item.containsKey('type')) {
        throw const FormatException('Dados de transação incompletos no backup.');
      }
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      final batch = txn.batch();
      for (var item in decoded) {
        batch.insert(
          'transactions',
          item as Map<String, dynamic>,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });

    // Sincroniza todas as transações compartilhadas recém-importadas
    for (var item in decoded) {
      final txModel = TransactionModel.fromMap(item as Map<String, dynamic>);
      if (txModel.isShared) {
        await FirestoreSyncService.instance.uploadTransaction(txModel);
      }
    }
  }
}
