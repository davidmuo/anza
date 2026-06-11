import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/passport_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/verified_badge.dart';
import '../checkin/checkin_screen.dart';
import '../chat/chat_screen.dart';

/// Full details for one event: banner, poster identity, date/location,
/// description, attendee count, and the primary actions (RSVP, chat,
/// check-in). Looked up live by [eventId] so RSVP state always reflects
/// the latest provider state, even after navigating back and forth.
class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final passport = context.watch<PassportProvider>();
    final user = context.watch<AuthProvider>().currentUser!;
    final event = eventsProvider.eventById(eventId);

    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    final isRsvped = event.isRsvpedBy(user.id);
    final hasCheckedIn = passport.entries.any((e) => e.eventId == event.id);
    final dateLabel = DateFormat('EEEE, MMMM d • h:mm a').format(event.dateTime);
    final canCheckIn = isRsvped && event.isToday && !hasCheckedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: event.imageColor,
            expandedHeight: 180,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: event.imageColor,
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    event.category.label,
                    style: AppTextStyles.label.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: AppTextStyles.display.copyWith(fontSize: 26)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('Hosted by ${event.posterName}', style: AppTextStyles.bodyMuted),
                      if (event.postedByVerifiedOrg) ...[
                        const SizedBox(width: 8),
                        VerifiedBadge(label: event.posterVerifiedOrg!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(icon: Icons.calendar_today_outlined, label: dateLabel),
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.place_outlined, label: '${event.location} • ${event.campus.label} Campus'),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.groups_outlined,
                    label: '${event.attendeeUserIds.length} attended • ${event.rsvpUserIds.length} going',
                  ),
                  const SizedBox(height: 24),
                  Text('About this event', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(event.description, style: AppTextStyles.body),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: isRsvped ? "You're going — tap to cancel" : 'RSVP to this event',
                    icon: isRsvped ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                    color: isRsvped ? AppColors.surface : AppColors.primary,
                    textColor: isRsvped ? AppColors.ink : Colors.white,
                    onPressed: () async {
                      final wasAdded = await context.read<EventsProvider>().toggleRsvp(event.id, user.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            wasAdded
                                ? "You're on the list for ${event.title}."
                                : "You've cancelled your RSVP for ${event.title}.",
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Go to event chat',
                    icon: Icons.forum_outlined,
                    color: AppColors.surface,
                    textColor: AppColors.ink,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(spaceId: event.id, title: event.title),
                        ),
                      );
                    },
                  ),
                  if (hasCheckedIn) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.task_alt_rounded, color: AppColors.success),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "You're checked in — this event is in your passport.",
                              style: AppTextStyles.body.copyWith(color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (canCheckIn) ...[
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Check in to this event',
                      icon: Icons.qr_code_scanner_rounded,
                      color: AppColors.secondary,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CheckInScreen(eventId: event.id)),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.mutedText),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.bodyMuted)),
      ],
    );
  }
}
