import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'feedback_toast.dart';

void showEventShareSheet(BuildContext context, Event event) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _EventShareSheet(event: event),
  );
}

class _EventShareSheet extends StatelessWidget {
  final Event event;

  const _EventShareSheet({required this.event});

  String get _shareText {
    final dateLabel = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime);
    return 'Check out "${event.title}" on Anza — $dateLabel at ${event.location}. '
        'Open it in the app: ${event.shareLink}';
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open that app.")),
      );
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!context.mounted) return;
    showFeedbackToast(context, message: 'Link copied to clipboard.');
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: event.shareCode));
    if (!context.mounted) return;
    showFeedbackToast(context, message: 'Code copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Text('Share this event', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text(
              event.title,
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: event.shareLink,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Scan in Anza to open this event',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Can't scan? Use this code instead",
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    event.shareCode,
                    style: AppTextStyles.h2.copyWith(
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _copyCode(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareAction(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _open(
                    context,
                    Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_shareText)}'),
                  ),
                ),
                _ShareAction(
                  icon: Icons.alternate_email_rounded,
                  label: 'X',
                  color: AppColors.ink,
                  onTap: () => _open(
                    context,
                    Uri.parse('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_shareText)}'),
                  ),
                ),
                _ShareAction(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  color: const Color(0xFFE8A33D),
                  onTap: () => _open(
                    context,
                    Uri(
                      scheme: 'mailto',
                      query: 'subject=${Uri.encodeComponent('Check out ${event.title} on Anza')}'
                          '&body=${Uri.encodeComponent(_shareText)}',
                    ),
                  ),
                ),
                _ShareAction(
                  icon: Icons.link_rounded,
                  label: 'Copy link',
                  color: AppColors.secondary,
                  onTap: () => _copyLink(context),
                ),
                _ShareAction(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  color: AppColors.primary,
                  onTap: () => SharePlus.instance.share(
                    ShareParams(text: _shareText, subject: event.title),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}