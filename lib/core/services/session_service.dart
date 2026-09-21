import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const String _guestTokenKey = 'flexisport_guest_session_token';
  String? _cachedGuestToken;

  /// Lấy hoặc tạo mới token phiên duy nhất cho khách vãng lai (Guest User)
  Future<String> getGuestSessionToken() async {
    if (_cachedGuestToken != null && _cachedGuestToken!.isNotEmpty) {
      return _cachedGuestToken!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(_guestTokenKey);

      if (token == null || token.isEmpty) {
        final randomPart = Random().nextInt(900000) + 100000;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        token = 'guest_${timestamp}_$randomPart';
        await prefs.setString(_guestTokenKey, token);
      }

      _cachedGuestToken = token;
      return token;
    } catch (_) {
      final fallback = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      _cachedGuestToken = fallback;
      return fallback;
    }
  }

  /// Lấy User ID hiện tại hoặc trả về token phiên nếu là khách vãng lai
  Future<String> getCurrentUserIdOrGuestToken() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser != null && authUser.id.isNotEmpty) {
      return authUser.id;
    }
    return await getGuestSessionToken();
  }

  /// Kiểm tra xem user có phải là khách vãng lai hay không
  bool isGuestUser(String? userId) {
    if (userId == null || userId.isEmpty) return true;
    if (userId == 'guest_user' || userId.startsWith('guest_')) return true;
    return Supabase.instance.client.auth.currentUser == null;
  }
}
