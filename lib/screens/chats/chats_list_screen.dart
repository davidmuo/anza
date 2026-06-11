import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/community.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/communities_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../chat/chat_screen.dart';

/// One chat "space" the current user has access to — either an event
/// they've RSVP'd to, or a community they've joined.
class _ChatSpace {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Message? lastMessage;
  final Community? community;

  const _ChatSpace({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.lastMessage,
    this.community,
  });
}

/// All of the current user's chats in one place — event chats for events
/// they're going to, plus chats for communities they've joined. Reached via
/// the chat icon on the feed's app bar.
class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final eventsProvider = context.watch<EventsProvider>();
    final communitiesProvider = context.watch<CommunitiesProvider>();
    final chatProvider = context.watch<ChatProvider>();

    Message? lastMessageFor(String spaceId) {
      final messages = chatProvider.messagesFor(spaceId);
      return messages.isEmpty ? null : messages.last;
    }

    final spaces = <_ChatSpace>[
      for (final event in eventsProvider.myRsvps(user.id))
        _ChatSpace(
          id: event.id,
          title: event.title,
          icon: Icons.event_rounded,
          color: event.imageColor,
          lastMessage: lastMessageFor(event.id),
        ),
      for (final community in communitiesProvider.myCommunities(user.id))
        _ChatSpace(
          id: community.id,
          title: community.name,
          icon: community.icon,
          color: community.color,
          lastMessage: lastMessageFor(community.id),
          community: community,
        ),
    ];

    // Spaces with the most recent activity first; spaces with no messages
    // yet sink to the bottom, in their original order.
    spaces.sort((a, b) {
      final aTime = a.lastMessage?.timestamp;
      final bTime = b.lastMessage?.timestamp;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chats')),
      body: spaces.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No chats yet',
              message: 'RSVP to an event or join a community to start chatting with peers.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: spaces.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final space = spaces[index];
                final lastMessage = space.lastMessage;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: space.color.withValues(alpha: 0.15),
                    child: Icon(space.icon, color: space.color),
                  ),
                  title: Text(space.title, style: AppTextStyles.label),
                  subtitle: Text(
                    lastMessage == null
                        ? 'No messages yet'
                        : '${lastMessage.senderName}: ${lastMessage.text}',
                    style: AppTextStyles.bodyMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: lastMessage == null
                      ? null
                      : Text(
                          DateFormat('MMM d').format(lastMessage.timestamp),
                          style: AppTextStyles.caption,
                        ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          spaceId: space.id,
                          title: space.title,
                          community: space.community,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
