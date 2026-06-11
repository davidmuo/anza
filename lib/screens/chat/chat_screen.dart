import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/community.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/communities_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

/// Generic chat surface for any "space" — an event id or a community id.
/// Shared by event detail ("Go to event chat") and the communities list.
///
/// When [community] is provided, the chat is gated behind membership: a
/// student who hasn't joined sees a join prompt instead of the messages.
class ChatScreen extends StatefulWidget {
  final String spaceId;
  final String title;
  final Community? community;

  const ChatScreen({super.key, required this.spaceId, required this.title, this.community});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  Message? _replyingTo;
  String? _mentionQuery;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onTextChanged(String text) {
    final cursor = _messageController.selection.baseOffset;
    final upToCursor = cursor >= 0 ? text.substring(0, cursor) : text;
    final atIndex = upToCursor.lastIndexOf('@');

    if (atIndex == -1) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }

    final query = upToCursor.substring(atIndex + 1);
    if (query.contains(' ') || query.contains('\n')) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }

    setState(() => _mentionQuery = query);
  }

  void _selectMention(String name) {
    final text = _messageController.text;
    final cursor = _messageController.selection.baseOffset;
    final upToCursor = cursor >= 0 ? text.substring(0, cursor) : text;
    final atIndex = upToCursor.lastIndexOf('@');
    if (atIndex == -1) return;

    final newText = text.replaceRange(atIndex, cursor, '@$name ');
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: atIndex + name.length + 2),
    );
    setState(() => _mentionQuery = null);
    _focusNode.requestFocus();
  }

  void _setReplyingTo(Message message) {
    setState(() => _replyingTo = message);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _send(String userId, String userName) {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    final replyingTo = _replyingTo;
    context.read<ChatProvider>().sendMessage(
          spaceId: widget.spaceId,
          senderId: userId,
          senderName: userName,
          text: text,
          replyToId: replyingTo?.id,
          replyToSenderName: replyingTo?.senderName,
          replyToText: replyingTo?.text,
        );
    _messageController.clear();
    setState(() {
      _replyingTo = null;
      _mentionQuery = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent.')),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final community = widget.community;
    if (community != null) {
      final joined = context.watch<CommunitiesProvider>().isJoined(community.id);
      if (!joined) {
        return _JoinGate(community: community);
      }
    }

    final user = context.watch<AuthProvider>().currentUser!;
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messagesFor(widget.spaceId);

    final mentionCandidates = <String>[];
    if (_mentionQuery != null) {
      final query = _mentionQuery!.toLowerCase();
      final seen = <String>{};
      for (final message in messages) {
        if (message.senderId == user.id) continue;
        final firstName = message.senderName.split(' ').first;
        if (!firstName.toLowerCase().startsWith(query)) continue;
        if (seen.add(firstName)) mentionCandidates.add(firstName);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: chatProvider.refresh,
              color: AppColors.primary,
              child: messages.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'No messages yet',
                          message: 'Be the first to say something here.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return ChatBubble(
                          message: message,
                          isOwnMessage: message.senderId == user.id,
                          onReply: _setReplyingTo,
                        );
                      },
                    ),
            ),
          ),
          if (mentionCandidates.isNotEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 44),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                itemCount: mentionCandidates.length,
                itemBuilder: (context, index) {
                  final name = mentionCandidates[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('@$name'),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: AppTextStyles.caption,
                      onPressed: () => _selectMention(name),
                    ),
                  );
                },
              ),
            ),
          if (_replyingTo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 18, color: AppColors.mutedText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${_replyingTo!.senderName}',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _replyingTo!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.mutedText),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: AppTextStyles.body,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.title}...',
                        hintStyle: AppTextStyles.bodyMuted,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: _onTextChanged,
                      onSubmitted: (_) => _send(user.id, user.name),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                      onPressed: () => _send(user.id, user.name),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the chat for communities the user hasn't joined yet —
/// previews what the community is about and prompts them to join.
class _JoinGate extends StatelessWidget {
  final Community community;

  const _JoinGate({required this.community});

  @override
  Widget build(BuildContext context) {
    final communitiesProvider = context.watch<CommunitiesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(community.name)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: community.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(community.icon, color: community.color, size: 34),
            ),
            const SizedBox(height: 18),
            Text(community.name, style: AppTextStyles.h1, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              community.description,
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${communitiesProvider.memberCountFor(community)} members',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),
            Text(
              'Join this community to see and send messages in its chat.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Join ${community.name}',
              icon: Icons.group_add_rounded,
              onPressed: () => communitiesProvider.toggleJoin(community.id),
            ),
          ],
        ),
      ),
    );
  }
}
