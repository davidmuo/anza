import 'package:flutter/material.dart';

import '../providers/passport_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Single cell in the profile's badge grid. Earned badges pop in full
/// color; unearned ones stay muted/outlined so the grid communicates
/// progress at a glance.
class BadgeTile extends StatelessWidget {
  final PassportBadge badge;

  const BadgeTile({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = badge.earned ? AppColors.primary : AppColors.mutedText;
    final background = badge.earned ? AppColors.primary.withValues(alpha: 0.1) : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
            child: Icon(badge.icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            badge.title,
            style: AppTextStyles.label.copyWith(
              color: badge.earned ? AppColors.ink : AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: AppTextStyles.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
