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

    bool reconciledFromServer = false;
    bool reconciledFromCache = false;

    // Subscreve para ouvir alterações da família no Firestore
    _transactionSubscription = FirebaseFirestore.instance
        .collection('transactions')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .listen(
      (snapshot) async {
        final db = await _dbHelper.database;
        final isFromServer = !snapshot.metadata.isFromCache;

        // Executa a reconciliação uma única vez por fonte (cache/servidor) para alinhar dados offline/deletados
        final needReconcile = (isFromServer && !reconciledFromServer) || (!isFromServer && !reconciledFromCache);

        if (needReconcile) {
          if (isFromServer) {
            reconciledFromServer = true;
          } else {
            reconciledFromCache = true;
          }

          debugPrint('Sync: Executando reconciliação inicial (${isFromServer ? "Servidor" : "Cache"})...');

          // 1. Coleta todos os IDs de transações atualmente no Firestore para esta família
          final firestoreIds = snapshot.docs.map((doc) => doc.id).toSet();

          // 2. Busca todas as transações compartilhadas locais desta família no SQLite
          final List<Map<String, dynamic>> localShared = await db.query(
            'transactions',
            columns: ['id', 'ownerId'],
            where: 'isShared = 1 AND familyId = ?',
            whereArgs: [familyId],
          );

          final List<String> localIdsToDelete = [];
          final List<Transaction> localTransactionsToUpload = [];

          for (var row in localShared) {
            final id = row['id'] as String;
            final ownerId = row['ownerId'] as String?;

            if (!firestoreIds.contains(id)) {
              if (ownerId != null && ownerId != user.uid) {
                // Outro usuário deletou no Firestore enquanto estávamos offline
                localIdsToDelete.add(id);
              } else {
                // Transação nossa (ou órfã) criada offline e que ainda não subiu para o Firestore
                final List<Map<String, dynamic>> fullTxMap = await db.query(
                  'transactions',
                  where: 'id = ?',
                  whereArgs: [id],
                );
                if (fullTxMap.isNotEmpty) {
                  localTransactionsToUpload.add(TransactionModel.fromMap(fullTxMap.first));
                }
              }
            }
          }

          // Executa as deleções locais em SQLite
          if (localIdsToDelete.isNotEmpty) {
            await db.transaction((txn) async {
              final batch = txn.batch();
              for (var id in localIdsToDelete) {
                batch.delete(
                  'transactions',
                  where: 'id = ?',
                  whereArgs: [id],
                );
              }
              await batch.commit(noResult: true);
            });
            debugPrint('Sync: Reconciliação deletou ${localIdsToDelete.length} transações removidas na nuvem.');
          }

          // Executa upload das transações locais pendentes
          if (localTransactionsToUpload.isNotEmpty) {
            await uploadTransactions(localTransactionsToUpload);
            debugPrint('Sync: Reconciliação enviou ${localTransactionsToUpload.length} transações locais ao Firestore.');
          }
        }

        // 3. Processamento em tempo real das alterações do snapshot (added, modified, removed)
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

              // Evita escritas e prints redundantes se a transação já estiver salva localmente idêntica
              final List<Map<String, dynamic>> local = await txn.query(
                'transactions',
                where: 'id = ?',
                whereArgs: [transactionId],
              );

              bool needsUpdate = true;
              if (local.isNotEmpty) {
                final localModel = TransactionModel.fromMap(local.first);
                if (localModel == transactionModel) {
                  needsUpdate = false;
                }
              }

              if (needsUpdate) {
                await txn.insert(
                  'transactions',
                  transactionModel.toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                debugPrint('Sync: Transação compartilhada salva/atualizada localmente: $transactionId');
              }
            } else if (change.type == DocumentChangeType.removed) {
              // Se foi deletada no Firestore, removemos do SQLite local apenas se a transação local ainda estiver como compartilhada.
              // Isso evita deletar transações locais que foram descompartilhadas pelo próprio dono (que salva com isShared = 0 localmente).
              final List<Map<String, dynamic>> localTx = await txn.query(
                'transactions',
                columns: ['isShared'],
                where: 'id = ?',
                whereArgs: [transactionId],
              );
              if (localTx.isNotEmpty) {
                final isShared = localTx.first['isShared'] == 1 || localTx.first['isShared'] == true;
                if (isShared) {
                  await txn.delete(
                    'transactions',
                    where: 'id = ?',
                    whereArgs: [transactionId],
                  );
                  debugPrint('Sync: Transação compartilhada removida localmente por exclusão remota: $transactionId');
                }
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

  /// Faz o upload de várias transações para o Firestore em lote
  Future<void> uploadTransactions(List<Transaction> transactions) async {
    if (!_isFirebaseAvailable) return;
    if (transactions.isEmpty) return;

    final user = await _authService.getCurrentUser();
    if (user == null || user.familyId == null) return;

    // Apenas transações compartilhadas são enviadas
    final sharedTxs = transactions.where((tx) => tx.isShared).toList();
    if (sharedTxs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var transaction in sharedTxs) {
      final updatedTx = transaction.copyWith(
        ownerId: transaction.ownerId ?? user.uid,
        familyId: transaction.familyId ?? user.familyId,
      );

      final model = TransactionModel.fromEntity(updatedTx);
      final map = model.toMap();

      map['isPending'] = model.isPending;
      map['isPaid'] = model.isPaid;
      map['isShared'] = model.isShared;

      final docRef = FirebaseFirestore.instance.collection('transactions').doc(model.id);
      batch.set(docRef, map);
    }

    await batch.commit();
    debugPrint('Sync: Upload em lote concluído para ${sharedTxs.length} transações.');
  }

  /// Deleta várias transações no Firestore em lote
  Future<void> deleteTransactions(List<String> transactionIds) async {
    if (!_isFirebaseAvailable) return;
    if (transactionIds.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var id in transactionIds) {
        final docRef = FirebaseFirestore.instance.collection('transactions').doc(id);
        batch.delete(docRef);
      }
      await batch.commit();
      debugPrint('Sync: Deleção em lote concluída no Firestore para ${transactionIds.length} transações.');
    } catch (e) {
      debugPrint('Sync: Erro ao deletar em lote no Firestore: $e');
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
