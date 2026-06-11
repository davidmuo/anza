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

/// "My Events" tab — three sections via a top tab bar:
///   • Going: events the user has RSVP'd to
///   • Attended: events recorded in the participation passport
///   • Posted: events the user has published, including ones still
///     awaiting approval
///
/// All lists reuse [EventCard] and live-update as RSVPs/check-ins/posts change.
class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              Tab(text: 'Posted'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GoingTab(),
            _AttendedTab(),
            _PostedTab(),
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

    return RefreshIndicator(
      onRefresh: eventsProvider.refresh,
      color: AppColors.primary,
      child: going.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No upcoming RSVPs',
                  message: 'Browse the feed and tap RSVP on events you plan to attend.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
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

    return RefreshIndicator(
      onRefresh: eventsProvider.refresh,
      color: AppColors.primary,
      child: entries.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.qr_code_2_outlined,
                  title: 'No attended events yet',
                  message: 'Check in at an event on the day it happens to add it here.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
    );
  }
}

class _PostedTab extends StatelessWidget {
  const _PostedTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final eventsProvider = context.watch<EventsProvider>();
    final posted = eventsProvider.myPosts(user.id);

    return RefreshIndicator(
      onRefresh: eventsProvider.refresh,
      color: AppColors.primary,
      child: posted.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'Nothing posted yet',
                  message: 'Tap "New event" on the feed to publish something for the campus.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: posted.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final event = posted[index];
                return Stack(
                  children: [
                    EventCard(
                      event: event,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
                      ),
                    ),
                    if (event.status == EventStatus.pending)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Pending approval',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
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
