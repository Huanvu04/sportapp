// Đại diện cho một sản phẩm trong đơn hàng
class OrderItemModel {
  final String productId; // ID của sản phẩm gốc
  final String productName;
  final int quantity;
  final double price; // Giá tại thời điểm mua

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  // Chuyển đổi từ Map (đọc từ Firestore)
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

  // Chuyển đổi thành Map (để lưu vào Firestore)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }
}
