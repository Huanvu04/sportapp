// lib/screens/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:sportapp/models/category_model.dart';
import 'package:sportapp/services/category_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // 3. Sử dụng CategoryService và Future
  final CategoryService _categoryService = CategoryService();
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    // Bắt đầu tải danh mục khi màn hình được tạo
    _categoriesFuture = _categoryService.getAllCategories().then(
      (docs) => docs.map((doc) => CategoryModel.fromFirestore(doc)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Không cần Scaffold hay AppBar vì HomeWrapper đã cung cấp
    return Scaffold(
      // Thêm lại Scaffold để có nền trắng
      // 4. Dùng FutureBuilder để xử lý tải dữ liệu
      body: FutureBuilder<List<CategoryModel>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          // Đang tải...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Lỗi...
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải danh mục.'));
          }
          // Không có dữ liệu...
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có danh mục nào.'));
          }

          // Tải thành công, hiển thị GridView
          final categories = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () {
                  print('Đã chọn danh mục: ${category.name}');
                  Navigator.pushNamed(
                    context,
                    '/sub-categories',
                    arguments: category,
                  ); // Tạm comment lại
                },
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hiển thị icon từ URL
                      Image.network(
                        category.iconUrl,
                        width: 60,
                        height: 60,
                        fit:
                            BoxFit.contain, // Dùng contain để icon không bị cắt
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.category, // Icon dự phòng nếu lỗi ảnh
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
