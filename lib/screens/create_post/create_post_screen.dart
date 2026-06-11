import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

/// Event-creation form, gated to verified users — the core of Anza's
/// "trust model": only verified clubs/teams/founders can post, so the
/// feed stays signal over noise.
///
/// Students who land here (they shouldn't via normal navigation, but a
/// defensive check costs nothing) see an explanatory empty state instead
/// of a broken form.
class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New event')),
      body: user.isVerified
          ? const _CreatePostForm()
          : const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Verified posters only',
              message: 'To keep the feed trustworthy, only verified clubs, academic '
                  'teams, and founders can publish events. Reach out to your club '
                  'lead if you think your organization should be verified.',
            ),
    );
  }
}

class _CreatePostForm extends StatefulWidget {
  const _CreatePostForm();

  @override
  State<_CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<_CreatePostForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  static const _uuid = Uuid();

  EventCategory _category = EventCategory.event;
  Campus _campus = Campus.kigali;
  DateTime _dateTime = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  /// Generates a random 6-character uppercase alphanumeric check-in code —
  /// same shape as the codes baked into seed events.
  String _generateCheckInCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final eventsProvider = context.read<EventsProvider>();
    final user = auth.currentUser!;

    final event = Event(
      id: _uuid.v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      posterId: user.id,
      posterName: user.name,
      posterVerifiedOrg: user.verifiedOrg,
      dateTime: _dateTime,
      location: _locationController.text.trim(),
      campus: _campus,
      imageColor: AppColors.accentPalette[Random().nextInt(AppColors.accentPalette.length)],
      checkInCode: _generateCheckInCode(),
    );

    eventsProvider.addEvent(event);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${event.title}" is live on the feed.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d • h:mm a').format(_dateTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Post a new event', style: AppTextStyles.h1),
            const SizedBox(height: 6),
            Text(
              'This will appear at the top of the feed for every student to see.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Title',
              controller: _titleController,
              hint: 'e.g. Founders\' Friday Pitch Night',
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Give your event a title' : null,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'What should people expect? Who is it for?',
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Add a short description' : null,
            ),
            const SizedBox(height: 18),
            Text('Category', style: AppTextStyles.label),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventCategory.values.map((category) {
                return CategoryChip(
                  label: category.label,
                  selected: _category == category,
                  onTap: () => setState(() => _category = category),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Campus', style: AppTextStyles.label),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Campus.values.map((campus) {
                return CategoryChip(
                  label: '${campus.label} Campus',
                  selected: _campus == campus,
                  onTap: () => setState(() => _campus = campus),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Location',
              controller: _locationController,
              hint: 'e.g. Innovation Hub, Room 204',
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Add a location' : null,
            ),
            const SizedBox(height: 18),
            Text('Date & time', style: AppTextStyles.label),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.mutedText),
                    const SizedBox(width: 10),
                    Text(dateLabel, style: AppTextStyles.body),
                    const Spacer(),
                    const Icon(Icons.edit_outlined, size: 16, color: AppColors.mutedText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Publish event',
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
