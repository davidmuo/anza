import 'package:flutter/material.dart';

/// Moderation state for a user-created community.
///
/// Communities created by verified users publish straight to [approved].
/// Everyone else can still create one, but it starts as [pending] —
/// visible only to its creator until a verified moderator approves it.
enum CommunityStatus { approved, pending }

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

  /// User id of the student who created this community. Empty for the
  /// built-in seed communities.
  final String posterId;

  /// Moderation state — see [CommunityStatus]. Defaults to
  /// [CommunityStatus.approved] so seed communities show up immediately.
  final CommunityStatus status;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.memberCount,
    this.posterId = '',
    this.status = CommunityStatus.approved,
  });

  bool get isPending => status == CommunityStatus.pending;
}
