import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart'; // Dùng ProductService
import '../services/category_service.dart';
import '../models/category_model.dart';

class AdminAddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AdminAddEditProductScreen({super.key, this.product});

  @override
  State<AdminAddEditProductScreen> createState() =>
      _AdminAddEditProductScreenState();
}

class _AdminAddEditProductScreenState extends State<AdminAddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  // Dùng ProductService
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  bool _isLoading = false;
  bool _isLoadingCategories = true;
  bool get _isEditMode => widget.product != null;

  List<CategoryModel> _availableCategories = [];
  List<String> _selectedCategoryIds = [];

  String? _selectedSubCategory;
  List<String> _currentSubCategoryOptions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.product?.imageUrl ?? '',
    );
    if (_isEditMode) {
      _selectedCategoryIds.addAll(widget.product!.categoryIds);
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categoryDocs = await _categoryService.getAllCategories();
      setState(() {
        _availableCategories = categoryDocs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Thêm SnackBar(...)
            content: Text('Lỗi tải danh mục: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _updateSubCategoryOptions() {
    Set<String> subCategorySet = {};
    for (var category in _availableCategories) {
      if (_selectedCategoryIds.contains(category.id)) {
        subCategorySet.addAll(category.subCategories);
      }
    }

    final newList = subCategorySet.toList()..sort();
    // Kiểm tra xem sub-category đã chọn trước đó còn tồn tại trong list mới không
    if (_selectedSubCategory != null &&
        !newList.contains(_selectedSubCategory)) {
      _selectedSubCategory = null;
    }

    setState(() {
      _currentSubCategoryOptions = newList;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // Sửa hàm này để gọi đúng ProductService
  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Kiểm tra cả danh mục con
      if (_selectedCategoryIds.isEmpty || _selectedSubCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vui lòng chọn ít nhất một danh mục cha VÀ một danh mục con.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final data = {
        'name': _nameController.text,
        'description': _descController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'imageUrl': _imageUrlController.text,
        'categoryIds': _selectedCategoryIds, // Mảng các ID cha
        'subCategory': _selectedSubCategory!, // Tên danh mục con đã chọn
      };

      try {
        if (_isEditMode) {
          await _productService.updateProduct(widget.product!.id, data);
        } else {
          await _productService.addProduct(data);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // Thêm SnackBar(...)
            content: Text('Đã lưu sản phẩm thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Thêm SnackBar(...)
            content: Text('Lỗi khi lưu sản phẩm: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextFormField(
                      _nameController,
                      'Tên sản phẩm',
                      Icons.shopping_cart,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      _descController,
                      'Mô tả',
                      Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      _priceController,
                      'Giá tiền',
                      Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      _imageUrlController,
                      'Link hình ảnh',
                      Icons.image,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Chọn danh mục cha (có thể chọn nhiều):',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : _buildCategorySelection(), // Checkbox list

                    const SizedBox(height: 20),
                    Text(
                      'Chọn danh mục con (chỉ 1):',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSubCategory,
                      // Vô hiệu hóa nếu chưa chọn danh mục cha
                      onChanged: _currentSubCategoryOptions.isEmpty
                          ? null
                          : (String? newValue) {
                              setState(() {
                                _selectedSubCategory = newValue;
                              });
                            },
                      items: _currentSubCategoryOptions
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      decoration: InputDecoration(
                        labelText: 'Danh mục con',
                        icon: const Icon(Icons.style),
                        border: const OutlineInputBorder(),
                        // Hiển thị hint nếu chưa có gì
                        hintText: _selectedCategoryIds.isEmpty
                            ? 'Vui lòng chọn danh mục cha trước'
                            : 'Chọn loại sản phẩm',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn danh mục con';
                        }
                        return null;
                      },
                    ),

                    // -----------------------------------------
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        child: const Text('Lưu lại'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      // Bỏ Padding đi
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        icon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập $label';
        }
        if (label == 'Giá tiền' &&
            (double.tryParse(value) == null || double.parse(value) < 0)) {
          return 'Giá tiền không hợp lệ';
        }
        return null;
      },
    );
  }

  // Widget chọn danh mục
  Widget _buildCategorySelection() {
    if (_availableCategories.isEmpty) {
      return const Text('Không có danh mục nào. Vui lòng thêm danh mục trước.');
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _availableCategories.length,
        itemBuilder: (context, index) {
          final category = _availableCategories[index];
          final isSelected = _selectedCategoryIds.contains(category.id);

          return CheckboxListTile(
            title: Text(category.name),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedCategoryIds.add(category.id);
                } else {
                  _selectedCategoryIds.remove(category.id);
                }
                _updateSubCategoryOptions();
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }
}
