import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/passport_entry.dart';
import '../models/user.dart';

/// Thin wrapper around shared_preferences.
///
/// Every read/write that touches local persistence goes through here so the
/// rest of the app (providers) never has to know about JSON encoding or
/// preference keys directly. This isolation is what makes the "offline
/// persistence" requirement easy to explain and test.
class StorageService {
  static const _keyCurrentUser = 'anza.currentUser';
  static const _keyRsvpIds = 'anza.rsvpEventIds';
  static const _keyPassportEntries = 'anza.passportEntries';
  static const _keyOnboardingComplete = 'anza.onboardingComplete';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ---------------------------------------------------------------------
  // Current user (the signed-in account)
  // ---------------------------------------------------------------------

  Future<void> saveCurrentUser(AppUser user) async {
    await _prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
  }

  AppUser? loadCurrentUser() {
    final raw = _prefs.getString(_keyCurrentUser);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearCurrentUser() async {
    await _prefs.remove(_keyCurrentUser);
  }

  // ---------------------------------------------------------------------
  // RSVP'd event ids for the current user
  // ---------------------------------------------------------------------

  Future<void> saveRsvpEventIds(List<String> eventIds) async {
    await _prefs.setStringList(_keyRsvpIds, eventIds);
  }

  List<String> loadRsvpEventIds() {
    return _prefs.getStringList(_keyRsvpIds) ?? const [];
  }

  // ---------------------------------------------------------------------
  // Participation Passport entries
  // ---------------------------------------------------------------------

  Future<void> savePassportEntries(List<PassportEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyPassportEntries, encoded);
  }

  List<PassportEntry> loadPassportEntries() {
    final raw = _prefs.getString(_keyPassportEntries);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List;
    return list
        .map((item) => PassportEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Onboarding flag — so returning users skip the intro screen
  // ---------------------------------------------------------------------

  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_keyOnboardingComplete, complete);
  }

  bool get hasCompletedOnboarding => _prefs.getBool(_keyOnboardingComplete) ?? false;
}
