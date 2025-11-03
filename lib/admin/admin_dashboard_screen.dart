// lib/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.0,
      children: [
        _buildDashboardCard(
          context,
          'Sản phẩm',
          'Quản lý sản phẩm',
          Icons.inventory_2,
          Colors.blue,
          () {
            Navigator.pushNamed(context, '/admin-products');
          },
        ),
        _buildDashboardCard(
          context,
          'Danh mục',
          'Quản lý danh mục',
          Icons.category,
          Colors.purple,
          () {
            Navigator.pushNamed(context, '/admin-categories');
          },
        ),
        _buildDashboardCard(
          context,
          'Đơn hàng',
          'Quản lý đơn hàng',
          Icons.shopping_bag,
          Colors.orange,
          () {
            Navigator.pushNamed(context, '/admin-orders');
          },
        ),
        _buildDashboardCard(
          context,
          'Thống kê',
          'Xem báo cáo',
          Icons.bar_chart,
          Colors.teal,
          () {
            Navigator.pushNamed(context, '/admin-statistics');
          },
        ),
      ],
    );
  }

  // Hàm _buildDashboardCard giữ nguyên
  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40.0, color: iconColor),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
