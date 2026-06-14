import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';
import 'auth_service.dart';

class FirestoreSyncService {
  static final FirestoreSyncService instance = FirestoreSyncService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService.instance;

  StreamSubscription<QuerySnapshot>? _transactionSubscription;
  String? _activeFamilyId;

  FirestoreSyncService._init();

  bool get _isFirebaseAvailable => _authService.isFirebaseAvailable;

  /// Inicia a sincronização com base no estado atual do usuário e sua família.
  /// Deve ser chamado no boot do app (após carregar o usuário) e após login/logout/mudança de família.
  Future<void> startSync() async {
    if (!_isFirebaseAvailable) {
      debugPrint('Sync: Firebase indisponível. Rodando em modo totalmente offline.');
      _cancelSubscription();
      return;
    }

    final user = await _authService.getCurrentUser();
    if (user == null) {
      debugPrint('Sync: Nenhum usuário logado. Cancelando sincronização.');
      _cancelSubscription();
      return;
    }

    final familyId = user.familyId;
    if (familyId == null) {
      debugPrint('Sync: Usuário não pertence a nenhuma família. Cancelando sincronização.');
      _cancelSubscription();
      return;
    }

    if (_activeFamilyId == familyId) {
      // Já está sincronizando a mesma família
      return;
    }

    _cancelSubscription();
    _activeFamilyId = familyId;
    debugPrint('Sync: Iniciando sincronização em tempo real para a família: $familyId');

    // Subscreve para ouvir alterações da família no Firestore
    _transactionSubscription = FirebaseFirestore.instance
        .collection('transactions')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .listen(
      (snapshot) async {
        final db = await _dbHelper.database;
        await db.transaction((txn) async {
          for (var change in snapshot.docChanges) {
            final doc = change.doc;
            final data = doc.data();

            if (data == null) continue;

            final transactionId = doc.id;

            if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
              // Converte dados do Firestore para mapeamento de banco local
              // Garante que o ID da transação seja o ID do documento
              final map = Map<String, dynamic>.from(data);
              map['id'] = transactionId;

              // Como o SQLite armazena booleanos como 0/1, convertemos aqui se necessário
              final transactionModel = TransactionModel.fromMap(map);

              await txn.insert(
                'transactions',
                transactionModel.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              debugPrint('Sync: Transação compartilhada salva/atualizada localmente: $transactionId');
            } else if (change.type == DocumentChangeType.removed) {
              // Se foi deletada no Firestore e o dono é outro usuário, deleta do SQLite local
              final ownerId = data['ownerId'] as String?;
              if (ownerId != user.uid) {
                await txn.delete(
                  'transactions',
                  where: 'id = ?',
                  whereArgs: [transactionId],
                );
                debugPrint('Sync: Transação compartilhada removida localmente: $transactionId');
              }
            }
          }
        });
      },
      onError: (error) {
        debugPrint('Sync: Erro no stream do Firestore: $error');
      },
    );
  }

  /// Cancela a subscrição ativa
  void _cancelSubscription() {
    _transactionSubscription?.cancel();
    _transactionSubscription = null;
    _activeFamilyId = null;
  }

  /// Desconecta o sync ao fazer logout
  void stopSync() {
    _cancelSubscription();
  }

  /// Faz o upload de uma transação para o Firestore se for compartilhada
  Future<void> uploadTransaction(Transaction transaction) async {
    if (!_isFirebaseAvailable) return;

    final user = await _authService.getCurrentUser();
    if (user == null || user.familyId == null || !transaction.isShared) return;

    // Garante que a transação tenha o ownerId e o familyId corretos
    final updatedTx = transaction.copyWith(
      ownerId: transaction.ownerId ?? user.uid,
      familyId: transaction.familyId ?? user.familyId,
    );

    final model = TransactionModel.fromEntity(updatedTx);
    final map = model.toMap();

    // No Firestore, preferimos armazenar booleanos de verdade em vez de 0/1
    map['isPending'] = model.isPending;
    map['isPaid'] = model.isPaid;
    map['isShared'] = model.isShared;

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(model.id)
        .set(map);

    debugPrint('Sync: Upload concluído para transação ${model.id}');
  }

  /// Deleta a transação no Firestore se ela estiver lá
  Future<void> deleteTransaction(String transactionId) async {
    if (!_isFirebaseAvailable) return;

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId)
          .delete();
      debugPrint('Sync: Deleção concluída no Firestore para transação $transactionId');
    } catch (e) {
      debugPrint('Sync: Erro ao deletar no Firestore (pode não existir na nuvem): $e');
    }
  }

  /// Limpa os dados compartilhados locais que pertencem a outra família
  Future<void> clearOtherFamilyTransactions(String? currentFamilyId) async {
    final db = await _dbHelper.database;
    if (currentFamilyId == null) {
      // Se saiu de qualquer família, remove todas as transações compartilhadas
      await db.delete(
        'transactions',
        where: 'isShared = 1',
      );
      debugPrint('Sync: Limpou todas as transações compartilhadas locais.');
    } else {
      // Se trocou de família, remove as transações da família anterior
      await db.delete(
        'transactions',
        where: 'isShared = 1 AND familyId != ?',
        whereArgs: [currentFamilyId],
      );
      debugPrint('Sync: Limpou transações de outras famílias.');
    }
  }
}
