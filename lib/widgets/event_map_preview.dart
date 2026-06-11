import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class EventMapPreview extends StatelessWidget {
  final Event event;

  const EventMapPreview({super.key, required this.event});

  void _showLocationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.location, style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text('${event.campus.label} Campus', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 16),
              Text('Coordinates', style: AppTextStyles.label),
              const SizedBox(height: 4),
              SelectableText(
                '${event.latitude.toStringAsFixed(5)}, ${event.longitude.toStringAsFixed(5)}',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              Text('Open in maps', style: AppTextStyles.label),
              const SizedBox(height: 4),
              SelectableText(event.mapsUrl, style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showLocationSheet(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 140,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.surface),
              Image.network(
                event.mapImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _MapFallback(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const _MapFallback();
                },
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Details', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(Icons.map_outlined, size: 36, color: AppColors.mutedText),
    );
  }
}