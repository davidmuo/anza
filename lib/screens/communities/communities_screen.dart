import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/community.dart';
import '../../providers/auth_provider.dart';
import '../../providers/communities_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../chat/chat_screen.dart';
import 'create_community_screen.dart';

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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New community'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
            );
          },
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
    final user = context.watch<AuthProvider>().currentUser!;
    final communities = myCommunitiesOnly
        ? communitiesProvider.myCommunities(user.id)
        : communitiesProvider.communities;

    return RefreshIndicator(
      onRefresh: communitiesProvider.refresh,
      color: AppColors.primary,
      child: communities.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                EmptyState(
                  icon: myCommunitiesOnly ? Icons.diversity_3_outlined : Icons.search_off_rounded,
                  title: myCommunitiesOnly ? "You haven't joined any communities" : 'No communities found',
                  message: myCommunitiesOnly
                      ? 'Join a community from the "All" tab to see it here.'
                      : 'Try a different search term.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              itemCount: communities.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _CommunityTile(community: communities[index]),
            ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final Community community;

  const _CommunityTile({required this.community});

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(spaceId: community.id, title: community.name, community: community),
      ),
    );
  }

  void _promptToJoin(BuildContext context, CommunitiesProvider communitiesProvider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(community.name),
        content: Text(
          'Join ${community.name} to see and send messages in its chat.\n\n${community.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await communitiesProvider.toggleJoin(community.id);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              _openChat(context);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communitiesProvider = context.watch<CommunitiesProvider>();
    final joined = communitiesProvider.isJoined(community.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => joined ? _openChat(context) : _promptToJoin(context, communitiesProvider),
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
                  Row(
                    children: [
                      Flexible(child: Text(community.name, style: AppTextStyles.h2)),
                      if (community.isPending) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Pending',
                            style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(community.description, style: AppTextStyles.bodyMuted, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('${communitiesProvider.memberCountFor(community)} members', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => joined
                  ? communitiesProvider.toggleJoin(community.id)
                  : _promptToJoin(context, communitiesProvider),
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
