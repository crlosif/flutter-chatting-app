import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

class ChatService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ChatRoom> _chatRooms = [];
  Map<String, List<Message>> _messages = {};
  bool _isLoading = false;
  StreamSubscription? _chatRoomsSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  List<Message> getMessages(String chatRoomId) {
    return _messages[chatRoomId] ?? [];
  }

  Future<void> loadChatRooms() async {
    if (currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('chat_room_participants')
          .select('''
            chat_room_id,
            chat_rooms (
              id,
              name,
              is_group,
              created_at,
              avatar_url
            )
          ''')
          .eq('user_id', currentUserId!);

      final rooms = <ChatRoom>[];

      for (final row in response as List) {
        final roomData = row['chat_rooms'] as Map<String, dynamic>;
        
        // Get participants
        final participantsRes = await _supabase
            .from('chat_room_participants')
            .select('user_id')
            .eq('chat_room_id', roomData['id']);
        
        final participantIds = (participantsRes as List)
            .map((p) => p['user_id'] as String)
            .toList();

        // Get last message
        final lastMsgRes = await _supabase
            .from('messages')
            .select('*, profiles(*)')
            .eq('chat_room_id', roomData['id'])
            .order('created_at', ascending: false)
            .limit(1);

        Message? lastMessage;
        if ((lastMsgRes as List).isNotEmpty) {
          lastMessage = Message.fromJson(lastMsgRes.first);
        }

        // Get unread count
        final unreadRes = await _supabase
            .from('messages')
            .select()
            .eq('chat_room_id', roomData['id'])
            .eq('is_read', false)
            .neq('sender_id', currentUserId!);

        // For DM, get other user's name
        String roomName = roomData['name'] ?? 'Chat';
        String? avatarUrl = roomData['avatar_url'];
        
        if (!(roomData['is_group'] as bool? ?? false)) {
          final otherUserId = participantIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );
          if (otherUserId.isNotEmpty) {
            final otherUser = await _supabase
                .from('profiles')
                .select()
                .eq('id', otherUserId)
                .single();
            roomName = otherUser['username'] ?? otherUser['email']?.split('@').first ?? 'User';
            avatarUrl = otherUser['avatar_url'];
          }
        }

        rooms.add(ChatRoom(
          id: roomData['id'],
          name: roomName,
          isGroup: roomData['is_group'] ?? false,
          createdAt: DateTime.parse(roomData['created_at']),
          participantIds: participantIds,
          lastMessage: lastMessage,
          avatarUrl: avatarUrl,
          unreadCount: (unreadRes as List).length,
        ));
      }

      // Sort by last message time
      rooms.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.createdAt;
        final bTime = b.lastMessage?.createdAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      _chatRooms = rooms;
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String chatRoomId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*, profiles(*)')
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: true);

      _messages[chatRoomId] = (response as List)
          .map((json) => Message.fromJson(json))
          .toList();

      notifyListeners();

      // Mark messages as read
      await markMessagesAsRead(chatRoomId);
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  void subscribeToMessages(String chatRoomId) {
    _messageSubscriptions[chatRoomId]?.cancel();

    _messageSubscriptions[chatRoomId] = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', chatRoomId)
        .order('created_at', ascending: true)
        .listen((data) async {
          final messages = <Message>[];
          
          for (final json in data) {
            // Fetch sender profile
            try {
              final profileRes = await _supabase
                  .from('profiles')
                  .select()
                  .eq('id', json['sender_id'])
                  .single();
              json['profiles'] = profileRes;
            } catch (_) {}
            
            messages.add(Message.fromJson(json));
          }
          
          _messages[chatRoomId] = messages;
          notifyListeners();
        });
  }

  void unsubscribeFromMessages(String chatRoomId) {
    _messageSubscriptions[chatRoomId]?.cancel();
    _messageSubscriptions.remove(chatRoomId);
  }

  Future<void> sendMessage(String chatRoomId, String content) async {
    if (currentUserId == null || content.trim().isEmpty) return;

    try {
      await _supabase.from('messages').insert({
        'chat_room_id': chatRoomId,
        'sender_id': currentUserId,
        'content': content.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatRoomId) async {
    if (currentUserId == null) return;

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_room_id', chatRoomId)
          .neq('sender_id', currentUserId!);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<ChatRoom?> createDirectMessage(UserProfile otherUser) async {
    if (currentUserId == null) return null;

    try {
      // Check if DM already exists
      final existingRooms = await _supabase
          .from('chat_room_participants')
          .select('chat_room_id')
          .eq('user_id', currentUserId!);

      for (final room in existingRooms as List) {
        final participants = await _supabase
            .from('chat_room_participants')
            .select('user_id')
            .eq('chat_room_id', room['chat_room_id']);

        final participantIds =
            (participants as List).map((p) => p['user_id'] as String).toList();

        if (participantIds.length == 2 &&
            participantIds.contains(otherUser.id)) {
          // DM already exists
          final roomData = await _supabase
              .from('chat_rooms')
              .select()
              .eq('id', room['chat_room_id'])
              .single();

          if (!(roomData['is_group'] as bool? ?? false)) {
            return ChatRoom(
              id: roomData['id'],
              name: otherUser.displayName,
              isGroup: false,
              createdAt: DateTime.parse(roomData['created_at']),
              participantIds: participantIds,
              avatarUrl: otherUser.avatarUrl,
            );
          }
        }
      }

      // Create new DM
      final roomRes = await _supabase.from('chat_rooms').insert({
        'name': 'DM',
        'is_group': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final roomId = roomRes['id'] as String;

      // Add participants
      await _supabase.from('chat_room_participants').insert([
        {'chat_room_id': roomId, 'user_id': currentUserId},
        {'chat_room_id': roomId, 'user_id': otherUser.id},
      ]);

      await loadChatRooms();

      return ChatRoom(
        id: roomId,
        name: otherUser.displayName,
        isGroup: false,
        createdAt: DateTime.now(),
        participantIds: [currentUserId!, otherUser.id],
        avatarUrl: otherUser.avatarUrl,
      );
    } catch (e) {
      debugPrint('Error creating DM: $e');
      return null;
    }
  }

  Future<ChatRoom?> createGroupChat(String name, List<String> userIds) async {
    if (currentUserId == null) return null;

    try {
      final roomRes = await _supabase.from('chat_rooms').insert({
        'name': name,
        'is_group': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final roomId = roomRes['id'] as String;

      // Add all participants including current user
      final allUserIds = [...userIds, currentUserId!];
      await _supabase.from('chat_room_participants').insert(
            allUserIds.map((id) => {'chat_room_id': roomId, 'user_id': id}).toList(),
          );

      await loadChatRooms();

      return ChatRoom(
        id: roomId,
        name: name,
        isGroup: true,
        createdAt: DateTime.now(),
        participantIds: allUserIds,
      );
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    for (final sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}

