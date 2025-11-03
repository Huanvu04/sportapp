// lib/screens/sub_categories_screen.dart

import 'package:flutter/material.dart';
import 'package:sportapp/models/category_model.dart'; // Sử dụng CategoryModel

class SubCategoriesScreen extends StatelessWidget {
  const SubCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy CategoryModel từ arguments
    final category =
        ModalRoute.of(context)!.settings.arguments as CategoryModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name), // Tên danh mục cha
      ),
      body: category.subCategories.isEmpty
          ? const Center(child: Text('Danh mục này chưa có mục con.'))
          : ListView.builder(
              itemCount: category.subCategories.length,
              itemBuilder: (context, index) {
                final subCategoryName = category.subCategories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.arrow_right_alt),
                    title: Text(subCategoryName),
                    onTap: () {
                      // --- SỬA CÁCH TRUYỀN ARGUMENTS ---
                      Navigator.pushNamed(
                        context,
                        '/product-list',
                        arguments: {
                          // Truyền ID của danh mục cha
                          'categoryId': category.id,
                          // Truyền tên danh mục cha
                          'categoryName': category.name,
                          // Truyền tên danh mục con được nhấn
                          'subCategoryName': subCategoryName,
                        },
                      );
                      // ---------------------------------
                    },
                  ),
                );
              },
            ),
    );
  }
}
