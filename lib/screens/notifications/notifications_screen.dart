import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/communities_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../chat/chat_screen.dart';
import '../event_detail/event_detail_screen.dart';

enum _NotificationType { mention, announcement }

/// One row in the notifications list — either someone tagging the current
/// user in a chat, or an announcement about an upcoming event.
class _NotificationItem {
  final _NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// All of the current user's notifications: `@mentions` from chats they're
/// part of, and announcements about upcoming events from verified hosts.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final chatProvider = context.watch<ChatProvider>();
    final communitiesProvider = context.watch<CommunitiesProvider>();
    final eventsProvider = context.watch<EventsProvider>();
    final now = DateTime.now();

    final firstName = user.name.split(' ').first.toLowerCase();
    final mentionPattern = RegExp('@$firstName', caseSensitive: false);

    final notifications = <_NotificationItem>[];

    // Mentions across every space the user is part of.
    final spaces = <(String id, String title)>[
      for (final event in eventsProvider.myRsvps(user.id)) (event.id, event.title),
      for (final community in communitiesProvider.myCommunities(user.id))
        (community.id, community.name),
    ];

    for (final space in spaces) {
      for (final message in chatProvider.messagesFor(space.$1)) {
        if (message.senderId == user.id) continue;
        if (!mentionPattern.hasMatch(message.text)) continue;

        notifications.add(_NotificationItem(
          type: _NotificationType.mention,
          title: '${message.senderName} mentioned you in ${space.$2}',
          body: message.text,
          timestamp: message.timestamp,
          icon: Icons.alternate_email_rounded,
          color: AppColors.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(spaceId: space.$1, title: space.$2),
            ),
          ),
        ));
      }
    }

    // Announcements: upcoming events from verified hosts in the next week.
    for (final event in eventsProvider.filteredEvents) {
      if (!event.postedByVerifiedOrg) continue;
      if (event.dateTime.isBefore(now)) continue;
      if (event.dateTime.difference(now) > const Duration(days: 7)) continue;

      notifications.add(_NotificationItem(
        type: _NotificationType.announcement,
        title: '${event.posterVerifiedOrg} posted "${event.title}"',
        body: 'Happening ${DateFormat('EEE, MMM d • h:mm a').format(event.dateTime)}',
        timestamp: event.dateTime,
        icon: Icons.campaign_outlined,
        color: event.imageColor,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
        ),
      ));
    }

    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Nothing new',
              message: "You'll see mentions and announcements here.",
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: item.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: AppTextStyles.label),
                              const SizedBox(height: 3),
                              Text(
                                item.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMuted,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('MMM d, h:mm a').format(item.timestamp),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
