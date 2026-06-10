import 'package:flutter/material.dart';

import '../data/seed_data.dart';
import '../models/event.dart';
import '../services/saved_events_database.dart';
import '../services/storage_service.dart';

/// Holds the event catalogue plus feed-filtering state, and owns RSVP logic.
///
/// Events themselves are seed data recreated on every launch; what survives
/// a restart is *which events the current user RSVP'd to*, persisted as a
/// flat list of event ids and re-applied on top of the fresh seed list via
/// [hydrateRsvpsForUser].
class EventsProvider extends ChangeNotifier {
  final StorageService _storage;
  final SavedEventsDatabase _savedEventsDb = SavedEventsDatabase();

  List<Event> _events = SeedData.events();
  EventCategory? _categoryFilter;
  Campus? _campusFilter;
  String _searchQuery = '';
  Set<String> _savedEventIds = {};

  EventsProvider(this._storage);

  List<Event> get events => List.unmodifiable(_events);
  EventCategory? get categoryFilter => _categoryFilter;
  Campus? get campusFilter => _campusFilter;
  String get searchQuery => _searchQuery;

  /// Saved-for-later events, most recently saved first.
  List<Event> get savedEvents => _events.where((e) => _savedEventIds.contains(e.id)).toList();

  bool isSaved(String eventId) => _savedEventIds.contains(eventId);

  /// Loads previously saved event ids from the on-device SQLite database.
  /// Call once after sign-in, alongside [hydrateRsvpsForUser].
  Future<void> loadSavedEvents() async {
    _savedEventIds = await _savedEventsDb.loadSavedEventIds();
    notifyListeners();
  }

  /// Toggles whether [eventId] is bookmarked, persisting the change to
  /// SQLite. Returns true if the event is now saved.
  Future<bool> toggleSaved(String eventId) async {
    final isCurrentlySaved = _savedEventIds.contains(eventId);
    if (isCurrentlySaved) {
      _savedEventIds = {..._savedEventIds}..remove(eventId);
      await _savedEventsDb.unsave(eventId);
    } else {
      _savedEventIds = {..._savedEventIds, eventId};
      await _savedEventsDb.save(eventId);
    }
    notifyListeners();
    return !isCurrentlySaved;
  }

  /// Events matching the selected category chip, campus chip, and search
  /// field. Recomputed on read so the feed always reflects the latest
  /// filter state.
  List<Event> get filteredEvents {
    return _events.where((event) {
      final matchesCategory = _categoryFilter == null || event.category == _categoryFilter;
      final matchesCampus = _campusFilter == null || event.campus == _campusFilter;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.posterName.toLowerCase().contains(query);
      return matchesCategory && matchesCampus && matchesSearch;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void setCategoryFilter(EventCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setCampusFilter(Campus? campus) {
    _campusFilter = campus;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _categoryFilter = null;
    _campusFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  Event? eventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Events the given user has RSVP'd to, soonest first.
  List<Event> myRsvps(String userId) {
    return _events.where((e) => e.isRsvpedBy(userId)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Adds or removes [userId] from an event's RSVP list, persists the
  /// user's full RSVP set, and notifies listeners so the feed and
  /// "My Events" screen update live. Returns true if the user is now
  /// RSVP'd (useful for choosing snackbar copy).
  Future<bool> toggleRsvp(String eventId, String userId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final event = _events[index];
    final isCurrentlyRsvped = event.isRsvpedBy(userId);
    final updatedIds = List<String>.from(event.rsvpUserIds);
    if (isCurrentlyRsvped) {
      updatedIds.remove(userId);
    } else {
      updatedIds.add(userId);
    }

    _events[index] = event.copyWith(rsvpUserIds: updatedIds);
    notifyListeners();

    await _persistRsvpsFor(userId);
    return !isCurrentlyRsvped;
  }

  /// Records a successful check-in by moving the user from "RSVP'd" to
  /// "attended" on the given event. Called by [PassportProvider] so all
  /// check-in side effects stay in one place.
  void markAttended(String eventId, String userId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];
    if (event.isAttendedBy(userId)) return;

    _events[index] = event.copyWith(
      attendeeUserIds: [...event.attendeeUserIds, userId],
    );
    notifyListeners();
  }

  Future<void> _persistRsvpsFor(String userId) async {
    final ids = _events.where((e) => e.isRsvpedBy(userId)).map((e) => e.id).toList();
    await _storage.saveRsvpEventIds(ids);
  }

  /// Re-applies the signed-in user's persisted RSVPs onto the freshly
  /// seeded events. Call this once, right after a user signs in.
  void hydrateRsvpsForUser(String userId) {
    final persistedIds = _storage.loadRsvpEventIds().toSet();
    if (persistedIds.isEmpty) return;

    _events = _events.map((event) {
      if (persistedIds.contains(event.id) && !event.isRsvpedBy(userId)) {
        return event.copyWith(rsvpUserIds: [...event.rsvpUserIds, userId]);
      }
      return event;
    }).toList();
    notifyListeners();
  }

  /// Prepends a newly created event to the feed (used by Create Post).
  void addEvent(Event event) {
    _events = [event, ..._events];
    notifyListeners();
  }
}
