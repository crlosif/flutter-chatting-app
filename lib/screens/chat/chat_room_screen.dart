import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/chat_service.dart';
import '../../models/chat_room.dart';
import '../../models/message.dart';
import '../../config/theme.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({super.key, required this.chatRoom});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = context.read<ChatService>();
      chatService.loadMessages(widget.chatRoom.id);
      chatService.subscribeToMessages(widget.chatRoom.id);
      _headerAnimation.forward();
    });
  }

  @override
  void dispose() {
    context.read<ChatService>().unsubscribeFromMessages(widget.chatRoom.id);
    _scrollController.dispose();
    _headerAnimation.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<ChatService>();
    final messages = chatService.getMessages(widget.chatRoom.id);
    final currentUserId = chatService.currentUserId;

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryMid,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              FadeTransition(
                opacity: _headerAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _headerAnimation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: _buildHeader(),
                ),
              ),

              // Messages
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == currentUserId;
                              final showAvatar = !isMe &&
                                  (index == 0 ||
                                      messages[index - 1].senderId !=
                                          message.senderId);
                              final showTimestamp = index == 0 ||
                                  _shouldShowTimestamp(
                                    messages[index - 1].createdAt,
                                    message.createdAt,
                                  );

                              return Column(
                                children: [
                                  if (showTimestamp)
                                    _buildTimestampDivider(message.createdAt),
                                  MessageBubble(
                                    message: message,
                                    isMe: isMe,
                                    showAvatar: showAvatar,
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),

              // Input
              SafeArea(
                top: false,
                child: MessageInput(
                  chatRoomId: widget.chatRoom.id,
                  onMessageSent: _scrollToBottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 8),

          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: widget.chatRoom.isGroup
                    ? [AppTheme.success, AppTheme.success.withOpacity(0.7)]
                    : [AppTheme.accent, AppTheme.accent.withOpacity(0.7)],
              ),
            ),
            child: widget.chatRoom.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      widget.chatRoom.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: widget.chatRoom.isGroup
                        ? const Icon(
                            Icons.group,
                            color: AppTheme.primaryDark,
                            size: 22,
                          )
                        : Text(
                            widget.chatRoom.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                  ),
          ),
          const SizedBox(width: 12),

          // Name & status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.online,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            onPressed: () {
              // TODO: Voice call
            },
            icon: const Icon(Icons.call_outlined),
            color: AppTheme.textPrimary,
          ),
          IconButton(
            onPressed: () {
              // TODO: Video call
            },
            icon: const Icon(Icons.videocam_outlined),
            color: AppTheme.textPrimary,
          ),
          IconButton(
            onPressed: () {
              // TODO: More options
            },
            icon: const Icon(Icons.more_vert),
            color: AppTheme.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_outlined,
              size: 40,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampDivider(DateTime timestamp) {
    String text;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      text = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      text = 'Yesterday';
    } else {
      text = timeago.format(timestamp);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppTheme.surfaceLight,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppTheme.surfaceLight,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(DateTime previous, DateTime current) {
    return current.difference(previous).inMinutes > 30;
  }
}

