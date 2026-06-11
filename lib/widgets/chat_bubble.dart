import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'mini_avatar.dart';

const _quickReactions = ['👍', '❤️', '🎉', '😂', '🔥', '🙌'];

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
  });

  void _showReactionPicker(BuildContext context) {
    final chat = context.read<ChatProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 18,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _quickReactions
                .map(
                  (emoji) => InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      chat.toggleReaction(message.id, emoji);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(message.timestamp);

    final initials = message.senderName.trim().isEmpty
        ? '?'
        : message.senderName.trim().substring(0, 1).toUpperCase();

    final chat = context.watch<ChatProvider>();

    final bubble = GestureDetector(
      onLongPress: () => _showReactionPicker(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
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
                color: isOwnMessage
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );

    final reactionsRow = Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry in message.reactions.entries)
          if (entry.value > 0)
            _ReactionChip(
              emoji: entry.key,
              count: entry.value,
              active: chat.hasReacted(message.id, entry.key),
              onTap: () => chat.toggleReaction(message.id, entry.key),
            ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showReactionPicker(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Icon(Icons.add_reaction_outlined, size: 16, color: AppColors.mutedText),
          ),
        ),
      ],
    );

    if (isOwnMessage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [bubble, reactionsRow],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MiniAvatar(
              seed: message.senderId,
              label: initials,
              color: AppColors.forSeed(message.senderId),
              radius: 14,
            ),
            const SizedBox(width: 8),
            Flexible(child: bubble),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: reactionsRow,
        ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          '$emoji $count',
          style: AppTextStyles.caption.copyWith(
            color: active ? AppColors.primary : AppColors.mutedText,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}