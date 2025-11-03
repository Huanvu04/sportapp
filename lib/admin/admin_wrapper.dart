// lib/admin/admin_wrapper.dart

import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';

class AdminWrapper extends StatefulWidget {
  const AdminWrapper({super.key});

  @override
  State<AdminWrapper> createState() => _AdminWrapperState();
}

class _AdminWrapperState extends State<AdminWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardScreen(), // Màn hình Lưới
    AdminProfileScreen(), // Màn hình Profile Admin
  ];

  final List<String> _titles = ['Quản Lý', 'Hồ Sơ Admin'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        // actions: [
        //   // Nút xem trang user, chỉ hiển thị ở tab "Quản Lý"
        //   if (_selectedIndex == 0)
        //     IconButton(
        //       icon: const Icon(Icons.store),
        //       tooltip: 'Xem trang User',
        //       onPressed: () {
        //         // Điều hướng đến trang Home của user
        //         Navigator.pushNamed(context, '/home');
        //       },
        //     ),
        // ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Quản lý',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}
