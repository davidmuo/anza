import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../auth/auth_screen.dart';

/// First screen a new install shows: a short pitch for Anza plus a
/// "Get started" button that leads into sign in / sign up.
///
/// Persisted via [StorageService.setOnboardingComplete] (set when the user
/// reaches the feed) so returning users skip straight past this.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  'A',
                  style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 40),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to Anza',
                style: AppTextStyles.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your verified hub for opportunities, events, and communities '
                'across the ALU campus — workshops, hackathons, internships, '
                'and the people running them, all in one place.',
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              const _PitchPoint(
                icon: Icons.verified_rounded,
                text: 'Posts come from verified clubs, teams, and founders — not noise.',
              ),
              const SizedBox(height: 14),
              const _PitchPoint(
                icon: Icons.qr_code_rounded,
                text: 'Check in at events and build your participation passport.',
              ),
              const SizedBox(height: 14),
              const _PitchPoint(
                icon: Icons.forum_rounded,
                text: 'Chat with attendees and communities before and after events.',
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: 'Get started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PitchPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PitchPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text, style: AppTextStyles.bodyMuted),
          ),
        ),
      ],
    );
  }
}
