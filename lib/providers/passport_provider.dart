import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../models/passport_entry.dart';
import '../services/storage_service.dart';
import 'events_provider.dart';

/// Result of a check-in attempt — drives the success/error feedback on the
/// check-in screen.
enum CheckInResult { success, wrongCode, alreadyCheckedIn, eventNotToday }

/// A single earned-or-not badge shown on the profile passport grid.
class PassportBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool earned;

  const PassportBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.earned,
  });
}

/// Owns the "Participation Passport": validated check-ins, derived badges,
/// and the attendance streak. This is the screen's signature feature, so
/// its logic lives in one well-commented place the team can walk through.
///
/// Check-in is the one action that touches three providers' worth of state
/// (passport entries, the event's attendee list, persistence) — keeping
/// that orchestration here means the UI layer stays a thin button handler.
class PassportProvider extends ChangeNotifier {
  final StorageService _storage;
  final EventsProvider _eventsProvider;
  static const _uuid = Uuid();

  List<PassportEntry> _entries = [];

  PassportProvider(this._storage, this._eventsProvider) {
    _entries = _storage.loadPassportEntries();
  }

  List<PassportEntry> get entries => List.unmodifiable(
    List<PassportEntry>.from(_entries)
      ..sort((a, b) => b.checkedInAt.compareTo(a.checkedInAt)),
  );

  int get totalAttended => _entries.length;

  /// Attempts to check [userId] into [event] using the code they typed.
  ///
  /// Validates: the code matches, the event is happening today, and the
  /// user hasn't already checked in. On success this creates a
  /// [PassportEntry], flips the event from "RSVP'd" to "attended" via
  /// [EventsProvider.markAttended], and persists the updated entry list.
  Future<CheckInResult> checkIn({
    required Event event,
    required String userId,
    required String enteredCode,
  }) async {
    if (_entries.any((e) => e.eventId == event.id)) {
      return CheckInResult.alreadyCheckedIn;
    }
    if (!event.isToday) {
      return CheckInResult.eventNotToday;
    }
    if (enteredCode.trim().toUpperCase() != event.checkInCode.toUpperCase()) {
      return CheckInResult.wrongCode;
    }

    final entry = PassportEntry(
      id: _uuid.v4(),
      eventId: event.id,
      eventTitle: event.title,
      category: event.category,
      checkedInAt: DateTime.now(),
    );

    _entries = [..._entries, entry];
    _eventsProvider.markAttended(event.id, userId);
    await _storage.savePassportEntries(_entries);
    notifyListeners();

    return CheckInResult.success;
  }

  // ---------------------------------------------------------------------
  // Streak: longest run of consecutive calendar days containing a check-in
  // ---------------------------------------------------------------------

  int get attendanceStreak {
    if (_entries.isEmpty) return 0;

    final days = _entries
        .map((e) => DateTime(e.checkedInAt.year, e.checkedInAt.month, e.checkedInAt.day))
        .toSet()
        .toList()
      ..sort();

    int longest = 1;
    int current = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        current += 1;
        longest = current > longest ? current : longest;
      } else if (gap > 1) {
        current = 1;
      }
    }
    return longest;
  }

  // ---------------------------------------------------------------------
  // Badges — recomputed from the current entry list every time it's read,
  // so they stay in sync without a separate "award" step to forget about.
  // ---------------------------------------------------------------------

  List<PassportBadge> get badges {
    final distinctCategories = _entries.map((e) => e.category).toSet();
    final hasHackathon = _entries.any((e) => e.category == EventCategory.hackathon);

    return [
      PassportBadge(
        id: 'first_hackathon',
        title: 'First Hackathon',
        description: 'Checked in to a hackathon event.',
        icon: Icons.code_rounded,
        earned: hasHackathon,
      ),
      PassportBadge(
        id: 'five_events',
        title: '5 Events Attended',
        description: 'Checked in to five or more events.',
        icon: Icons.local_activity_outlined,
        earned: totalAttended >= 5,
      ),
      // Interpreted as: attended events spanning at least 3 different
      // categories — a proxy for engaging across multiple campus circles,
      // since the passport tracks event attendance rather than chat activity.
      PassportBadge(
        id: 'three_communities',
        title: 'Active in 3 Communities',
        description: 'Attended events across three or more categories.',
        icon: Icons.diversity_3_outlined,
        earned: distinctCategories.length >= 3,
      ),
      PassportBadge(
        id: 'streak',
        title: 'On a Roll',
        description: 'Checked in on three or more consecutive days.',
        icon: Icons.local_fire_department_outlined,
        earned: attendanceStreak >= 3,
      ),
    ];
  }

  int get earnedBadgeCount => badges.where((b) => b.earned).length;
}
