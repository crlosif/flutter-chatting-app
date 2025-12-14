import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<UserProfile> _users = [];
  bool _isLoading = false;

  List<UserProfile> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', currentUserId ?? '')
          .order('username');

      _users = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfile?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', currentUserId ?? '')
          .or('username.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  Stream<List<UserProfile>> watchOnlineUsers() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .map((json) => UserProfile.fromJson(json))
            .where((user) => user.isOnline)
            .toList());
  }
}

