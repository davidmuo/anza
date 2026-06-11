/// A single chat message within an event or community "space".
///
/// [spaceId] is either an event id or a community id — both chat surfaces
/// share the same underlying model and provider.
class Message {
  final String id;
  final String spaceId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  /// Emoji reaction counts, e.g. {'👍': 3, '🎉': 1}.
  final Map<String, int> reactions;

  const Message({
    required this.id,
    required this.spaceId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.reactions = const {},
  });

  Message copyWith({Map<String, int>? reactions}) => Message(
        id: id,
        spaceId: spaceId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: timestamp,
        reactions: reactions ?? this.reactions,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'spaceId': spaceId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'reactions': reactions,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        spaceId: json['spaceId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        reactions: (json['reactions'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as int),
            ) ??
            const {},
      );
}
