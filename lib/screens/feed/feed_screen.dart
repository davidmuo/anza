import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campus_chip.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/event_card.dart';
import '../../widgets/photo_banner.dart';
import '../../widgets/user_avatar.dart';
import '../chats/chats_list_screen.dart';
import '../create_post/create_post_screen.dart';
import '../event_detail/event_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import 'recommended_events_screen.dart';

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
    final recommended = eventsProvider.recommendedFor(user);

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
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Chats',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatsListScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            const SizedBox(width: 4),
            UserAvatar(user: user, radius: 20),
          ],
        ),
        toolbarHeight: 72,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New event'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
      ),
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
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                CampusChip(
                  label: 'All campuses',
                  selected: eventsProvider.campusFilter == null,
                  onTap: () => eventsProvider.setCampusFilter(null),
                ),
                const SizedBox(width: 8),
                ...Campus.values.map((campus) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CampusChip(
                      label: '${campus.label} Campus',
                      selected: eventsProvider.campusFilter == campus,
                      onTap: () => eventsProvider.setCampusFilter(
                        eventsProvider.campusFilter == campus ? null : campus,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: eventsProvider.refresh,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (recommended.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _RecommendedSection(recommended: recommended),
                    ),
                  if (filteredEvents.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.only(top: 40, bottom: 80),
                        child: EmptyState(
                          icon: Icons.event_busy_outlined,
                          title: 'No events match',
                          message: 'Try a different search term, or clear the category/campus filters.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index.isOdd) return const SizedBox(height: AppSpacing.lg);
                            final event = filteredEvents[index ~/ 2];
                            return EventCard(
                              event: event,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
                                );
                              },
                            );
                          },
                          childCount: filteredEvents.length * 2 - 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Recommended for you" rail — sits inline at the top of the feed's
/// scrollable list (rather than above it) so it scrolls away naturally
/// instead of eating into the events list's space.
class _RecommendedSection extends StatelessWidget {
  final List<Event> recommended;

  const _RecommendedSection({required this.recommended});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(child: Text('Recommended for you', style: AppTextStyles.h2)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecommendedEventsScreen()),
                  );
                },
                child: const Text('See more'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: recommended.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final event = recommended[index];
              return _RecommendedCard(
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
    );
  }
}

/// Compact horizontal-rail card used by the "Recommended for you" section —
/// a smaller cousin of [EventCard] that fits in a fixed-height row.
class _RecommendedCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _RecommendedCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d').format(event.dateTime);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 84,
              width: double.infinity,
              child: PhotoBanner(
                imageUrl: event.imageUrl,
                color: event.imageColor,
                imagePath: event.imagePath,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      style: AppTextStyles.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(dateLabel, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
