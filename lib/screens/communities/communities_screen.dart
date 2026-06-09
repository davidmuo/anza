import 'package:flutter/material.dart';

import '../../data/seed_data.dart';
import '../../models/community.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';

/// Lists topic-based community spaces (clubs, teams, interest groups).
/// Tapping one opens its chat — communities and events share the same
/// [ChatScreen] / [ChatProvider] since both are just "spaces" with messages.
class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final communities = SeedData.communities;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Communities')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
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

  @override
  Widget build(BuildContext context) {
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
                  Text('${community.memberCount} members', style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
