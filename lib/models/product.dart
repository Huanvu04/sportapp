import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> categoryIds;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryIds,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Đọc danh sách categoryIds (là array trên Firestore)
    List<String> cats = [];
    if (data['categoryIds'] is List) {
      cats = List<String>.from(data['categoryIds']);
    }

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      // --- THAY ĐỔI: Gán giá trị đã đọc ---
      categoryIds: cats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl, // Vẫn dùng imageUrl khi ghi
      // --- THAY ĐỔI: Ghi danh sách categoryIds ---
      'categoryIds': categoryIds,
    };
  }
}
