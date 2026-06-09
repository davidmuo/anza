import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/seed_data.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

/// Result of a sign-in/sign-up attempt — lets the UI show a precise inline
/// error instead of a generic "something went wrong".
enum AuthResult { success, invalidEmail, emptyName, userNotFound }

/// Mock authentication: there is no backend, so "signing in" means matching
/// the entered email against [SeedData.users], and "signing up" means
/// creating a lightweight local student account.
///
/// Holds the single source of truth for "who is using the app right now",
/// which other providers (events, passport) key their per-user state off of.
class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  static const _uuid = Uuid();
  static final RegExp _emailPattern = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');

  AppUser? _currentUser;

  AuthProvider(this._storage) {
    _currentUser = _storage.loadCurrentUser();
  }

  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Attempts to sign in by matching [email] (case-insensitive) against the
  /// seeded roster. Returns [AuthResult.userNotFound] if nobody matches —
  /// the UI then offers to sign up instead.
  Future<AuthResult> signIn(String email) async {
    final trimmed = email.trim();
    if (!_emailPattern.hasMatch(trimmed)) return AuthResult.invalidEmail;

    final match = SeedData.users.where(
      (u) => u.email.toLowerCase() == trimmed.toLowerCase(),
    );
    if (match.isEmpty) return AuthResult.userNotFound;

    await _setCurrentUser(match.first);
    return AuthResult.success;
  }

  /// Creates a brand-new local student account. [interests] come from the
  /// onboarding chip picker.
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required List<String> interests,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    if (trimmedName.isEmpty) return AuthResult.emptyName;
    if (!_emailPattern.hasMatch(trimmedEmail)) return AuthResult.invalidEmail;

    final user = AppUser(
      id: _uuid.v4(),
      name: trimmedName,
      email: trimmedEmail,
      role: UserRole.student,
      interests: interests,
      avatarColor: AppColors.accentPalette[trimmedName.length % AppColors.accentPalette.length],
    );

    await _setCurrentUser(user);
    return AuthResult.success;
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _storage.clearCurrentUser();
    notifyListeners();
  }

  Future<void> _setCurrentUser(AppUser user) async {
    _currentUser = user;
    await _storage.saveCurrentUser(user);
    notifyListeners();
  }
}
