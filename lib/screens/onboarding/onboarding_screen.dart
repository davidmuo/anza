import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../auth/auth_screen.dart';

/// First screens a new install shows: a brand splash followed by a short
/// pitch for Anza, ending with a "Get started" button that leads into sign
/// in / sign up.
///
/// Persisted via [StorageService.setOnboardingComplete] (set when the user
/// reaches the feed) so returning users skip straight past this.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: const [
                  _BrandPage(),
                  _PitchPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) {
                      final active = index == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (_page == 0)
                    PrimaryButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _next,
                    )
                  else
                    PrimaryButton(
                      label: 'Get started',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// First page: just the brand, front and center.
class _BrandPage extends StatelessWidget {
  const _BrandPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('ANZA', style: AppTextStyles.wordmark, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Your connection to everything ALU',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Second page: the fuller pitch, shown after the brand splash.
class _PitchPage extends StatelessWidget {
  const _PitchPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
        ],
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
