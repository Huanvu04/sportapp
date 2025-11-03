import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void dispose() {
    _recipientNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    // 1. Kiểm tra form hợp lệ
    if (!_formKey.currentState!.validate()) {
      return; // Không hợp lệ, dừng lại
    }

    // 2. Lấy thông tin từ provider
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return; // Kiểm tra lại giỏ hàng

    setState(() => _isLoading = true);

    try {
      // 3. Gọi service với thông tin đầy đủ
      await _orderService.placeOrder(
        cart.items.values.toList(),
        cart.totalPrice,
        _recipientNameController.text.trim(),
        _addressController.text.trim(),
        _phoneController.text.trim(),
        _notesController.text.trim(),
      );

      // 4. Xử lý sau khi thành công
      cart.clearCart();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/checkout-success');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đặt hàng: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy giỏ hàng (listen: true) để hiển thị tổng tiền
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin Giao hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết đơn hàng:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              // --- PHẦN ĐÃ SỬA (HIỂN THỊ DANH SÁCH SẢN PHẨM) ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  maxHeight: 200,
                ), // Giới hạn chiều cao
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final cartItem = cart.items.values.toList()[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          cartItem.product.imageUrl,
                        ),
                        onBackgroundImageError: (_, __) {},
                      ),
                      title: Text(cartItem.product.name), // Tên
                      subtitle: Text(
                        'Số lượng: ${cartItem.quantity}',
                      ), // Hiển thị "Số lượng: x"
                      trailing: Text(
                        currencyFormatter.format(
                          cartItem.product.price * cartItem.quantity,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              // ----------------------------------------------
              const SizedBox(height: 8),
              // Card tổng tiền
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(cart.totalPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Thông tin nhận hàng:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Địa chỉ nhận hàng
              TextFormField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên người nhận',
                  icon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên người nhận';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ nhận hàng',
                  icon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  icon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (value.trim().length < 10) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  icon: Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Giao hàng giờ hành chính...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              // Nút Xác nhận Đặt hàng
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'XÁC NHẬN ĐẶT HÀNG',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
