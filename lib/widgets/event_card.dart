import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/events_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'feedback_toast.dart';
import 'photo_banner.dart';
import 'verified_badge.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime);
    final eventsProvider = context.watch<EventsProvider>();
    final isSaved = eventsProvider.isSaved(event.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: PhotoBanner(
                imageUrl: event.imageUrl,
                color: event.imageColor,
                imagePath: event.imagePath,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            event.category.label,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () async {
                            final nowSaved = await eventsProvider.toggleSaved(
                              event.id,
                            );
                            if (!context.mounted) return;
                            showFeedbackToast(
                              context,
                              message: nowSaved
                                  ? 'Saved "${event.title}"'
                                  : 'Removed from saved events',
                              icon: nowSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.28),
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                key: ValueKey(isSaved),
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.h2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          event.posterName,
                          style: AppTextStyles.bodyMuted,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.postedByVerifiedOrg) ...[
                        const SizedBox(width: 6),
                        VerifiedBadge(
                          label: event.posterVerifiedOrg!,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(dateLabel, style: AppTextStyles.caption),
                      const SizedBox(width: 14),
                      Icon(
                        event.isOnline
                            ? Icons.videocam_outlined
                            : Icons.place_outlined,
                        size: 15,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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