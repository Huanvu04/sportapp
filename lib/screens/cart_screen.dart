import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // <-- 3. TẠO STATE
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final OrderService _orderService = OrderService();
  bool _isPlacingOrder = false;
  void _navigateToCheckout() {
    Navigator.of(context).pushNamed('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (ctx, cart, _) => Scaffold(
        appBar: AppBar(title: const Text('Giỏ hàng của bạn')),
        body: Column(
          children: [
            Expanded(
              child: cart.items.isEmpty
                  ? const Center(child: Text('Giỏ hàng của bạn đang trống!'))
                  : ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (ctx, i) {
                        final itemKey = cart.items.keys.elementAt(i);
                        final cartItem = cart.items[itemKey]!;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ảnh sản phẩm
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    cartItem.product.imageUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Thông tin bên phải
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cartItem.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        'Tổng: ${currencyFormatter.format(cartItem.product.price * cartItem.quantity)}',
                                        style: const TextStyle(fontSize: 15),
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          // Minus
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: cartItem.quantity > 1
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            onPressed: cartItem.quantity > 1
                                                ? () =>
                                                      cart.decreaseItemQuantity(
                                                        itemKey,
                                                      )
                                                : null,
                                          ),

                                          Text(
                                            '${cartItem.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),

                                          // Plus
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.green,
                                            ),
                                            onPressed: () => cart
                                                .increaseItemQuantity(itemKey),
                                          ),

                                          const Spacer(),

                                          // Delete
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                cart.removeItem(itemKey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Chỉ hiển thị Card tổng tiền và nút Thanh toán nếu giỏ hàng không trống
            if (cart.items.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(15),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(fontSize: 20)),
                      const Spacer(),
                      Chip(
                        label: Text(
                          currencyFormatter.format(cart.totalPrice),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 10),
                      // --- 7. SỬA NÚT THANH TOÁN ---
                      ElevatedButton(
                        // Disable nút nếu đang đặt hàng hoặc giỏ hàng trống
                        onPressed: cart.items.isEmpty
                            ? null
                            : _navigateToCheckout,
                        child: _isPlacingOrder
                            ? const SizedBox(
                                // Hiển thị loading nhỏ
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('THANH TOÁN'),
                      ),
                      // -------------------------
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
