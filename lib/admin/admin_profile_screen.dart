// lib/admin/admin_profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminProfileScreen extends StatelessWidget {
  AdminProfileScreen({super.key});

  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hàm đăng xuất
  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (!context.mounted) return;
      // Quay về trang login và xóa mọi màn hình cũ
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đăng xuất thành công.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đăng xuất: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.shield_outlined,
                size: 80,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thông tin Quản trị viên',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),
            // Hiển thị Email
            _buildInfoRow('Email:', user?.email ?? 'Không có', Icons.email),
            const SizedBox(height: 40),
            // Nút Đăng xuất
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper để hiển thị thông tin
  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
          ],
        ),
      ],
    );
  }
}
