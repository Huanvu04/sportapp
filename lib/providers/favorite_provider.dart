// lib/providers/favorite_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart'; // Cần để thêm/xóa thông tin product nếu cần

class FavoriteProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _favoriteIds = []; // Danh sách ID yêu thích local
  bool _isLoading = false;

  List<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;

  FavoriteProvider() {
    _init(); // Gọi hàm tải dữ liệu khi provider được tạo
  }

  // Hàm khởi tạo, lắng nghe thay đổi trạng thái đăng nhập
  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadFavorites(user.uid); // Tải danh sách yêu thích khi đăng nhập
      } else {
        _favoriteIds = []; // Xóa danh sách khi đăng xuất
        notifyListeners();
      }
    });
  }

  // Tải danh sách ID yêu thích từ Firestore
  Future<void> _loadFavorites(String userId) async {
    if (_isLoading) return; // Tránh gọi nhiều lần
    _isLoading = true;
    notifyListeners(); // Thông báo bắt đầu load

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists &&
          userDoc.data() != null &&
          userDoc.data()!.containsKey('favoriteProductIds')) {
        // Lấy danh sách ID từ field 'favoriteProductIds'
        _favoriteIds = List<String>.from(userDoc.data()!['favoriteProductIds']);
      } else {
        _favoriteIds = []; // Nếu không có field hoặc document
      }
    } catch (e) {
      print("Error loading favorites: $e");
      _favoriteIds = []; // Đặt về rỗng nếu lỗi
    } finally {
      _isLoading = false;
      notifyListeners(); // Thông báo kết thúc load và cập nhật UI
    }
  }

  // Kiểm tra xem sản phẩm có trong danh sách yêu thích không
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  // Thêm/Xóa sản phẩm khỏi yêu thích
  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return; // Cần đăng nhập

    final productId = product.id;
    final currentlyFavorite = isFavorite(productId);

    // Cập nhật UI ngay lập tức
    if (currentlyFavorite) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();

    // Cập nhật Firestore
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      if (currentlyFavorite) {
        // Xóa khỏi array trên Firestore
        await userRef.update({
          'favoriteProductIds': FieldValue.arrayRemove([productId]),
        });
      } else {
        // Thêm vào array trên Firestore
        await userRef.update({
          'favoriteProductIds': FieldValue.arrayUnion([productId]),
        });
        // Nếu document user chưa có field 'favoriteProductIds', lệnh update có thể lỗi
        // Cách an toàn hơn là kiểm tra và tạo nếu cần, hoặc dùng set với merge:true
        // await userRef.set({'favoriteProductIds': FieldValue.arrayUnion([productId])}, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error updating favorites in Firestore: $e");
      // Nếu lỗi, rollback lại thay đổi trên UI
      if (currentlyFavorite) {
        _favoriteIds.add(productId); // Thêm lại nếu xóa bị lỗi
      } else {
        _favoriteIds.remove(productId); // Xóa đi nếu thêm bị lỗi
      }
      notifyListeners();
      // Có thể hiển thị SnackBar lỗi ở đây
    }
  }
}
