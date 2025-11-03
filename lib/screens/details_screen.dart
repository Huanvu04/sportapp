import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

/// Trang chi tiết hiển thị thông tin cụ thể của một sản phẩm
class DetailsScreen extends StatelessWidget {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu sản phẩm được truyền từ HomeScreen
    final product = ModalRoute.of(context)!.settings.arguments as Product;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        // Cho phép cuộn nếu nội dung quá dài
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Kéo dài các thành phần con
          children: [
            // Hình ảnh lớn của sản phẩm
            Image.network(product.imageUrl, fit: BoxFit.cover, height: 300),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Giá sản phẩm
                  Text(
                    currencyFormatter.format(product.price),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Mô tả sản phẩm
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ), // giãn dòng
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            // 1. Lấy CartProvider và gọi hàm addItem để thêm sản phẩm
            Provider.of<CartProvider>(context, listen: false).addItem(product);
            // 2. Ẩn SnackBar cũ nếu có để tránh chồng chéo
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            // 3. Hiển thị SnackBar mới với kiểu floating và nút hành động
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã thêm "${product.name}" vào giỏ hàng!'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'XEM',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/cart');
                  },
                ),
              ),
            );
          },
          // --- KẾT THÚC PHẦN CẬP NHẬT ---
          icon: const Icon(Icons.shopping_cart_outlined),
          label: const Text('Thêm vào giỏ hàng'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
