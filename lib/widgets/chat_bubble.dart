import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Chat message bubble. Own messages align right in the coral accent;
/// others align left in a neutral surface — the classic messaging layout
/// everyone recognizes instantly during the demo.
class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;

  const ChatBubble({super.key, required this.message, required this.isOwnMessage});

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(message.timestamp);

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwnMessage ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
            bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
          ),
          border: isOwnMessage ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwnMessage)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.senderName,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            Text(
              message.text,
              style: AppTextStyles.body.copyWith(
                color: isOwnMessage ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeLabel,
              style: AppTextStyles.caption.copyWith(
                color: isOwnMessage ? Colors.white.withValues(alpha: 0.75) : AppColors.mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
