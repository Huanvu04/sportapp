import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import thư viện intl
import '../models/order_model.dart';
import '../services/order_service.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  // Đặt currencyFormatter là final
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final List<String> _validStatuses = ['pending', 'processing', 'shipped'];
  final Map<String, String> _statusTranslations = {
    'pending': 'Chờ lấy hàng',
    'processing': 'Đang giao hàng',
    'shipped': 'Đã giao hàng',
    'completed': 'Đã nhận hàng',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // Tải các đơn hàng chưa bị hủy (bao gồm cả 'shipped')
  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final docs = await _orderService.getAdminOrders();
      if (!mounted) return;
      setState(() {
        _orders = docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      print("Error loading admin orders: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách đơn hàng: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Cập nhật trạng thái, không xóa đơn hàng
  Future<void> _updateStatus(OrderModel order, String newStatusKey) async {
    try {
      await _orderService.updateOrderStatus(order.id, newStatusKey);

      if (!mounted) return;
      final statusText = _statusTranslations[newStatusKey] ?? newStatusKey;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật trạng thái đơn hàng #${order.id.substring(0, 6)} thành "$statusText".',
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Cập nhật UI ngay lập tức
      setState(() {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          // Khi tạo OrderModel MỚI, phải truyền ĐẦY ĐỦ tham số
          _orders[index] = OrderModel(
            id: order.id,
            userId: order.userId,
            createdAt: order.createdAt,
            items: order.items,
            totalAmount: order.totalAmount,
            status: newStatusKey,
            recipientName: order.recipientName,
            shippingAddress: order.shippingAddress,
            phoneNumber: order.phoneNumber,
            notes: order.notes,
          );
          // Sắp xếp lại list
          _orders.sort((a, b) {
            int statusCompare = _statusValue(
              a.status,
            ).compareTo(_statusValue(b.status));
            if (statusCompare != 0) return statusCompare;
            return b.createdAt.compareTo(a.createdAt);
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật trạng thái: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Xóa đơn hàng đã hoàn thành
  Future<void> _archiveCompletedOrder(String orderId) async {
    // Dialog xác nhận (sửa lại nội dung)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận ẩn đơn hàng?'),
        content: const Text(
          'Đơn hàng này sẽ bị ẩn khỏi danh sách quản lý vĩnh viễn.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text(
              'Xác nhận Ẩn',
              style: TextStyle(color: Colors.orange),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // GỌI HÀM MỚI: archiveOrder
        await _orderService.archiveOrder(orderId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ẩn đơn hàng thành công.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadOrders(); // Tải lại danh sách (đơn hàng sẽ biến mất)
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi ẩn đơn hàng: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper để sắp xếp theo trạng thái
  int _statusValue(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'processing':
        return 1;
      case 'shipped':
        return 2;
      default:
        return 3; // Các trạng thái khác
    }
  }

  // Helper để format Timestamp
  String _formatTimestamp(Timestamp timestamp) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    } catch (e) {
      print("Error formatting timestamp: $e");
      return "Lỗi ngày";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadOrders,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(
              child: Text('Không có đơn hàng nào.'),
            ) // Sửa lại thông báo
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                // final currentStatusDisplay =
                //     _statusTranslations[order.status] ?? order.status;

                return Card(
                  color: order.status == 'shipped'
                      ? Colors.grey[200]
                      : (order.status == 'completed'
                            ? Colors.lightGreen[100]
                            : null),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ExpansionTile(
                    key: ValueKey(order.id),
                    title: Text('Đơn hàng #${order.id.substring(0, 6)}...'),
                    subtitle: Text(
                      'Ngày: ${_formatTimestamp(order.createdAt)}',
                    ),
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
                            Text(
                              'User ID: ${order.userId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 9),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Người nhận:',
                              order.recipientName,
                            ),
                            const SizedBox(height: 7),
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              'Giao đến:',
                              order.shippingAddress,
                            ),
                            const SizedBox(height: 7),
                            _buildInfoRow(
                              Icons.phone_outlined,
                              'SĐT:',
                              order.phoneNumber,
                            ),
                            const SizedBox(height: 7),
                            if (order.notes.isNotEmpty)
                              _buildInfoRow(
                                Icons.note_alt_outlined,
                                'Ghi chú:',
                                order.notes,
                              ),
                            const SizedBox(height: 7),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Trạng thái:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (order.status ==
                                    'completed') // Nếu đã hoàn thành
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Text(
                                      _statusTranslations['completed'] ??
                                          'Đã nhận hàng',
                                      style: const TextStyle(
                                        // Đổi màu thành Indigo cho đồng bộ User
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else // Nếu chưa hoàn thành (pending, processing, shipped)
                                  DropdownButton<String>(
                                    value: order.status,
                                    items: _validStatuses.map((statusKey) {
                                      bool isEnabled = true;
                                      // Logic Disable giữ nguyên
                                      if ((order.status == 'processing' ||
                                              order.status == 'shipped') &&
                                          statusKey == 'pending') {
                                        isEnabled = false;
                                      }
                                      if (order.status == 'shipped' &&
                                          statusKey == 'processing') {
                                        isEnabled = false;
                                      }

                                      return DropdownMenuItem<String>(
                                        value: statusKey,
                                        enabled: isEnabled,
                                        child: Text(
                                          _statusTranslations[statusKey] ??
                                              statusKey,
                                          style: TextStyle(
                                            color: isEnabled
                                                ? null
                                                : Colors.grey,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: order.status != 'shipped'
                                        ? (String? newStatusKey) {
                                            if (newStatusKey != null &&
                                                newStatusKey != order.status) {
                                              _updateStatus(
                                                order,
                                                newStatusKey,
                                              );
                                            }
                                          }
                                        : null,
                                  ), // Đóng DropdownButton
                              ], // Đóng children Row
                            ), // Đóng Row
                            const Divider(),
                            Text(
                              'Chi tiết sản phẩm:', // Thêm tiêu đề nhỏ
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Hiển thị chi tiết items
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
                            if (order.status == 'completed')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(
                                    Icons.archive,
                                    color: Colors.orange,
                                  ), // Đổi icon
                                  label: const Text(
                                    'Ẩn đơn hàng (Đã xong)',
                                    style: TextStyle(color: Colors.orange),
                                  ), // Đổi text
                                  onPressed: () => _archiveCompletedOrder(
                                    order.id,
                                  ), // Gọi hàm mới
                                ),
                              ),
                          ], // Đóng children Column
                        ), // Đóng Column
                      ), // Đóng Padding
                    ], // Đóng children ExpansionTile
                  ), // Đóng ExpansionTile
                ); // Đóng Card
              }, // Đóng itemBuilder
            ), // Đóng ListView.builder
    ); // Đóng Scaffold
  } // Đóng build method

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
} // Đóng class _AdminOrderListScreenState
