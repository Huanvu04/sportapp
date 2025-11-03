import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../providers/cart_provider.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final Map<String, String> _statusTranslations = {
    'completed': 'Đã nhận hàng',
    'cancelled': 'Đã hủy',
  };

  List<Product> _allProducts = [];
  bool _isProductsLoading = true;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _loadData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _orderService.getUserOrderHistory(),
        _productService.getAllProducts(),
      ]);

      final orderDocs = results[0] as List<QueryDocumentSnapshot>;

      if (!mounted) return;
      setState(() {
        _orders = orderDocs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        _allProducts = results[1] as List<Product>;
        _isLoading = false;
        _isProductsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print("Error loading order history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải lịch sử đơn hàng: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _buyAgain(OrderModel order, CartProvider cart) async {
    if (_isProductsLoading) return;

    int itemsAdded = 0;
    for (var item in order.items) {
      try {
        final productToAdd = _allProducts.firstWhere(
          (p) => p.id == item.productId,
        );
        cart.addItem(productToAdd, item.quantity);
        itemsAdded++;
      } catch (e) {
        print(
          "Sản phẩm ${item.productName} (ID: ${item.productId}) không còn tồn tại.",
        );
      }
    }

    if (!mounted) return;
    if (itemsAdded > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $itemsAdded sản phẩm vào giỏ hàng!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, '/cart');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thêm sản phẩm (có thể đã bị xóa).'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteOrderFromHistory(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử đơn hàng?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn đơn hàng này khỏi lịch sử? Hành động này không thể hoàn tác.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _orderService.deleteOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa đơn hàng khỏi lịch sử.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _orders.removeWhere((order) => order.id == orderId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa đơn hàng: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    } catch (e) {
      return "Lỗi ngày";
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (FirebaseAuth.instance.currentUser == null) {
      return const Center(child: Text('Vui lòng đăng nhập.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử mua hàng')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('Bạn chưa có lịch sử đơn hàng nào.'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
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
                        style: TextStyle(
                          color: order.status == 'cancelled'
                              ? Colors.red
                              : Colors.indigo,
                        ),
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
                                'Chi tiết sản phẩm:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                      title: Text(item.productName), // Tên
                                      subtitle: Text(
                                        'Số lượng: ${item.quantity}',
                                      ), // Số lượng
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () =>
                                        _deleteOrderFromHistory(order.id),
                                  ),
                                  const SizedBox(width: 8),
                                  if (order.status == 'completed')
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.replay_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Mua lại'),
                                      onPressed: _isProductsLoading
                                          ? null
                                          : () => _buyAgain(order, cart),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                      ),
                                    ),
                                ],
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
}
