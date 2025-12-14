import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/message.dart';
import '../../../config/theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (for received messages)
          if (!isMe && showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accent,
                    AppTheme.accent.withOpacity(0.7),
                  ],
                ),
              ),
              child: message.senderAvatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        message.senderAvatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        (message.senderUsername ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
            )
          else if (!isMe)
            const SizedBox(width: 40),

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.accent,
                          Color(0xFFFF8585),
                        ],
                      )
                    : null,
                color: isMe ? null : AppTheme.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? AppTheme.accent : Colors.black)
                        .withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name (for group chats)
                  if (!isMe && showAvatar && message.senderUsername != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderUsername!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),

                  // Message content
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? AppTheme.primaryDark : AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  // Time & read status
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? AppTheme.primaryDark.withOpacity(0.7)
                              : AppTheme.textSecondary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? AppTheme.primaryDark.withOpacity(0.9)
                              : AppTheme.primaryDark.withOpacity(0.7),
                        ),
                      ],
                    ],
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

