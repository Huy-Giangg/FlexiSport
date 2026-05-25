import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // Hàm đăng ký tài khoản mới
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Xử lý các mã lỗi từ Firebase
      if (e.code == 'weak-password') {
        throw 'Mật khẩu quá yếu.';
      } else if (e.code == 'email-already-in-use') {
        throw 'Email này đã được đăng ký.';
      }
      throw e.message ?? 'Đã xảy ra lỗi.';
    }
  }

  // Hàm đăng nhập
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // Gọi lệnh đăng nhập của Firebase
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Xử lý các mã lỗi phổ biến của Firebase để trả về thông báo tiếng Việt
      switch (e.code) {
        case 'user-not-found':
          throw 'Email này chưa được đăng ký tài khoản.';
        case 'invalid-credential':
          throw 'Email hoặc mật khẩu không chính xác.'; // Firebase dùng chung lỗi này
        case 'wrong-password':
          throw 'Mật khẩu không chính xác.';
        case 'user-disabled':
          throw 'Tài khoản đã bị khóa.';
        case 'invalid-email':
          throw 'Định dạng email không hợp lệ.';
        case 'too-many-requests':
          throw 'Thử lại quá nhiều lần. Vui lòng đợi trong giây lát.';
        default:
          throw e.message ?? 'Đã xảy ra lỗi không xác định.';
      }
    } catch (e) {
      throw 'Lỗi hệ thống: ${e.toString()}';
    }
  }

  Future<User?> signInWithGoogle() async {
  final googleUser = await _googleSignIn.signIn();
  if (googleUser == null) return null;

  final googleAuth = await googleUser.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

  return userCredential.user;
}

  // lib/core/services/auth_service.dart

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'Email này không tồn tại trong hệ thống.';
        case 'invalid-email':
          throw 'Định dạng email không hợp lệ.';
        default:
          throw 'Đã xảy ra lỗi: ${e.message}';
      }
    }
  }

  // Hàm đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
