import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/user_profile.dart';
import 'firestore_sync_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AuthService._init();

  bool get isFirebaseAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserProfile?> getCurrentUser() async {
    if (isFirebaseAvailable) {
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(fbUser.uid)
              .get();
          if (doc.exists) {
            final data = doc.data()!;
            return UserProfile(
              uid: fbUser.uid,
              username: data['username'] as String? ?? 'Sem Nome',
              email: fbUser.email ?? '',
              familyId: data['familyId'] as String?,
            );
          }
        } catch (e) {
          debugPrint('Erro ao obter perfil do Firebase: $e. Usando cache local.');
        }
      }
    }

    // Fallback: carregar sessão local do SQLite
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('current_session');
    if (maps.isNotEmpty) {
      final map = maps.first;
      return UserProfile(
        uid: map['uid'] as String,
        username: map['username'] as String,
        email: map['email'] as String,
        familyId: map['familyId'] as String?,
      );
    }
    return null;
  }

  Future<UserProfile> signUp(
    String username,
    String email,
    String password,
  ) async {
    if (isFirebaseAvailable) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final uid = credential.user!.uid;

        // Salvar no Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username': username,
          'email': email,
          'familyId': null,
        });

        final profile = UserProfile(
          uid: uid,
          username: username,
          email: email,
        );

        // Atualizar cache local
        await _saveLocalSession(profile);

        // Iniciar Sincronização
        await FirestoreSyncService.instance.startSync();

        return profile;
      } catch (e) {
        debugPrint('Erro Firebase SignUp: $e. Tentando cadastro local.');
        rethrow;
      }
    }

    // Cadastro Local
    final db = await _dbHelper.database;
    final uid = 'local_${DateTime.now().millisecondsSinceEpoch}';

    // Salvar usuário local
    await db.insert('users', {
      'uid': uid,
      'username': username,
      'email': email,
      'password': password,
      'familyId': null,
    });

    final profile = UserProfile(
      uid: uid,
      username: username,
      email: email,
    );

    await _saveLocalSession(profile);
    return profile;
  }

  Future<UserProfile> signIn(String email, String password) async {
    if (isFirebaseAvailable) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final uid = credential.user!.uid;

        // Buscar dados do Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        
        String username = 'Usuário';
        String? familyId;
        if (doc.exists) {
          final data = doc.data()!;
          username = data['username'] as String? ?? 'Usuário';
          familyId = data['familyId'] as String?;
        }

        final profile = UserProfile(
          uid: uid,
          username: username,
          email: email,
          familyId: familyId,
        );

        await _saveLocalSession(profile);

        // Iniciar Sincronização
        await FirestoreSyncService.instance.startSync();

        return profile;
      } catch (e) {
        debugPrint('Erro Firebase SignIn: $e. Tentando login local.');
        rethrow;
      }
    }

    // Login Local
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isEmpty) {
      throw const FormatException('E-mail ou senha incorretos.');
    }

    final userMap = maps.first;
    final profile = UserProfile(
      uid: userMap['uid'] as String,
      username: userMap['username'] as String,
      email: userMap['email'] as String,
      familyId: userMap['familyId'] as String?,
    );

    await _saveLocalSession(profile);
    return profile;
  }

  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Erro ao desconectar Firebase: $e');
      }
    }

    // Parar Sincronização e limpar transações locais da família
    FirestoreSyncService.instance.stopSync();
    await FirestoreSyncService.instance.clearOtherFamilyTransactions(null);

    // Limpar sessão local
    final db = await _dbHelper.database;
    await db.delete('current_session');
  }

  Future<void> _saveLocalSession(UserProfile profile) async {
    final db = await _dbHelper.database;
    await db.delete('current_session'); // limpa qualquer sessão anterior
    await db.insert('current_session', {
      'uid': profile.uid,
      'username': profile.username,
      'email': profile.email,
      'familyId': profile.familyId,
    });
  }

  // Método auxiliar para atualizar o familyId de um usuário (após aceitar convite)
  Future<void> updateFamilyId(String? familyId) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(familyId: familyId);
      await _saveLocalSession(updatedUser);

      // Limpa dados locais da família anterior
      await FirestoreSyncService.instance.clearOtherFamilyTransactions(familyId);

      if (isFirebaseAvailable) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'username': user.username,
                'email': user.email,
                'familyId': familyId,
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Erro ao atualizar família no Firebase: $e');
        }
      }

      // Reinicia a sincronização com a nova família
      await FirestoreSyncService.instance.startSync();
    }
  }
}
