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

  /// Reaction keys ("messageId:emoji") the current device has added — used
  /// to toggle reactions on/off and highlight the ones "you" picked.
  final Set<String> _myReactions = {};

  /// Messages for [spaceId], oldest first (so they read top-to-bottom).
  List<Message> messagesFor(String spaceId) {
    final filtered = _messages.where((m) => m.spaceId == spaceId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtered;
  }

  bool hasReacted(String messageId, String emoji) =>
      _myReactions.contains('$messageId:$emoji');

  /// Adds or removes one reaction count for [emoji] on [messageId],
  /// tracking whether "you" are the one who added it so it can be undone.
  void toggleReaction(String messageId, String emoji) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = _messages[index];
    final reactions = Map<String, int>.from(message.reactions);
    final key = '$messageId:$emoji';

    if (_myReactions.contains(key)) {
      _myReactions.remove(key);
      final next = (reactions[emoji] ?? 1) - 1;
      if (next <= 0) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = next;
      }
    } else {
      _myReactions.add(key);
      reactions[emoji] = (reactions[emoji] ?? 0) + 1;
    }

    _messages[index] = message.copyWith(reactions: reactions);
    notifyListeners();
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

  /// Simulated refresh for pull-to-refresh — messages are local-only, so
  /// this just gives the spinner something to wait on.
  Future<void> refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    notifyListeners();
  }
}
