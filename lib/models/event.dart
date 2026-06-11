import 'package:flutter/material.dart';

/// Categories an event can belong to. Drives both the filter chips on the
/// feed and the badge/streak logic in [PassportProvider].
enum EventCategory {
  event,
  hackathon,
  internship,
  workshop,
  leadership,
  startup,
}

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

/// Whether an event happens on campus or remotely over a video call.
enum EventMode { inPerson, online }

extension EventModeLabel on EventMode {
  String get label {
    switch (this) {
      case EventMode.inPerson:
        return 'In-person';
      case EventMode.online:
        return 'Online';
    }
  }
}

/// Moderation state for a posted event.
///
/// Verified posters publish straight to [approved]. Everyone else can still
/// post, but their event starts as [pending] — visible only to them (on
/// their "Posted" tab) until a verified moderator approves it.
enum EventStatus { approved, pending }

/// ALU's two undergraduate campuses. Drives the campus filter on the feed
/// so students only see what's relevant to where they study.
enum Campus { kigali, mauritius }

extension CampusLabel on Campus {
  String get label {
    switch (this) {
      case Campus.kigali:
        return 'Kigali';
      case Campus.mauritius:
        return 'Mauritius';
    }
  }

  /// Approximate campus coordinates, used as the center point for each
  /// event's map (see [Event.latitude]/[Event.longitude]).
  ({double lat, double lng}) get center {
    switch (this) {
      case Campus.kigali:
        return (lat: -1.9357, lng: 30.1336);
      case Campus.mauritius:
        return (lat: -20.1175, lng: 57.5716);
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
  final Campus campus;

  /// Whether this event happens on campus or over a video call. Online
  /// events skip the map preview and show [meetingLink] instead.
  final EventMode mode;

  /// Zoom/Google Meet link for [EventMode.online] events.
  final String? meetingLink;

  /// Organizer-provided Google Maps link, used in place of the
  /// auto-generated [mapsUrl] when set.
  final String? mapLink;

  /// Placeholder banner color — shown immediately and kept as a fallback
  /// behind [imageUrl] so banners never look broken offline.
  final Color imageColor;

  /// Local file path for a photo the poster attached when creating this
  /// event, if any. Takes priority over [imageUrl] in [PhotoBanner].
  final String? imagePath;

  /// Deterministic photo for this event's banner. Backed by a free
  /// placeholder photo service (no API key required); [imageColor] is the
  /// fallback if the device has no network.
  String get imageUrl => 'https://picsum.photos/seed/anza-event-$id/900/600';

  /// Deterministic offset (roughly +/- 600m) so each event lands at a
  /// distinct point near its campus center without needing hand-picked
  /// coordinates for every entry.
  double _offset(int salt) {
    final hash = '$id-$salt'.hashCode;
    return ((hash % 1200) - 600) / 100000;
  }

  double get latitude => campus.center.lat + _offset(0);

  double get longitude => campus.center.lng + _offset(1);

  /// Static map preview for the event detail screen — no API key required.
  String get mapImageUrl =>
      'https://staticmap.openstreetmap.de/staticmap.php'
      '?center=$latitude,$longitude&zoom=15&size=640x320&maptype=mapnik'
      '&markers=$latitude,$longitude,red-pushpin';

  /// Deep link used by the "Open in Maps" action on the detail screen —
  /// the organizer's [mapLink] if they provided one, otherwise a
  /// generated link from the event's approximate coordinates.
  String get mapsUrl =>
      (mapLink != null && mapLink!.isNotEmpty)
          ? mapLink!
          : 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  bool get isOnline => mode == EventMode.online;

  /// QR/share payload that opens this event directly when scanned in-app.
  String get shareLink => 'anza://event?id=$id';

  /// Short code shown alongside the share QR as a manual-entry fallback —
  /// typed into the scanner's "Enter code" sheet to open this event.
  String get shareCode => id.toUpperCase();

  /// QR payload an organizer displays at the door — scanning it both
  /// identifies the event and carries the check-in code.
  String get checkInLink => 'anza://checkin?event=$id&code=$checkInCode';

  /// 6-character code organizers share at the door; entered by attendees
  /// on the check-in screen.
  final String checkInCode;

  final List<String> rsvpUserIds;
  final List<String> attendeeUserIds;

  /// Moderation state — see [EventStatus]. Defaults to [EventStatus.approved]
  /// so seed data and verified posters' events show up immediately.
  final EventStatus status;

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
    required this.campus,
    this.mode = EventMode.inPerson,
    this.meetingLink,
    this.mapLink,
    required this.imageColor,
    this.imagePath,
    required this.checkInCode,
    this.rsvpUserIds = const [],
    this.attendeeUserIds = const [],
    this.status = EventStatus.approved,
  });

  bool get postedByVerifiedOrg => posterVerifiedOrg != null;

  bool isRsvpedBy(String userId) => rsvpUserIds.contains(userId);

  bool isAttendedBy(String userId) => attendeeUserIds.contains(userId);

  /// True when the event's date falls on today's calendar day — used to
  /// gate the "Check in" action so it only appears on event day.
  bool get isToday {
    final now = DateTime.now();
    return now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
  }

  Event copyWith({
    List<String>? rsvpUserIds,
    List<String>? attendeeUserIds,
    EventStatus? status,
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
      campus: campus,
      mode: mode,
      meetingLink: meetingLink,
      mapLink: mapLink,
      imageColor: imageColor,
      imagePath: imagePath,
      checkInCode: checkInCode,
      rsvpUserIds: rsvpUserIds ?? this.rsvpUserIds,
      attendeeUserIds: attendeeUserIds ?? this.attendeeUserIds,
      status: status ?? this.status,
    );
  }
}
