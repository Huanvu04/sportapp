import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Để lấy User ID
import '../providers/cart_provider.dart'; // Để lấy CartItem
import '../models/order_item_model.dart';
// Không import OrderModel ở đây vì hàm placeOrder chỉ tạo Map

class OrderService {
  final CollectionReference _ordersCollection = FirebaseFirestore.instance
      .collection('orders');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hàm đặt hàng (cho User gọi)
  Future<void> placeOrder(
    List<CartItem> cartItems,
    double totalAmount,
    String recipientName,
    String address,
    String phone,
    String notes,
  ) async {
    // Thêm 'notes'
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập!');
    }

    // Chuyển đổi CartItem thành OrderItemModel dạng Map
    final List<Map<String, dynamic>> orderItemsMap = cartItems.map((cartItem) {
      return OrderItemModel(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        quantity: cartItem.quantity,
        price: cartItem.product.price,
      ).toMap();
    }).toList();

    // Tạo dữ liệu đơn hàng
    final orderData = {
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'items': orderItemsMap,
      'totalAmount': totalAmount,
      'status': 'pending',
      'isAdminArchived': false, // Logic từ trước
      'recipientName': recipientName,
      'shippingAddress': address,
      'phoneNumber': phone,
      'notes': notes, // <-- TRƯỜNG GHI CHÚ MỚI
    };

    try {
      // Thêm đơn hàng mới vào collection 'orders'
      await _ordersCollection.add(orderData);
    } catch (e) {
      print('Lỗi khi đặt hàng: $e');
      rethrow;
    }
  }

  // Hàm lấy tất cả đơn hàng (cho Admin gọi)
  Future<List<QueryDocumentSnapshot>> getAdminOrders() async {
    try {
      final querySnapshot = await _ordersCollection
          .where('status', isNotEqualTo: 'cancelled')
          // CHỈ LẤY CÁC ĐƠN HÀNG CHƯA BỊ LƯU TRỮ
          .where('isAdminArchived', isEqualTo: false)
          .orderBy('status')
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print('Lỗi khi lấy danh sách đơn hàng cho admin: $e');
      rethrow;
    }
  }

  // (Tùy chọn) Hàm cập nhật trạng thái đơn hàng (cho Admin)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _ordersCollection.doc(orderId).update({'status': newStatus});
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái đơn hàng $orderId: $e');
      rethrow;
    }
  }

  // (Tùy chọn) Hàm xóa đơn hàng (cho Admin)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _ordersCollection.doc(orderId).delete();
    } catch (e) {
      print('Lỗi khi xóa đơn hàng $orderId: $e');
      rethrow;
    }
  }

  // Hàm lấy đơn hàng của người dùng hiện tại (cho User gọi)
  Future<List<QueryDocumentSnapshot>> getUserActiveOrders() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập!');

    try {
      final querySnapshot = await _ordersCollection
          .where('userId', isEqualTo: user.uid)
          // Chỉ lấy các trạng thái đang hoạt động
          .where('status', whereIn: ['pending', 'processing', 'shipped'])
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print('Lỗi khi lấy đơn hàng đang hoạt động: $e');
      rethrow;
    }
  }

  // Hàm lấy lịch sử đơn hàng đã hoàn thành hoặc bị hủy của người dùng
  Future<List<QueryDocumentSnapshot>> getUserOrderHistory() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập!');

    try {
      final querySnapshot = await _ordersCollection
          .where('userId', isEqualTo: user.uid)
          // Chỉ lấy các trạng thái đã kết thúc
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print('Lỗi khi lấy lịch sử đơn hàng: $e');
      rethrow;
    }
  }

  // Hàm lấy thống kê đơn hàng cho Admin
  Future<Map<String, dynamic>> getOrderStats() async {
    int totalOrders = 0;
    double totalRevenue = 0.0;

    try {
      // Lấy tất cả đơn hàng CHƯA BỊ HỦY để đếm tổng số
      final activeOrdersSnapshot = await _ordersCollection
          .where('status', isNotEqualTo: 'cancelled')
          .get();
      totalOrders = activeOrdersSnapshot.size;

      // Lấy các đơn hàng ĐÃ HOÀN THÀNH để tính tổng doanh thu
      final completedOrdersSnapshot = await _ordersCollection
          .where('status', isEqualTo: 'completed') // <-- THAY ĐỔI Ở ĐÂY
          .get();

      // Cộng dồn totalAmount từ các đơn đã hoàn thành
      for (var doc in completedOrdersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null &&
            data.containsKey('totalAmount') &&
            data['totalAmount'] is num) {
          totalRevenue += (data['totalAmount'] as num).toDouble();
        }
      }

      return {
        'totalOrders': totalOrders, // Vẫn đếm tất cả đơn chưa hủy
        'totalRevenue': totalRevenue, // Chỉ tính tiền đơn đã hoàn thành
      };
    } catch (e) {
      print('Lỗi khi lấy thống kê đơn hàng: $e');
      rethrow;
    }
  }

  // Hàm lưu trữ đơn hàng (cho Admin)
  Future<void> archiveOrder(String orderId) async {
    try {
      // Cập nhật trạng thái 'isAdminArchived' thành true
      await _ordersCollection.doc(orderId).update({'isAdminArchived': true});
    } catch (e) {
      print('Lỗi khi lưu trữ đơn hàng $orderId: $e');
      rethrow;
    }
  }
}
