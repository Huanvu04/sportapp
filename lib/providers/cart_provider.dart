import 'package:flutter/material.dart';
import '../models/product.dart';

// Lớp này không thay đổi
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  // Các getter này không thay đổi
  int get itemCount {
    return _items.length;
  }

  double get totalPrice {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total;
  }

  // --- THAY ĐỔI 1: Tham số của hàm addItem bây giờ là Product ---
  void addItem(Product product, [int quantity = 1]) {
    // Thêm [int quantity = 1]
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          // Cộng thêm số lượng được truyền vào (thay vì + 1)
          quantity: existingCartItem.quantity + quantity,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        // Dùng số lượng được truyền vào (mặc định là 1)
        () => CartItem(product: product, quantity: quantity),
      );
    }
    notifyListeners();
  }

  void increaseItemQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + 1,
        ),
      );
      notifyListeners();
    }
  }
  // -----------------------------

  // --- HÀM MỚI: GIẢM SỐ LƯỢNG (HOẶC XÓA) ---
  void decreaseItemQuantity(String productId) {
    if (!_items.containsKey(productId)) {
      return; // Không có gì để giảm
    }
    if (_items[productId]!.quantity > 1) {
      // Nếu số lượng > 1, chỉ giảm đi 1
      _items.update(
        productId,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      // Nếu số lượng là 1, xóa khỏi giỏ hàng
      _items.remove(productId);
    }
    notifyListeners();
  }

  // --- THAY ĐỔI 3: Tham số của hàm removeItem bây giờ là String ---
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Hàm này không thay đổi
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
