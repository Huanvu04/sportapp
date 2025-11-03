import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final CollectionReference _categoriesCollection = FirebaseFirestore.instance
      .collection('categories');

  // Lấy tất cả danh mục
  Future<List<QueryDocumentSnapshot>> getAllCategories() async {
    try {
      final querySnapshot = await _categoriesCollection.get();
      return querySnapshot.docs;
    } catch (e) {
      print('Lỗi khi lấy danh mục: $e');
      rethrow;
    }
  }

  // Thêm danh mục mới
  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      await _categoriesCollection.add(data);
    } catch (e) {
      print('Lỗi khi thêm danh mục: $e');
      rethrow;
    }
  }

  // Cập nhật danh mục
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _categoriesCollection.doc(categoryId).update(data);
    } catch (e) {
      print('Lỗi khi cập nhật danh mục: $e');
      rethrow;
    }
  }

  // Xóa danh mục
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
    } catch (e) {
      print('Lỗi khi xóa danh mục: $e');
      rethrow;
    }
  }

  // Đếm số lượng danh mục
  Future<int> getCategoryCount() async {
    try {
      final aggregateQuery = _categoriesCollection.count();
      final snapshot = await aggregateQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Lỗi khi đếm danh mục: $e');
      rethrow;
    }
  }
}
