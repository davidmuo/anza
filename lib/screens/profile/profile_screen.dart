import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/passport_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badge_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_stat_tile.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';
import '../onboarding/onboarding_screen.dart';

/// Profile + Participation Passport — the app's signature screen.
///
/// Shows who the user is (avatar, role, interests) and what they've done
/// (attendance stats, earned badges, attended-event history). Everything
/// here is derived live from [PassportProvider], which persists across
/// restarts via shared_preferences.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final passport = context.watch<PassportProvider>();
    final user = auth.currentUser!;
    final badges = passport.badges;
    final entries = passport.entries;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmSignOut(context, auth),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // ---------------------------------------------------------------
          // Identity header
          // ---------------------------------------------------------------
          Row(
            children: [
              UserAvatar(user: user, radius: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTextStyles.h1),
                    const SizedBox(height: 4),
                    Text(user.email, style: AppTextStyles.bodyMuted),
                    const SizedBox(height: 8),
                    if (user.isVerified)
                      VerifiedBadge(label: user.verifiedOrg ?? 'Verified')
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Student', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(interest, style: AppTextStyles.label),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 32),
          Text('Participation Passport', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(
            'A record of every event you\'ve checked into on campus.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),

          // ---------------------------------------------------------------
          // Stats row
          // ---------------------------------------------------------------
          Row(
            children: [
              ProfileStatTile(
                value: '${passport.totalAttended}',
                label: 'Events attended',
                icon: Icons.local_activity_outlined,
              ),
              const SizedBox(width: 12),
              ProfileStatTile(
                value: '${passport.attendanceStreak}',
                label: 'Day streak',
                icon: Icons.local_fire_department_outlined,
              ),
              const SizedBox(width: 12),
              ProfileStatTile(
                value: '${passport.earnedBadgeCount}/${badges.length}',
                label: 'Badges earned',
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),

          const SizedBox(height: 28),
          Text('Badges', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: badges.map((badge) => BadgeTile(badge: badge)).toList(),
          ),

          const SizedBox(height: 28),
          Text('Attendance history', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No check-ins yet',
              message: 'Check in at your first event to start building your passport.',
            )
          else
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.task_alt_rounded, color: AppColors.success, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.eventTitle, style: AppTextStyles.label),
                              const SizedBox(height: 2),
                              Text(
                                '${entry.category.label} • ${DateFormat('MMM d, yyyy').format(entry.checkedInAt)}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out?'),
        content: const Text('You can sign back in any time with the same email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await auth.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: Text('Sign out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
