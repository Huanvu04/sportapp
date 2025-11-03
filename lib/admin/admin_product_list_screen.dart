import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _productsFuture;
  final currencyFormatter = NumberFormat("#,###", "vi_VN");

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Bắt đầu tải sản phẩm
  }

  // Hàm tải lại danh sách sản phẩm
  void _loadProducts() {
    setState(() {
      _productsFuture = _productService.getAllProducts();
    });
  }

  // Hàm xử lý xóa sản phẩm
  Future<void> _deleteProduct(String productId, String productName) async {
    // Hiển thị dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "$productName"?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    // Nếu người dùng xác nhận xóa
    if (confirm == true) {
      try {
        await _productService.deleteProduct(productId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa sản phẩm "$productName"!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadProducts(); // Tải lại danh sách sau khi xóa
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa sản phẩm: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Hàm điều hướng đến trang thêm/sửa
  void _navigateToAddEditScreen(Product? product) {
    Navigator.pushNamed(
      context,
      '/admin-add-edit-product',
      arguments: product, // Truyền sản phẩm (null nếu là thêm mới)
    ).then((_) => _loadProducts()); // Tải lại danh sách sau khi quay về
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Sản phẩm')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải sản phẩm: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm nào.'));
          }

          final products = snapshot.data!;
          // Hiển thị danh sách sản phẩm
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final formattedPrice = currencyFormatter.format(product.price);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Image.network(
                    product.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        const Icon(Icons.image_not_supported),
                  ),
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('$formattedPrice ₫'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Sửa',
                        onPressed: () => _navigateToAddEditScreen(product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Xóa',
                        onPressed: () =>
                            _deleteProduct(product.id, product.name),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToAddEditScreen(
                    product,
                  ), // Nhấn vào item cũng là sửa
                ),
              );
            },
          );
        },
      ),
      // Nút thêm mới sản phẩm
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(null), // null = thêm mới
        tooltip: 'Thêm sản phẩm',
        child: const Icon(Icons.add),
      ),
    );
  }
}
