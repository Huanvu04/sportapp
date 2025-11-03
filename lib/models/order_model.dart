import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item_model.dart'; // Import model item

// Đại diện cho một đơn hàng
class OrderModel {
  final String id; // Document ID của đơn hàng trên Firestore
  final String userId; // ID của người dùng đặt hàng
  final Timestamp createdAt; // Thời gian đặt hàng
  final List<OrderItemModel> items; // Danh sách các sản phẩm trong đơn
  final double totalAmount;
  final String status;
  final String recipientName;
  final String shippingAddress;
  final String phoneNumber;
  final String notes;

  OrderModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.items,
    required this.totalAmount,
    this.status = 'pending',
    required this.recipientName,
    required this.shippingAddress,
    required this.phoneNumber,
    required this.notes,
  });

  // Chuyển đổi từ Firestore document
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<OrderItemModel> orderItems = (data['items'] as List? ?? [])
        .map(
          (itemMap) => OrderItemModel.fromMap(itemMap as Map<String, dynamic>),
        )
        .toList();

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      items: orderItems,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      recipientName: data['recipientName'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  // Chuyển đổi thành Map (dùng khi tạo đơn hàng, không cần id)
  Map<String, dynamic> toMapForCreation() {
    return {
      'userId': userId,
      'createdAt':
          createdAt, // Sẽ dùng FieldValue.serverTimestamp() khi gọi service
      // Chuyển đổi List<OrderItemModel> thành List<Map>
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
    };
  }
}
