import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/database/database_helper.dart';
import 'auth_service.dart';

class UserCache {
  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _pending = {};

  static Future<String> getUsername(String uid) {
    if (_cache.containsKey(uid)) {
      return Future.value(_cache[uid]!);
    }
    if (_pending.containsKey(uid)) {
      return _pending[uid]!;
    }

    final future = _fetchUsername(uid);
    _pending[uid] = future;
    
    future.then((name) {
      _cache[uid] = name;
      _pending.remove(uid);
    }).catchError((_) {
      _pending.remove(uid);
    });

    return future;
  }

  static Future<String> _fetchUsername(String uid) async {
    // Se o UID for o do próprio usuário logado, retorna o nome dele
    try {
      final currentUser = await AuthService.instance.getCurrentUser();
      if (currentUser != null && currentUser.uid == uid) {
        return currentUser.username;
      }
    } catch (_) {}

    // 1. Tenta buscar no SQLite (se existir na tabela users)
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'users',
        columns: ['username'],
        where: 'uid = ?',
        whereArgs: [uid],
      );
      if (maps.isNotEmpty) {
        return maps.first['username'] as String;
      }
    } catch (_) {}

    // 2. Tenta buscar no Firestore se o Firebase estiver disponível
    if (AuthService.instance.isFirebaseAvailable) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          return data?['username'] as String? ?? 'Membro';
        }
      } catch (_) {}
    }

    return 'Membro';
  }
}
