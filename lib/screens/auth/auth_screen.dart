import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/primary_button.dart';
import '../root_screen.dart';

/// Combined sign in / sign up screen.
///
/// Sign in matches an email against the seeded roster (mock auth — no
/// passwords). Sign up collects name, email, and interests (multi-select
/// chips, satisfying the onboarding "pick interests" requirement) to
/// create a lightweight local student account.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final Set<String> _selectedInterests = {};

  bool _isSubmitting = false;
  String? _formError;

  static final List<String> _interestOptions = EventCategory.values
      .map((c) => c.label)
      .toList();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();

    final result = _isSignUp
        ? await auth.signUp(
            name: _nameController.text,
            email: _emailController.text,
            interests: _selectedInterests.toList(),
          )
        : await auth.signIn(_emailController.text);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case AuthResult.success:
        final user = auth.currentUser!;
        await context.read<StorageService>().setOnboardingComplete(true);
        if (!mounted) return;
        final eventsProvider = context.read<EventsProvider>();
        eventsProvider.hydrateRsvpsForUser(user.id);
        eventsProvider.loadSavedEvents();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RootScreen()),
          (route) => false,
        );
        break;
      case AuthResult.userNotFound:
        setState(
          () => _formError =
              'No account found for that email. Try one of the seeded addresses, or sign up instead.',
        );
        break;
      case AuthResult.invalidEmail:
        setState(() => _formError = 'Enter a valid email address.');
        break;
      case AuthResult.emptyName:
        setState(() => _formError = 'Enter your name.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                  style: AppTextStyles.display,
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Tell us a little about you so we can personalize your feed.'
                      : 'Sign in with your ALU student email to continue.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 28),
                if (_isSignUp) ...[
                  AppTextField(
                    label: 'Full name',
                    controller: _nameController,
                    hint: 'e.g. Amara Chen',
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (!_isSignUp) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                ],
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'you@alustudent.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your email';
                    }
                    final pattern = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
                    if (!pattern.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 22),
                  Text('What are you into?', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    'Pick a few — this tunes what shows up first in your feed.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interestOptions.map((interest) {
                      final selected = _selectedInterests.contains(interest);
                      return CategoryChip(
                        label: interest,
                        selected: selected,
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedInterests.remove(interest);
                          } else {
                            _selectedInterests.add(interest);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ],
                if (_formError != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _formError!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _isSignUp ? 'Create account' : 'Sign in',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _isSignUp = !_isSignUp;
                      _formError = null;
                    }),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : "New to Anza? Create an account",
                    ),
                  ),
                ),
                if (!_isSignUp) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Try a seeded account',
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'amara.chen@alustudent.com (student)\n'
                          'david.okafor@alustudent.com (verified — Robotics Club)',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
