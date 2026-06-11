import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../widgets/primary_button.dart';

/// Event-creation form, open to every student.
///
/// Verified posters (clubs, academic teams, founders) publish straight to
/// the feed. Anyone else can still post — their event is held as
/// [EventStatus.pending] on their "Posted" tab until a verified moderator
/// approves it, keeping the public feed signal over noise without locking
/// regular students out entirely.
class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New event')),
      body: const _CreatePostForm(),
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
  final _mapLinkController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  static const _uuid = Uuid();

  EventCategory _category = EventCategory.event;
  Campus _campus = Campus.kigali;
  EventMode _mode = EventMode.inPerson;
  DateTime _dateTime = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;
  XFile? _image;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _mapLinkController.dispose();
    _meetingLinkController.dispose();
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

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    setState(() => _image = image);
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
      location: _mode == EventMode.online
          ? 'Online'
          : _locationController.text.trim(),
      campus: _campus,
      mode: _mode,
      meetingLink: _mode == EventMode.online
          ? _meetingLinkController.text.trim()
          : null,
      mapLink: _mode == EventMode.inPerson && _mapLinkController.text.trim().isNotEmpty
          ? _mapLinkController.text.trim()
          : null,
      imageColor: AppColors.accentPalette[Random().nextInt(AppColors.accentPalette.length)],
      imagePath: _image?.path,
      checkInCode: _generateCheckInCode(),
      status: user.isVerified ? EventStatus.approved : EventStatus.pending,
    );

    eventsProvider.addEvent(event);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.isVerified
              ? '"${event.title}" is live on the feed.'
              : '"${event.title}" was submitted for approval. '
                  "You'll find it on your Posted tab once it's reviewed.",
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d • h:mm a').format(_dateTime);
    final user = context.watch<AuthProvider>().currentUser!;

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
              user.isVerified
                  ? 'This will appear at the top of the feed for every student to see.'
                  : "Since your account isn't verified yet, this will be reviewed "
                      'before it appears on the feed. You can track its status on '
                      'your Posted tab.',
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
            Text('Photo', style: AppTextStyles.label),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.mutedText,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a photo (optional)',
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_image!.path), fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => setState(() => _image = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
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
            Text('Format', style: AppTextStyles.label),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventMode.values.map((mode) {
                return CategoryChip(
                  label: mode.label,
                  selected: _mode == mode,
                  onTap: () => setState(() => _mode = mode),
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
            if (_mode == EventMode.online) ...[
              AppTextField(
                label: 'Meeting link',
                controller: _meetingLinkController,
                hint: 'e.g. https://zoom.us/j/123456789',
                keyboardType: TextInputType.url,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Add a Zoom or Google Meet link';
                  final uri = Uri.tryParse(trimmed);
                  if (uri == null || !uri.isScheme('HTTP') && !uri.isScheme('HTTPS')) {
                    return 'Enter a valid link starting with https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
            ] else ...[
              AppTextField(
                label: 'Location',
                controller: _locationController,
                hint: 'e.g. Innovation Hub, Room 204',
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Add a location' : null,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Map link (optional)',
                controller: _mapLinkController,
                hint: 'e.g. https://maps.app.goo.gl/...',
                keyboardType: TextInputType.url,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return null;
                  final uri = Uri.tryParse(trimmed);
                  if (uri == null || !uri.isScheme('HTTP') && !uri.isScheme('HTTPS')) {
                    return 'Enter a valid link starting with https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
            ],
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
