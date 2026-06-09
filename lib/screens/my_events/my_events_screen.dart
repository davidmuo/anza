import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../models/passport_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/passport_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/event_card.dart';
import '../event_detail/event_detail_screen.dart';

/// "My Events" tab — two sections via a top tab bar:
///   • Going: events the user has RSVP'd to
///   • Attended: events recorded in the participation passport
///
/// Both lists reuse [EventCard] and live-update as RSVPs/check-ins change.
class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Events'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedText,
            indicatorColor: AppColors.primary,
            labelStyle: AppTextStyles.label,
            tabs: const [
              Tab(text: 'Going'),
              Tab(text: 'Attended'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GoingTab(),
            _AttendedTab(),
          ],
        ),
      ),
    );
  }
}

class _GoingTab extends StatelessWidget {
  const _GoingTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final eventsProvider = context.watch<EventsProvider>();
    final going = eventsProvider.myRsvps(user.id);

    if (going.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_outlined,
        title: 'No upcoming RSVPs',
        message: 'Browse the feed and tap RSVP on events you plan to attend.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: going.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final event = going[index];
        return EventCard(
          event: event,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
          ),
        );
      },
    );
  }
}

class _AttendedTab extends StatelessWidget {
  const _AttendedTab();

  @override
  Widget build(BuildContext context) {
    final passport = context.watch<PassportProvider>();
    final eventsProvider = context.watch<EventsProvider>();
    final entries = passport.entries;

    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.qr_code_2_outlined,
        title: 'No attended events yet',
        message: 'Check in at an event on the day it happens to add it here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final event = eventsProvider.eventById(entry.eventId);

        // If the underlying event ever disappears, fall back to a simple
        // tile built from the passport entry alone so history is preserved.
        if (event == null) {
          return _AttendedFallbackTile(entry: entry);
        }

        return EventCard(
          event: event,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
          ),
        );
      },
    );
  }
}

class _AttendedFallbackTile extends StatelessWidget {
  final PassportEntry entry;

  const _AttendedFallbackTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt_rounded, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.eventTitle, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(entry.category.label, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
