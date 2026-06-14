import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../../domain/entities/user_profile.dart';

class FamilyService {
  static final FamilyService instance = FamilyService._init();
  final AuthService _authService = AuthService.instance;

  FamilyService._init();

  bool get _isFirebaseAvailable => _authService.isFirebaseAvailable;

  Future<void> createFamily(String name) async {
    if (!_isFirebaseAvailable) {
      throw const FormatException('Firebase indisponível. Conecte-se à internet para criar uma família.');
    }

    final user = await _authService.getCurrentUser();
    if (user == null) throw const FormatException('Usuário não autenticado.');

    final familyRef = FirebaseFirestore.instance.collection('families').doc();
    final familyId = familyRef.id;

    await familyRef.set({
      'name': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'adminId': user.uid,
      'members': [user.uid],
    });

    // Atualiza o perfil do usuário local e no Firestore
    await _authService.updateFamilyId(familyId);
  }

  Future<void> sendInvitation(String toEmail) async {
    if (!_isFirebaseAvailable) {
      throw const FormatException('Firebase indisponível. Conecte-se à internet para enviar convites.');
    }

    final user = await _authService.getCurrentUser();
    if (user == null) throw const FormatException('Usuário não autenticado.');
    if (user.familyId == null) {
      throw const FormatException('Você precisa criar ou fazer parte de uma família para enviar convites.');
    }

    final targetEmail = toEmail.trim().toLowerCase();
    if (targetEmail == user.email.toLowerCase()) {
      throw const FormatException('Você não pode convidar a si mesmo.');
    }

    // Cria o documento de convite no Firestore
    final inviteRef = FirebaseFirestore.instance.collection('invitations').doc();
    await inviteRef.set({
      'fromEmail': user.email,
      'toEmail': targetEmail,
      'familyId': user.familyId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'senderId': user.uid,
    });
  }

  Future<void> acceptInvitation(String invitationId, String familyId) async {
    if (!_isFirebaseAvailable) {
      throw const FormatException('Firebase indisponível. Conecte-se à internet.');
    }

    final user = await _authService.getCurrentUser();
    if (user == null) throw const FormatException('Usuário não autenticado.');

    // 1. Atualizar status do convite
    await FirebaseFirestore.instance
        .collection('invitations')
        .doc(invitationId)
        .update({'status': 'accepted'});

    // 2. Adicionar usuário aos membros da família
    await FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .update({
      'members': FieldValue.arrayUnion([user.uid])
    });

    // 3. Atualizar o perfil do usuário com o novo familyId
    await _authService.updateFamilyId(familyId);
  }

  Future<void> declineInvitation(String invitationId) async {
    if (!_isFirebaseAvailable) {
      throw const FormatException('Firebase indisponível. Conecte-se à internet.');
    }

    await FirebaseFirestore.instance
        .collection('invitations')
        .doc(invitationId)
        .update({'status': 'declined'});
  }

  Future<void> leaveFamily() async {
    if (!_isFirebaseAvailable) {
      throw const FormatException('Firebase indisponível. Conecte-se à internet para sair da família.');
    }

    final user = await _authService.getCurrentUser();
    if (user == null) throw const FormatException('Usuário não autenticado.');
    if (user.familyId == null) return;

    final familyId = user.familyId!;

    // 1. Remover da lista de membros da família
    await FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .update({
      'members': FieldValue.arrayRemove([user.uid])
    });

    // 2. Limpar o familyId do usuário localmente e no Firestore
    await _authService.updateFamilyId(null);
  }

  Stream<List<Map<String, dynamic>>> getPendingInvitationsStream(String email) {
    if (!_isFirebaseAvailable) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('invitations')
        .where('toEmail', isEqualTo: email.trim().toLowerCase())
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<UserProfile>> getFamilyMembersStream(String familyId) {
    if (!_isFirebaseAvailable) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserProfile(
          uid: doc.id,
          username: data['username'] as String? ?? 'Sem Nome',
          email: data['email'] as String? ?? '',
          familyId: familyId,
        );
      }).toList();
    });
  }

  Stream<Map<String, dynamic>?> getFamilyInfoStream(String familyId) {
    if (!_isFirebaseAvailable) {
      return Stream.value(null);
    }

    return FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
}
