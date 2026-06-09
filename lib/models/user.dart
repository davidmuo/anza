import 'package:flutter/material.dart';

/// The two roles in Anza's trust model.
///
/// Only [verified] users (club leaders, academic teams, founders) can post
/// events — this is the core "verified hub" concept the app demonstrates.
enum UserRole { student, verified }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// Name of the organization this user is verified to post on behalf of,
  /// e.g. "Robotics Club". Null for ordinary students.
  final String? verifiedOrg;

  final List<String> interests;

  /// Background color used for the user's avatar initials.
  final Color avatarColor;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.verifiedOrg,
    this.interests = const [],
    this.avatarColor = Colors.blue,
  });

  bool get isVerified => role == UserRole.verified;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? verifiedOrg,
    List<String>? interests,
    Color? avatarColor,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      verifiedOrg: verifiedOrg ?? this.verifiedOrg,
      interests: interests ?? this.interests,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'verifiedOrg': verifiedOrg,
        'interests': interests,
        'avatarColor': avatarColor.toARGB32(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.values.byName(json['role'] as String),
        verifiedOrg: json['verifiedOrg'] as String?,
        interests: List<String>.from(json['interests'] as List? ?? const []),
        avatarColor: Color(json['avatarColor'] as int? ?? 0xFF1E4D3B),
      );
}
