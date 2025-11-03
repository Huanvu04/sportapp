// lib/admin/admin_statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/auth_service.dart'; // Hoặc UserService nếu bạn tạo riêng

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final AuthService _authService = AuthService(); // Hoặc UserService

  // Dùng Map để lưu kết quả từ các Future
  Future<Map<String, dynamic>>? _statsFuture;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadStats(); // Bắt đầu tải thống kê
  }

  void _loadStats() {
    setState(() {
      // Gọi tất cả các hàm lấy thống kê cùng lúc bằng Future.wait
      _statsFuture =
          Future.wait([
                _orderService
                    .getOrderStats(), // Future 0 -> Map{'totalOrders', 'totalRevenue'}
                _productService.getProductCount(), // Future 1 -> int
                _categoryService.getCategoryCount(), // Future 2 -> int
                _authService.getUserCount(), // Future 3 -> int
              ])
              .then((results) {
                // Gộp kết quả lại thành một Map lớn
                final orderStats = results[0] as Map<String, dynamic>;
                return {
                  'totalOrders': orderStats['totalOrders'] ?? 0,
                  'totalRevenue': orderStats['totalRevenue'] ?? 0.0,
                  'productCount': results[1] as int? ?? 0,
                  'categoryCount': results[2] as int? ?? 0,
                  'userCount': results[3] as int? ?? 0,
                };
              })
              .catchError((error) {
                print("Error loading combined stats: $error");
                // Ném lỗi ra để FutureBuilder xử lý
                throw error;
              });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê & Báo cáo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải thống kê: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Không có dữ liệu thống kê.'));
          }

          final stats = snapshot.data!;

          // Hiển thị dữ liệu
          return RefreshIndicator(
            // Cho phép kéo xuống để tải lại
            onRefresh: () async => _loadStats(),
            child: ListView(
              // Dùng ListView để có thể cuộn nếu cần
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildStatCard(
                  'Tổng Đơn Hàng',
                  stats['totalOrders'].toString(), // Chuyển số sang String
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Tổng Doanh Thu',
                  currencyFormatter.format(
                    stats['totalRevenue'],
                  ), // Format tiền tệ
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildStatCard(
                  'Số Lượng Sản Phẩm',
                  stats['productCount'].toString(),
                  Icons.inventory_2,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Số Lượng Danh Mục',
                  stats['categoryCount'].toString(),
                  Icons.category,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Số Lượng Người Dùng',
                  stats['userCount'].toString(),
                  Icons.people,
                  Colors.teal,
                  subtitle: '(Số người dùng đã đăng ký)', // Chú thích nhỏ
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget helper để tạo card thống kê
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40.0, color: color),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    // Hiển thị subtitle nếu có
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.0, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
