import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/passport_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback_toast.dart';
import '../../widgets/primary_button.dart';

/// Check-in flow for one event.
///
/// Attendees type the 6-character code an organizer reads out at the door,
/// or scan the organizer's QR code in the in-app scanner — either way it
/// lands here. If the signed-in user *is* that organizer (the event's
/// poster), we skip the entry form and instead display the code as a QR.
class CheckInScreen extends StatefulWidget {
  final String eventId;

  /// Pre-filled from the QR scanner, if check-in was triggered that way —
  /// submitted automatically once the screen loads.
  final String? scannedCode;

  const CheckInScreen({super.key, required this.eventId, this.scannedCode});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorText;
  bool _isSubmitting = false;
  bool _justSucceeded = false;

  @override
  void initState() {
    super.initState();
    final scanned = widget.scannedCode;
    if (scanned != null) {
      _codeController.text = scanned.toUpperCase();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final userId = context.read<AuthProvider>().currentUser!.id;
        _submit(userId);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit(String userId) async {
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final eventsProvider = context.read<EventsProvider>();
    final passport = context.read<PassportProvider>();
    final event = eventsProvider.eventById(widget.eventId)!;

    final result = await passport.checkIn(
      event: event,
      userId: userId,
      enteredCode: _codeController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case CheckInResult.success:
        setState(() => _justSucceeded = true);
        showFeedbackToast(
          context,
          message:
              "You're checked in to ${event.title}! Added to your passport.",
        );
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) Navigator.of(context).pop();
        });
        break;
      case CheckInResult.wrongCode:
        setState(
          () => _errorText =
              "That code doesn't match — double-check with the organizer.",
        );
        break;
      case CheckInResult.alreadyCheckedIn:
        setState(() => _errorText = "You've already checked in to this event.");
        break;
      case CheckInResult.eventNotToday:
        setState(() => _errorText = 'Check-in opens on the day of the event.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final user = context.watch<AuthProvider>().currentUser!;
    final event = eventsProvider.eventById(widget.eventId);

    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    final isOrganizer = event.posterId == user.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Event check-in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: isOrganizer
            ? _OrganizerQrView(event: event)
            : _attendeeForm(event.title, user.id),
      ),
    );
  }

  Widget _attendeeForm(String eventTitle, String userId) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedScale(
            scale: _justSucceeded ? 1.1 : 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.elasticOut,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _justSucceeded
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _justSucceeded
                      ? Icons.check_circle_rounded
                      : Icons.confirmation_number_outlined,
                  key: ValueKey(_justSucceeded),
                  color: _justSucceeded
                      ? AppColors.success
                      : AppColors.primary,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Enter the event code', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Ask the organizer of "$eventTitle" for their 6-character check-in code, '
            'then enter it below to add this event to your participation passport.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: AppTextStyles.h2.copyWith(letterSpacing: 6),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'A1B2C3',
            ),
            validator: (value) {
              if (value == null || value.trim().length != 6) {
                return 'Enter the 6-character code';
              }
              return null;
            },
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Confirm check-in',
            isLoading: _isSubmitting,
            color: _justSucceeded ? AppColors.success : AppColors.primary,
            onPressed: () => _submit(userId),
          ),
        ],
      ),
    );
  }
}

/// Read-only QR display for event organizers — lets them show the
/// check-in code at the door for attendees to scan with the in-app
/// scanner, or read aloud and type manually.
class _OrganizerQrView extends StatelessWidget {
  final Event event;

  const _OrganizerQrView({required this.event});

  @override
  Widget build(BuildContext context) {
    final code = event.checkInCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Show this at the door', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text(
          'You posted "${event.title}" — attendees can scan this with the Anza QR '
          'scanner, or read this code aloud, to check themselves in and add the '
          'event to their passport.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 28),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: event.checkInLink,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.ink,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              code,
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
