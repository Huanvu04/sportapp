// lib/admin/admin_order_status_dropdown.dart
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

// Đây là Widget mới, nó sẽ tự quản lý trạng thái của chính nó
class OrderStatusDropdown extends StatefulWidget {
  final OrderModel order;
  // Hàm callback để báo cho cha (AdminOrderListScreen) biết cần tải lại
  final VoidCallback onStatusChanged;

  const OrderStatusDropdown({
    super.key,
    required this.order,
    required this.onStatusChanged,
  });

  @override
  State<OrderStatusDropdown> createState() => _OrderStatusDropdownState();
}

class _OrderStatusDropdownState extends State<OrderStatusDropdown> {
  // Các hằng số này được copy từ file admin_order_list_screen
  final List<String> _validStatuses = [
    'pending',
    'processing',
    'shipped',
    'return_requested',
    'completed',
  ];
  final Map<String, String> _statusTranslations = {
    'pending': 'Chờ lấy hàng',
    'processing': 'Đang giao hàng',
    'shipped': 'Đã giao hàng',
    'completed': 'Đã hoàn thành',
    'return_requested': 'Yêu cầu trả hàng',
  };

  final OrderService _orderService = OrderService();
  late String _currentStatus; // Trạng thái local của widget này
  bool _isUpdating = false; // Trạng thái loading

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status; // Lấy trạng thái ban đầu
  }

  // Cập nhật lại _currentStatus nếu widget cha build lại với order khác
  @override
  void didUpdateWidget(covariant OrderStatusDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.status != oldWidget.order.status) {
      _currentStatus = widget.order.status;
    }
  }

  // Hàm cập nhật trạng thái (chỉ xử lý logic, không setState của cha)
  Future<void> _updateStatus(String newStatusKey) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true; // Bật loading
    });

    try {
      await _orderService.updateOrderStatus(widget.order.id, newStatusKey);

      if (!mounted) return;
      // Cập nhật trạng thái local
      setState(() {
        _currentStatus = newStatusKey;
      });

      // Báo cho widget cha (AdminOrderListScreen) biết là đã cập nhật xong
      widget.onStatusChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái đơn hàng.'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật trạng thái: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false; // Tắt loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUpdating) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_currentStatus == 'completed') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(
          _statusTranslations['completed'] ?? 'Đã hoàn thành',
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _currentStatus,
        isExpanded: true, // Giúp căn chỉnh
        items: _validStatuses.map((statusKey) {
          bool isEnabled = true;
          if ((_currentStatus == 'processing' || _currentStatus == 'shipped') &&
              statusKey == 'pending') {
            isEnabled = false;
          }
          if (_currentStatus == 'shipped' && statusKey == 'processing') {
            isEnabled = false;
          }
          if (statusKey == 'return_requested' &&
              _currentStatus != 'return_requested') {
            isEnabled = false;
          }

          return DropdownMenuItem<String>(
            value: statusKey,
            enabled: isEnabled,
            child: Text(
              _statusTranslations[statusKey] ?? statusKey,
              style: TextStyle(color: isEnabled ? null : Colors.grey),
            ),
          );
        }).toList(),
        onChanged:
            (_currentStatus != 'shipped' && _currentStatus != 'completed')
            ? (String? newStatusKey) {
                if (newStatusKey != null && newStatusKey != _currentStatus) {
                  _updateStatus(
                    newStatusKey,
                  ); // Gọi hàm cập nhật của widget này
                }
              }
            : null,
      ),
    );
  }
}
