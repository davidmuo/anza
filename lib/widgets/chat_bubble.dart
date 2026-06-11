import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'mini_avatar.dart';

const _quickReactions = ['👍', '❤️', '🎉', '😂', '🔥', '🙌'];

final _mentionPattern = RegExp(r'(@\w+)');

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final ValueChanged<Message> onReply;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.onReply,
  });

  void _showActionSheet(BuildContext context) {
    final chat = context.read<ChatProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppColors.ink),
              title: const Text('Reply'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onReply(message);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
          ],
        ),
      ),
    );
  }

  /// Renders [text] with `@mentions` highlighted in [mentionColor].
  Widget _buildText(String text, Color baseColor, Color mentionColor) {
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in _mentionPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(color: mentionColor, fontWeight: FontWeight.w700),
      ));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(
      TextSpan(style: AppTextStyles.body.copyWith(color: baseColor), children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(message.timestamp);

    final initials = message.senderName.trim().isEmpty
        ? '?'
        : message.senderName.trim().substring(0, 1).toUpperCase();

    final chat = context.watch<ChatProvider>();

    final textColor = isOwnMessage ? Colors.white : AppColors.ink;
    final mentionColor = isOwnMessage ? Colors.white : AppColors.primary;

    final bubble = GestureDetector(
      onLongPress: () => _showActionSheet(context),
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
            if (message.replyToText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: mentionColor, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.replyToSenderName ?? '',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mentionColor,
                      ),
                    ),
                    Text(
                      message.replyToText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            _buildText(message.text, textColor, mentionColor),
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
          onTap: () => _showActionSheet(context),
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