import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportapp/screens/home_wrapper_screen.dart';
import '../admin/admin_wrapper.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Hàm lấy role (giữ nguyên logic cũ)
  Future<String> _getUserRole(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final role = doc.data()!['role'] ?? 'user';
        print('AuthWrapper: Role found: $role for UID: ${user.uid}');
        return role;
      } else {
        print('AuthWrapper: No role document found for UID: ${user.uid}');
        return 'user';
      }
    } catch (e) {
      print('AuthWrapper: Error getting user role: $e');
      return 'user'; // Mặc định là user nếu có lỗi
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // --- TRẠNG THÁI 1: ĐANG KIỂM TRA ĐĂNG NHẬP ---
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          print("AuthWrapper: Checking auth state...");
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- TRẠNG THÁI 2: CHƯA ĐĂNG NHẬP ---
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          print("AuthWrapper: User is not logged in. Redirecting to login.");

          // Điều hướng sau khi build xong
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          });

          return const Scaffold(
            body: Center(child: Text("Redirecting to login...")),
          );
        }

        // --- TRẠNG THÁI 3: ĐÃ ĐĂNG NHẬP -> KIỂM TRA ROLE ---
        final user = authSnapshot.data!;
        print("AuthWrapper: User logged in (${user.uid}). Checking role...");

        return FutureBuilder<String>(
          future: _getUserRole(user),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              print("AuthWrapper: Checking role future...");
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnapshot.hasError) {
              print("AuthWrapper: Error getting role: ${roleSnapshot.error}");
              return const Scaffold(
                body: Center(child: Text('Lỗi kiểm tra quyền người dùng.')),
              );
            }

            final role = roleSnapshot.data ?? 'user';
            print("AuthWrapper: Role determined: $role. Navigating...");

            if (role == 'admin') {
              return const AdminWrapper(); // Vào trang admin
            } else {
              return const HomeWrapperScreen(); // Vào trang user
            }
          },
        );
      },
    );
  }
}
