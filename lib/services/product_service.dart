import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  // Lấy tất cả sản phẩm
  Future<List<Product>> getAllProducts() async {
    try {
      final querySnapshot = await _productsCollection.get();
      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Lỗi khi lấy tất cả sản phẩm: $e');
      rethrow; // Ném lỗi ra để FutureBuilder xử lý
    }
  }

  // Lấy sản phẩm đã lọc (dùng cho User - theo categoryIds)
  Future<List<Product>> getFilteredProducts(
    String categoryId,
    String subCategoryName,
  ) async {
    try {
      print(
        "ProductService: Filtering by categoryId: $categoryId AND subCategory: $subCategoryName",
      );
      final querySnapshot = await _productsCollection
          .where(
            'categoryIds',
            arrayContains: categoryId,
          ) // Lọc theo ID danh mục cha
          .where(
            'subCategory',
            isEqualTo: subCategoryName,
          ) // LỌC THÊM THEO DANH MỤC CON
          .get();

      print("ProductService: Found ${querySnapshot.docs.length} products.");
      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Lỗi khi lấy sản phẩm đã lọc: $e');
      print(
        'QUAN TRỌNG: Lỗi này có thể do thiếu Index trên Firestore. Hãy kiểm tra Debug Console để lấy link tạo Index.',
      );
      rethrow;
    }
  }

  // --- HÀM THÊM SẢN PHẨM MỚI ---
  Future<void> addProduct(Map<String, dynamic> data) async {
    try {
      await _productsCollection.add(data);
    } catch (e) {
      print('Lỗi khi thêm sản phẩm: $e');
      rethrow; // Ném lỗi ra để màn hình Admin xử lý
    }
  }

  // --- HÀM CẬP NHẬT SẢN PHẨM ---
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _productsCollection.doc(productId).update(data);
    } catch (e) {
      print('Lỗi khi cập nhật sản phẩm $productId: $e');
      rethrow;
    }
  }

  // --- HÀM XÓA SẢN PHẨM ---
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      print('Lỗi khi xóa sản phẩm $productId: $e');
      rethrow;
    }
  }

  // --- HÀM ĐẾM TỔNG SỐ SẢN PHẨM ---
  Future<int> getProductCount() async {
    try {
      // Dùng aggregate query để đếm hiệu quả hơn
      final aggregateQuery = _productsCollection.count();
      final snapshot = await aggregateQuery.get();
      return snapshot.count ?? 0; // Trả về count, hoặc 0 nếu null
    } catch (e) {
      print('Lỗi khi đếm sản phẩm: $e');
      rethrow;
    }
  }
}
