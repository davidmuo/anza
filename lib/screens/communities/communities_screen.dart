import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/community.dart';
import '../../providers/communities_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../chat/chat_screen.dart';

/// Lists topic-based community spaces (clubs, teams, interest groups).
///
/// Students can search the directory, join/leave communities (state lives
/// in [CommunitiesProvider] and persists across restarts), and switch to a
/// "My Communities" view of just the ones they've joined. Tapping a tile
/// opens its chat — communities and events share the same [ChatScreen] /
/// [ChatProvider] since both are just "spaces" with messages.
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Communities'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedText,
            indicatorColor: AppColors.primary,
            labelStyle: AppTextStyles.label,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'My communities'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Consumer<CommunitiesProvider>(
                builder: (context, communitiesProvider, _) {
                  return TextField(
                    controller: _searchController,
                    onChanged: communitiesProvider.setSearchQuery,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Search communities…',
                      hintStyle: AppTextStyles.bodyMuted,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedText),
                      suffixIcon: communitiesProvider.searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
                              onPressed: () {
                                _searchController.clear();
                                communitiesProvider.setSearchQuery('');
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _CommunityList(myCommunitiesOnly: false),
                  _CommunityList(myCommunitiesOnly: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityList extends StatelessWidget {
  final bool myCommunitiesOnly;

  const _CommunityList({required this.myCommunitiesOnly});

  @override
  Widget build(BuildContext context) {
    final communitiesProvider = context.watch<CommunitiesProvider>();
    final communities =
        myCommunitiesOnly ? communitiesProvider.myCommunities : communitiesProvider.communities;

    if (communities.isEmpty) {
      return EmptyState(
        icon: myCommunitiesOnly ? Icons.diversity_3_outlined : Icons.search_off_rounded,
        title: myCommunitiesOnly ? "You haven't joined any communities" : 'No communities found',
        message: myCommunitiesOnly
            ? 'Join a community from the "All" tab to see it here.'
            : 'Try a different search term.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      itemCount: communities.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _CommunityTile(community: communities[index]),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final Community community;

  const _CommunityTile({required this.community});

  @override
  Widget build(BuildContext context) {
    final communitiesProvider = context.watch<CommunitiesProvider>();
    final joined = communitiesProvider.isJoined(community.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(spaceId: community.id, title: community.name),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: community.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(community.icon, color: community.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(community.name, style: AppTextStyles.h2),
                  const SizedBox(height: 3),
                  Text(community.description, style: AppTextStyles.bodyMuted, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('${communitiesProvider.memberCountFor(community)} members', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => communitiesProvider.toggleJoin(community.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: joined ? AppColors.mutedText : AppColors.primary,
                side: BorderSide(color: joined ? AppColors.border : AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(joined ? 'Joined' : 'Join'),
            ),
          ],
        ),
      ),
    );
  }
}
