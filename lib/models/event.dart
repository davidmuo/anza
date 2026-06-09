import 'package:flutter/material.dart';

/// Categories an event can belong to. Drives both the filter chips on the
/// feed and the badge/streak logic in [PassportProvider].
enum EventCategory { event, hackathon, internship, workshop, leadership, startup }

extension EventCategoryLabel on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.event:
        return 'Event';
      case EventCategory.hackathon:
        return 'Hackathon';
      case EventCategory.internship:
        return 'Internship';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.leadership:
        return 'Leadership';
      case EventCategory.startup:
        return 'Startup';
    }
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final String posterId;
  final String posterName;

  /// Non-null when the poster is a verified org — used to show the badge
  /// on event cards and detail pages.
  final String? posterVerifiedOrg;

  final DateTime dateTime;
  final String location;

  /// Placeholder banner color (we don't ship real images — keeps the app
  /// fully offline and lightweight).
  final Color imageColor;

  /// 6-character code organizers share at the door; entered by attendees
  /// on the check-in screen.
  final String checkInCode;

  final List<String> rsvpUserIds;
  final List<String> attendeeUserIds;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.posterId,
    required this.posterName,
    this.posterVerifiedOrg,
    required this.dateTime,
    required this.location,
    required this.imageColor,
    required this.checkInCode,
    this.rsvpUserIds = const [],
    this.attendeeUserIds = const [],
  });

  bool get postedByVerifiedOrg => posterVerifiedOrg != null;

  bool isRsvpedBy(String userId) => rsvpUserIds.contains(userId);

  bool isAttendedBy(String userId) => attendeeUserIds.contains(userId);

  /// True when the event's date falls on today's calendar day — used to
  /// gate the "Check in" action so it only appears on event day.
  bool get isToday {
    final now = DateTime.now();
    return now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
  }

  Event copyWith({
    List<String>? rsvpUserIds,
    List<String>? attendeeUserIds,
  }) {
    return Event(
      id: id,
      title: title,
      description: description,
      category: category,
      posterId: posterId,
      posterName: posterName,
      posterVerifiedOrg: posterVerifiedOrg,
      dateTime: dateTime,
      location: location,
      imageColor: imageColor,
      checkInCode: checkInCode,
      rsvpUserIds: rsvpUserIds ?? this.rsvpUserIds,
      attendeeUserIds: attendeeUserIds ?? this.attendeeUserIds,
    );
  }
}
