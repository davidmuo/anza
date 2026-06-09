import 'package:flutter/material.dart';

/// A topic-based chat space (e.g. "Robotics Club"), distinct from
/// per-event chat. Both share the same [Message] model and [ChatProvider]
/// — a community's [id] simply doubles as its chat "space id".
class Community {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int memberCount;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.memberCount,
  });
}
