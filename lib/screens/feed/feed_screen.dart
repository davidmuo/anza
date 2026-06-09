import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/event_card.dart';
import '../../widgets/user_avatar.dart';
import '../create_post/create_post_screen.dart';
import '../event_detail/event_detail_screen.dart';

/// Home tab: search field, category filter chips, and a live-filtered list
/// of [EventCard]s. This is the screen students land on after signing in.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final eventsProvider = context.watch<EventsProvider>();
    final user = auth.currentUser!;
    final filteredEvents = eventsProvider.filteredEvents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anza', style: AppTextStyles.display.copyWith(fontSize: 26)),
                  Text('Hi ${user.name.split(' ').first}, what\'s on?', style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
            UserAvatar(user: user, radius: 20),
          ],
        ),
        toolbarHeight: 72,
      ),
      floatingActionButton: user.isVerified
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New event'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: eventsProvider.setSearchQuery,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search events, locations, organizers…',
                hintStyle: AppTextStyles.bodyMuted,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedText),
                suffixIcon: eventsProvider.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
                        onPressed: () {
                          _searchController.clear();
                          eventsProvider.setSearchQuery('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                CategoryChip(
                  label: 'All',
                  selected: eventsProvider.categoryFilter == null,
                  onTap: () => eventsProvider.setCategoryFilter(null),
                ),
                const SizedBox(width: 8),
                ...EventCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: category.label,
                      selected: eventsProvider.categoryFilter == category,
                      onTap: () => eventsProvider.setCategoryFilter(
                        eventsProvider.categoryFilter == category ? null : category,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filteredEvents.isEmpty
                ? const EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'No events match',
                    message: 'Try a different search term or clear the category filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl,
                    ),
                    itemCount: filteredEvents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
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
          ),
        ],
      ),
    );
  }
}
