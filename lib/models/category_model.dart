// lib/models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconUrl;
  final List<String> subCategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.subCategories,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Đọc trường array từ Firestore, chuyển về List<String>
    // Dùng List<dynamic> rồi cast để đảm bảo an toàn kiểu
    List<String> subs = [];
    if (data['subCategories'] is List) {
      subs = List<String>.from(data['subCategories']);
    }

    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
      subCategories: subs, // <-- SỬ DỤNG DỮ LIỆU ĐÃ ĐỌC
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iconUrl': iconUrl,
      'subCategories': subCategories, // <-- THÊM VÀO JSON
    };
  }
}
