import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/seed_data.dart';
import '../models/message.dart';

/// Holds chat messages for every "space" (an event id or a community id).
///
/// Messages are seed data only — chat is illustrative for the demo and
/// intentionally not persisted, keeping the storage layer focused on the
/// two things the brief calls out (RSVPs and the passport).
class ChatProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  final List<Message> _messages = SeedData.messages();

  /// Messages for [spaceId], oldest first (so they read top-to-bottom).
  List<Message> messagesFor(String spaceId) {
    final filtered = _messages.where((m) => m.spaceId == spaceId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtered;
  }

  void sendMessage({
    required String spaceId,
    required String senderId,
    required String senderName,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(Message(
      id: _uuid.v4(),
      spaceId: spaceId,
      senderId: senderId,
      senderName: senderName,
      text: trimmed,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
