import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/events_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/event_card.dart';
import '../event_detail/event_detail_screen.dart';

/// Bookmarked events, persisted on-device via SQLite ([SavedEventsDatabase])
/// so the list survives app restarts independently of RSVP state.
class SavedEventsScreen extends StatelessWidget {
  const SavedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final saved = eventsProvider.savedEvents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved')),
      body: RefreshIndicator(
        onRefresh: eventsProvider.refresh,
        color: AppColors.primary,
        child: saved.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Nothing saved yet',
                    message: 'Tap the bookmark icon on any event to save it here for later.',
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: saved.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  final event = saved[index];
                  return EventCard(
                    event: event,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
