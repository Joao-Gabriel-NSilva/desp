import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String username;
  final String email;
  final String? familyId;

  const UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    this.familyId,
  });

  UserProfile copyWith({
    String? uid,
    String? username,
    String? email,
    String? familyId,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      familyId: familyId ?? this.familyId,
    );
  }

  @override
  List<Object?> get props => [uid, username, email, familyId];
}
