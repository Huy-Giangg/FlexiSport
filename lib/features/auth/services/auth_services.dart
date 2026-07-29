import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Hàm đăng ký tài khoản mới
  Future<User?> registerWithEmail(String email, String password, {String? name}) async {
    try {
      final AuthResponse result = await _auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'full_name': name, 'name': name} : null,
      );
      if (result.user != null) {
        await _saveProfile(result.user!, name: name);
      }
      return result.user;
    } on AuthException catch (e) {
      // Xử lý các lỗi phổ biến từ Supabase
      final message = e.message.toLowerCase();
      if (message.contains('user already exists') || message.contains('already registered')) {
        throw 'Email này đã được đăng ký.';
      } else if (message.contains('password should be') || message.contains('weak password')) {
        throw 'Mật khẩu quá yếu.';
      } else if (message.contains('rate limit') || message.contains('too many requests')) {
        throw 'Tần suất đăng ký quá nhanh hoặc vượt quá giới hạn gửi email. Vui lòng thử lại sau.';
      }
      throw e.message;
    } catch (e) {
      throw 'Lỗi hệ thống: ${e.toString()}';
    }
  }

  // Hàm đăng nhập
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // Gọi lệnh đăng nhập của Supabase
      final AuthResponse result = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on AuthException catch (e) {
      // Xử lý các mã lỗi phổ biến của Supabase để trả về thông báo tiếng Việt
      final message = e.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        throw 'Email hoặc mật khẩu không chính xác.';
      } else if (message.contains('email not confirmed')) {
        throw 'Email này chưa được xác nhận. Vui lòng kiểm tra hộp thư.';
      } else if (message.contains('user_disabled')) {
        throw 'Tài khoản đã bị khóa.';
      } else if (message.contains('rate limit') || message.contains('too many requests')) {
        throw 'Thử lại quá nhiều lần. Vui lòng đợi trong giây lát.';
      } else if (message.contains('missing email or phone')) {
        throw 'Email không được để trống.';
      }
      throw e.message;
    } catch (e) {
      throw 'Lỗi hệ thống: ${e.toString()}';
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Không lấy được thông tin xác thực từ Google.';
      }

      final AuthResponse response = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        await _saveProfile(response.user!);
      }

      return response.user;
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Lỗi kết nối Google: ${e.toString()}';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('user not found')) {
        throw 'Email này không tồn tại trong hệ thống.';
      }
      throw e.message;
    } catch (e) {
      throw 'Lỗi hệ thống: ${e.toString()}';
    }
  }

  // Hàm đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Hàm lưu thông tin vào bảng profiles trong database
  Future<void> _saveProfile(User user, {String? name}) async {
    try {
      final String profileName = name ??
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          '';

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'name': profileName,
        'email': user.email ?? '',
        'phone': user.phone ?? '',
        'birth_year': 0,
        'gender': '',
        'height': 0.0,
        'weight': 0.0,
      });
    } catch (e) {
      // Log lỗi nhưng không chặn luồng xác thực chính của người dùng
      print("Lỗi lưu thông tin profile: $e");
    }
  }
}

