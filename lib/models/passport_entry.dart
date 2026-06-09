import 'event.dart';

/// A record of a successful event check-in, stored in the user's
/// "Participation Passport" and persisted across restarts.
class PassportEntry {
  final String id;
  final String eventId;
  final String eventTitle;
  final EventCategory category;
  final DateTime checkedInAt;

  const PassportEntry({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.category,
    required this.checkedInAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'category': category.name,
        'checkedInAt': checkedInAt.toIso8601String(),
      };

  factory PassportEntry.fromJson(Map<String, dynamic> json) => PassportEntry(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        eventTitle: json['eventTitle'] as String,
        category: EventCategory.values.byName(json['category'] as String),
        checkedInAt: DateTime.parse(json['checkedInAt'] as String),
      );
}
