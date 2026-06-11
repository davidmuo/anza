import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../event_detail/event_detail_screen.dart';

/// Full list of events recommended for the current user, reached via
/// "See more" on the feed's "Recommended for you" rail.
class RecommendedEventsScreen extends StatelessWidget {
  const RecommendedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final user = context.watch<AuthProvider>().currentUser!;
    final recommended = eventsProvider.recommendedFor(user);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recommended for you')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: recommended.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final event = recommended[index];
          return EventCard(
            event: event,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
              );
            },
          );
        },
      ),
    );
  }
}
