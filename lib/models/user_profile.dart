import 'dart:convert';

class UserProfile {
  final String  id;
  final String  fullName;
  final String  email;
  final String? photoUrl;
  final String  authProvider; // 'email' | 'google'
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.authProvider,
    required this.createdAt,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2 && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toJson() => {
    'id':           id,
    'fullName':     fullName,
    'email':        email,
    'photoUrl':     photoUrl,
    'authProvider': authProvider,
    'createdAt':    createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id:           json['id']           as String,
    fullName:     json['fullName']     as String,
    email:        json['email']        as String,
    photoUrl:     json['photoUrl']     as String?,
    authProvider: json['authProvider'] as String? ?? 'email',
    createdAt:    DateTime.parse(json['createdAt'] as String),
  );

  static UserProfile? tryFromJsonString(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return UserProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
