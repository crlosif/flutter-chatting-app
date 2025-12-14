import 'message.dart';

class ChatRoom {
  final String id;
  final String name;
  final bool isGroup;
  final DateTime createdAt;
  final Message? lastMessage;
  final List<String> participantIds;
  final String? avatarUrl;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.name,
    this.isGroup = false,
    required this.createdAt,
    this.lastMessage,
    required this.participantIds,
    this.avatarUrl,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      isGroup: json['is_group'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      participantIds: (json['participant_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      avatarUrl: json['avatar_url'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_group': isGroup,
      'created_at': createdAt.toIso8601String(),
      'participant_ids': participantIds,
      'avatar_url': avatarUrl,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    bool? isGroup,
    DateTime? createdAt,
    Message? lastMessage,
    List<String>? participantIds,
    String? avatarUrl,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      participantIds: participantIds ?? this.participantIds,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

