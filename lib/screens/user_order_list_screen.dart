// lib/screens/user_order_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Để kiểm tra đăng nhập
import '../models/order_model.dart';
import '../services/order_service.dart';

class UserOrderListScreen extends StatefulWidget {
  const UserOrderListScreen({super.key});

  @override
  State<UserOrderListScreen> createState() => _UserOrderListScreenState();
}

class _UserOrderListScreenState extends State<UserOrderListScreen> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final Map<String, String> _statusTranslations = {
    'pending': 'Chờ lấy hàng',
    'processing': 'Đang giao hàng',
    'shipped': 'Đã giao hàng',
    'cancelled': 'Đã hủy',
    'completed': 'Đã nhận hàng',
  };

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _loadUserOrders();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final docs = await _orderService.getUserActiveOrders(); // <-- GỌI HÀM MỚI
      if (!mounted) return;
      setState(() {
        _orders = docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print("Error loading user orders: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách đơn hàng: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- HÀM HỦY ĐƠN HÀNG ---
  Future<void> _cancelOrder(String orderId) async {
    // Xác nhận trước khi hủy
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Không'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Gọi thẳng hàm deleteOrder của Service
        await _orderService.updateOrderStatus(orderId, 'cancelled');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đơn hàng thành công.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadUserOrders(); // Tải lại danh sách
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi hủy đơn hàng: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  // -------------------------

  Future<void> _confirmReceipt(String orderId) async {
    // Bạn có thể thêm Dialog xác nhận nếu muốn
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã nhận hàng?'),
        content: const Text('Hãy chắc chắn rằng bạn đã kiểm tra kĩ sản phẩm.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Colors.green),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Gọi updateOrderStatus thay vì deleteOrder
        await _orderService.updateOrderStatus(orderId, 'completed');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // Đổi thông báo
            content: Text('Đã xác nhận nhận hàng. Đơn hàng hoàn thành!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Tải lại danh sách để cập nhật trạng thái hiển thị
        _loadUserOrders();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xác nhận: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper để format Timestamp
  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Center(child: Text('Vui lòng đăng nhập để xem đơn hàng.'));
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('Bạn đang không có đơn hàng nào.'))
          : RefreshIndicator(
              onRefresh: _loadUserOrders,
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  // Lấy text trạng thái ngắn gọn
                  final statusDisplay =
                      _statusTranslations[order.status] ?? order.status;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: ExpansionTile(
                      key: ValueKey(order.id),
                      title: Text('Đơn hàng #${order.id.substring(0, 6)}...'),
                      subtitle: Text(
                        'Ngày: ${_formatTimestamp(order.createdAt)}\nTrạng thái: $statusDisplay',
                      ), // Hiển thị text ngắn
                      trailing: Text(
                        currencyFormatter.format(order.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hiển thị danh sách sản phẩm chi tiết
                              Text(
                                'Chi tiết sản phẩm:', // Thêm tiêu đề nhỏ
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Lặp qua danh sách items và tạo ListTile cho mỗi item
                              ...order.items
                                  .map(
                                    (item) => ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      leading: const Icon(
                                        Icons.shopping_cart_checkout,
                                        size: 18,
                                        color: Colors.blueGrey,
                                      ),
                                      title: Text(
                                        item.productName,
                                      ), // Chỉ hiển thị tên
                                      subtitle: Text(
                                        'Số lượng: ${item.quantity}',
                                      ), // Hiển thị số lượng ở subtitle
                                      trailing: Text(
                                        currencyFormatter.format(
                                          item.price * item.quantity,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),

                              // -----------------
                              const Divider(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _buildOrderStatusAction(
                                  order,
                                ), // Giữ nguyên phần nút/trạng thái
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  // --- HÀM HELPER MỚI ĐỂ QUYẾT ĐỊNH HIỂN THỊ NÚT GÌ ---
  Widget _buildOrderStatusAction(OrderModel order) {
    switch (order.status) {
      case 'pending': // Chờ lấy hàng -> Hiển thị nút Hủy
        return TextButton.icon(
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text(
            'Hủy đơn hàng',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () => _cancelOrder(order.id),
        );
      case 'shipped': // Đã giao hàng -> Hiển thị nút Xác nhận
        return ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: const Text('Xác nhận đã nhận hàng'),
          onPressed: () => _confirmReceipt(order.id),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        );
      case 'completed': // Hoàn thành -> Hiển thị text
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
          child: Text(
            _statusTranslations['completed'] ?? 'Đã nhận hàng',
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
            ), // Màu khác
          ),
        );
      case 'processing': // Đang giao -> Hiển thị text
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
          child: Text(
            _statusTranslations['processing'] ?? 'Đang giao hàng',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'cancelled': // Đã hủy -> Hiển thị text
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
          child: Text(
            _statusTranslations['cancelled'] ?? 'Đã hủy',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default: // Các trạng thái khác (nếu có) -> Hiển thị text
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
          child: Text(
            _statusTranslations[order.status] ?? order.status,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
    }
  }
}
