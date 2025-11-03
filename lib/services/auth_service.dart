// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // UID của admin mặc định
  static const String adminUID = 'mFydudeaweQ6bDVxsyv5eCaGC2k1';

  // ----- Đăng nhập bằng Email & Mật khẩu -----
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // ----- Đăng ký bằng Email & Mật khẩu -----
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Khi đăng ký xong, lưu thông tin user vào Firestore
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': email.trim(),
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // ----- Đăng nhập với Google -----
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'USER_CANCELLED');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw FirebaseAuthException(code: 'TOKEN_MISSING');
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Kiểm tra và tạo document user nếu chưa có
    final user = userCredential.user;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Nếu là admin mặc định
        final role = (user.uid == adminUID) ? 'admin' : 'user';
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    return userCredential;
  }

  // ----- Đăng xuất -----
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // Lấy thông tin role từ Firestore
  Future<DocumentSnapshot> getUserRole(String uid) async {
    try {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
    } catch (e) {
      print("AuthService Error getting user role: $e");
      rethrow; // Ném lỗi ra để LoginScreen xử lý
    }
  }

  // Đếm số lượng người dùng
  Future<int> getUserCount() async {
    try {
      final aggregateQuery = _usersCollection.count();
      final snapshot = await aggregateQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Lỗi khi đếm người dùng: $e');
      rethrow;
    }
  }
}
