// lib/admin/admin_add_edit_category_screen.dart
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class AdminAddEditCategoryScreen extends StatefulWidget {
  final CategoryModel? category;

  const AdminAddEditCategoryScreen({super.key, this.category});

  @override
  State<AdminAddEditCategoryScreen> createState() =>
      _AdminAddEditCategoryScreenState();
}

class _AdminAddEditCategoryScreenState
    extends State<AdminAddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();

  late TextEditingController _nameController;
  late TextEditingController _iconUrlController;
  late TextEditingController
  _subCategoriesController; // <-- THÊM CONTROLLER MỚI

  bool _isLoading = false;
  bool get _isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconUrlController = TextEditingController(
      text: widget.category?.iconUrl ?? '',
    );
    // Chuyển List<String> thành chuỗi cách nhau bởi dấu phẩy
    _subCategoriesController = TextEditingController(
      text: widget.category?.subCategories.join(', ') ?? '',
    ); // <-- KHỞI TẠO
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconUrlController.dispose();
    _subCategoriesController.dispose(); // <-- HỦY CONTROLLER
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Chuyển chuỗi nhập vào thành List<String>
      List<String> subCategoriesList = _subCategoriesController.text
          .split(',') // Tách chuỗi bằng dấu phẩy
          .map((s) => s.trim()) // Loại bỏ khoảng trắng thừa
          .where((s) => s.isNotEmpty) // Loại bỏ chuỗi rỗng
          .toList();

      final data = {
        'name': _nameController.text,
        'iconUrl': _iconUrlController.text,
        'subCategories': subCategoriesList,
      };

      try {
        if (_isEditMode) {
          await _categoryService.updateCategory(widget.category!.id, data);
        } else {
          await _categoryService.addCategory(data);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu danh mục thành công!')),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu danh mục: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa danh mục' : 'Thêm danh mục mới'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên danh mục',
                        icon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'Ví dụ: Giày, Áo thể thao...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên danh mục';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _iconUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ hình ảnh',
                        icon: Icon(Icons.image_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'https://...link hình ảnh',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập link hình ảnh';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _subCategoriesController,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục con (cách nhau bởi dấu phẩy)',
                        icon: Icon(Icons.list),
                        border: OutlineInputBorder(),
                        hintText: 'Ví dụ: Quần áo, Giày, Dụng cụ',
                      ),
                    ),
                    // ------------------------------------
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCategory,
                        child: const Text('Lưu lại'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
