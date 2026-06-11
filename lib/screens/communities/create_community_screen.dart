import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/community.dart';
import '../../providers/auth_provider.dart';
import '../../providers/communities_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

const _iconChoices = [
  Icons.diversity_3_outlined,
  Icons.groups_outlined,
  Icons.school_outlined,
  Icons.rocket_launch_outlined,
  Icons.sports_esports_outlined,
  Icons.palette_outlined,
  Icons.code_rounded,
  Icons.menu_book_outlined,
  Icons.music_note_outlined,
  Icons.camera_alt_outlined,
  Icons.fitness_center_outlined,
  Icons.volunteer_activism_outlined,
];

/// Form for proposing a new community.
///
/// Verified students' communities publish straight to the directory.
/// Everyone else can still create one — it's held as
/// [CommunityStatus.pending] on their "My communities" tab until a
/// verified moderator approves it, mirroring [CreatePostScreen]'s flow
/// for events.
class CreateCommunityScreen extends StatelessWidget {
  const CreateCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New community')),
      body: const _CreateCommunityForm(),
    );
  }
}

class _CreateCommunityForm extends StatefulWidget {
  const _CreateCommunityForm();

  @override
  State<_CreateCommunityForm> createState() => _CreateCommunityFormState();
}

class _CreateCommunityFormState extends State<_CreateCommunityForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  static const _uuid = Uuid();

  IconData _icon = _iconChoices.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final communitiesProvider = context.read<CommunitiesProvider>();
    final user = auth.currentUser!;

    final community = Community(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      icon: _icon,
      color: AppColors.forSeed(user.id + _nameController.text.trim()),
      memberCount: 1,
      posterId: user.id,
      status: user.isVerified ? CommunityStatus.approved : CommunityStatus.pending,
    );

    await communitiesProvider.addCommunity(community);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.isVerified
              ? '"${community.name}" is live in the directory.'
              : '"${community.name}" was submitted for approval. '
                  "You'll find it on your My communities tab once it's reviewed.",
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start a community', style: AppTextStyles.h1),
            const SizedBox(height: 6),
            Text(
              user.isVerified
                  ? 'This will appear in the community directory for every student to find.'
                  : "Since your account isn't verified yet, this will be reviewed "
                      'before it appears in the directory. You can track its status on '
                      'your My communities tab.',
              style: AppTextStyles.bodyMuted,
            ),
            if (!user.isVerified) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pending approval after you submit.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            AppTextField(
              label: 'Name',
              controller: _nameController,
              hint: 'e.g. Photography Society',
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Give your community a name' : null,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'What is this community about? Who should join?',
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Add a short description' : null,
            ),
            const SizedBox(height: 18),
            Text('Icon', style: AppTextStyles.label),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _iconChoices.map((icon) {
                final selected = icon == _icon;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _icon = icon),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? AppColors.primary : AppColors.mutedText,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Create community',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
