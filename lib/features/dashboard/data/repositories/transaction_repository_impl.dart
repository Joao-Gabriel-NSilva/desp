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

    // Consulta se a transação já existia localmente e se estava compartilhada
    final List<Map<String, dynamic>> existing = await db.query(
      'transactions',
      columns: ['isShared'],
      where: 'id = ?',
      whereArgs: [model.id],
    );
    final bool wasShared = existing.isNotEmpty &&
        (existing.first['isShared'] == 1 || existing.first['isShared'] == true);

    await db.insert(
      'transactions',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sincroniza com Firestore
    if (model.isShared) {
      await FirestoreSyncService.instance.uploadTransaction(model);
    } else if (wasShared) {
      await FirestoreSyncService.instance.deleteTransaction(model.id);
    }
  }

  @override
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final db = await _dbHelper.database;

    // Consulta em lote quais IDs já estavam compartilhados no SQLite
    final Map<String, bool> wasSharedMap = {};
    if (transactions.isNotEmpty) {
      final ids = transactions.map((t) => t.id).toList();
      final placeholders = List.filled(ids.length, '?').join(',');
      final List<Map<String, dynamic>> existing = await db.query(
        'transactions',
        columns: ['id', 'isShared'],
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
      for (var row in existing) {
        final id = row['id'] as String;
        final isShared = row['isShared'] == 1 || row['isShared'] == true;
        wasSharedMap[id] = isShared;
      }
    }

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
    final List<Transaction> uploads = [];
    final List<String> deletes = [];
    for (var transaction in transactions) {
      if (transaction.isShared) {
        uploads.add(transaction);
      } else if (wasSharedMap[transaction.id] == true) {
        deletes.add(transaction.id);
      }
    }

    if (uploads.isNotEmpty) {
      await FirestoreSyncService.instance.uploadTransactions(uploads);
    }
    if (deletes.isNotEmpty) {
      await FirestoreSyncService.instance.deleteTransactions(deletes);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _dbHelper.database;

    // Consulta se a transação estava compartilhada localmente antes de deletar
    final List<Map<String, dynamic>> existing = await db.query(
      'transactions',
      columns: ['isShared'],
      where: 'id = ?',
      whereArgs: [id],
    );
    final bool wasShared = existing.isNotEmpty &&
        (existing.first['isShared'] == 1 || existing.first['isShared'] == true);

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Sincroniza no Firestore apenas se era compartilhada
    if (wasShared) {
      await FirestoreSyncService.instance.deleteTransaction(id);
    }
  }

  @override
  Future<void> deleteTransactionWithScope(Transaction transaction, DeleteScope scope) async {
    final db = await _dbHelper.database;
    final String id = transaction.id;

    if (scope == DeleteScope.onlyThis) {
      await deleteTransaction(id);
      return;
    }

    List<Map<String, dynamic>> maps = [];
    if (scope == DeleteScope.all) {
      if (transaction.groupId != null) {
        maps = await db.query(
          'transactions',
          columns: ['id', 'isShared'],
          where: 'groupId = ?',
          whereArgs: [transaction.groupId],
        );
        await db.delete(
          'transactions',
          where: 'groupId = ?',
          whereArgs: [transaction.groupId],
        );
      } else if (transaction.recurrenceParentId != null) {
        maps = await db.query(
          'transactions',
          columns: ['id', 'isShared'],
          where: 'recurrenceParentId = ?',
          whereArgs: [transaction.recurrenceParentId],
        );
        await db.delete(
          'transactions',
          where: 'recurrenceParentId = ?',
          whereArgs: [transaction.recurrenceParentId],
        );
      } else if (transaction.installmentParentId != null) {
        maps = await db.query(
          'transactions',
          columns: ['id', 'isShared'],
          where: 'installmentParentId = ?',
          whereArgs: [transaction.installmentParentId],
        );
        await db.delete(
          'transactions',
          where: 'installmentParentId = ?',
          whereArgs: [transaction.installmentParentId],
        );
      }
    } else if (scope == DeleteScope.thisAndFuture) {
      if (transaction.groupId != null) {
        maps = await db.query(
          'transactions',
          columns: ['id', 'isShared'],
          where: 'groupId = ? AND date >= ?',
          whereArgs: [transaction.groupId, transaction.date.toIso8601String()],
        );
        await db.delete(
          'transactions',
          where: 'groupId = ? AND date >= ?',
          whereArgs: [transaction.groupId, transaction.date.toIso8601String()],
        );
      } else if (transaction.recurrenceParentId != null) {
        maps = await db.query(
          'transactions',
          columns: ['id', 'isShared'],
          where: 'recurrenceParentId = ? AND date >= ?',
          whereArgs: [transaction.recurrenceParentId, transaction.date.toIso8601String()],
        );
        await db.delete(
          'transactions',
          where: 'recurrenceParentId = ? AND date >= ?',
          whereArgs: [transaction.recurrenceParentId, transaction.date.toIso8601String()],
        );
      } else if (transaction.installmentParentId != null) {
        maps = await db.query(
          'transactions',
          columns: ['id', 'isShared'],
          where: 'installmentParentId = ? AND date >= ?',
          whereArgs: [transaction.installmentParentId, transaction.date.toIso8601String()],
        );
        await db.delete(
          'transactions',
          where: 'installmentParentId = ? AND date >= ?',
          whereArgs: [transaction.installmentParentId, transaction.date.toIso8601String()],
        );
      }
    }

    // Sincroniza a remoção de cada ID no Firestore apenas se era compartilhada (em lote)
    final List<String> idsToDelete = [];
    for (var map in maps) {
      final txId = map['id'] as String;
      final isShared = map['isShared'] == 1 || map['isShared'] == true;
      if (isShared) {
        idsToDelete.add(txId);
      }
    }
    if (idsToDelete.isNotEmpty) {
      await FirestoreSyncService.instance.deleteTransactions(idsToDelete);
    }
  }

  @override
  Future<void> saveTransactionWithScope(Transaction transaction, EditScope scope) async {
    final db = await _dbHelper.database;

    if (scope == EditScope.onlyThis) {
      await saveTransaction(transaction);
      return;
    }

    List<Map<String, dynamic>> maps = [];
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (scope == EditScope.all) {
      if (transaction.groupId != null) {
        whereClause = 'groupId = ?';
        whereArgs = [transaction.groupId];
      } else if (transaction.recurrenceParentId != null) {
        whereClause = 'recurrenceParentId = ?';
        whereArgs = [transaction.recurrenceParentId];
      } else if (transaction.installmentParentId != null) {
        whereClause = 'installmentParentId = ?';
        whereArgs = [transaction.installmentParentId];
      }
    } else if (scope == EditScope.thisAndFuture) {
      if (transaction.groupId != null) {
        whereClause = 'groupId = ? AND date >= ?';
        whereArgs = [transaction.groupId, transaction.date.toIso8601String()];
      } else if (transaction.recurrenceParentId != null) {
        whereClause = 'recurrenceParentId = ? AND date >= ?';
        whereArgs = [transaction.recurrenceParentId, transaction.date.toIso8601String()];
      } else if (transaction.installmentParentId != null) {
        whereClause = 'installmentParentId = ? AND date >= ?';
        whereArgs = [transaction.installmentParentId, transaction.date.toIso8601String()];
      }
    }

    if (whereClause.isNotEmpty) {
      maps = await db.query(
        'transactions',
        where: whereClause,
        whereArgs: whereArgs,
      );
    }

    final List<Transaction> updatedTxs = [];

    for (var map in maps) {
      final existing = TransactionModel.fromMap(map);
      
      String newTitle = transaction.title;
      if (existing.installmentNumber != null && existing.totalInstallments != null) {
        final baseNewTitle = transaction.title.replaceAll(RegExp(r'\s*\(\d+/\d+\)$'), '');
        newTitle = '$baseNewTitle (${existing.installmentNumber}/${existing.totalInstallments})';
      }

      final updated = existing.copyWith(
        title: newTitle,
        amount: transaction.amount,
        category: transaction.category,
        paymentMethod: transaction.paymentMethod,
        description: transaction.description,
        isShared: transaction.isShared,
        familyId: transaction.familyId,
        ownerId: transaction.ownerId,
      );
      updatedTxs.add(updated);
    }

    if (!updatedTxs.any((t) => t.id == transaction.id)) {
      updatedTxs.add(transaction);
    }

    await saveTransactions(updatedTxs);
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
