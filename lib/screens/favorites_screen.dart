// lib/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/favorite_provider.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ProductService _productService = ProductService();
  final currencyFormatter = NumberFormat("#,###", "vi_VN");
  // Future để lấy chi tiết sản phẩm
  Future<List<Product>>? _favoriteProductsFuture;
  // Biến để lưu trữ danh sách ID hiện tại mà Future đang dùng, tránh gọi lại không cần thiết
  List<String> _currentFavIds = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tải lại Future *chỉ khi* danh sách ID yêu thích thực sự thay đổi
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
    ); // listen: true ở đây là cần thiết
    if (!const ListEquality().equals(
      _currentFavIds,
      favoriteProvider.favoriteIds,
    )) {
      print(
        "FavoritesScreen: Favorite IDs changed, reloading products.",
      ); // Log
      _currentFavIds = List.from(
        favoriteProvider.favoriteIds,
      ); // Cập nhật ID hiện tại
      if (_currentFavIds.isNotEmpty) {
        setState(() {
          // Cập nhật future trong setState
          _favoriteProductsFuture = _loadFavoriteProducts(_currentFavIds);
        });
      } else {
        setState(() {
          _favoriteProductsFuture = Future.value(
            [],
          ); // Đặt về rỗng nếu không còn yêu thích
        });
      }
    }
  }

  // Hàm lấy chi tiết sản phẩm (giữ nguyên cách lọc client-side)
  Future<List<Product>> _loadFavoriteProducts(List<String> ids) async {
    print(
      "FavoritesScreen: Loading details for ${ids.length} favorite products.",
    ); // Log
    // Lấy tất cả sản phẩm rồi lọc phía client
    final allProducts = await _productService.getAllProducts();
    final favoriteProds = allProducts.where((p) => ids.contains(p.id)).toList();
    print(
      "FavoritesScreen: Found ${favoriteProds.length} matching products.",
    ); // Log
    return favoriteProds;
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ lấy provider để dùng trong FutureBuilder và nút bấm, không cần listen ở đây
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm yêu thích')),
      body:
          favoriteProvider
              .isLoading // Hiển thị loading nếu provider đang tải ID ban đầu
          ? const Center(
              child: CircularProgressIndicator(
                key: ValueKey('provider_loading'),
              ),
            ) // Thêm key
          // Dùng _currentFavIds để kiểm tra thay vì favoriteProvider.favoriteIds trực tiếp
          : _currentFavIds.isEmpty
          ? const Center(child: Text('Bạn chưa có sản phẩm yêu thích nào.'))
          : FutureBuilder<List<Product>>(
              // Sử dụng future đã được quản lý trong didChangeDependencies
              future: _favoriteProductsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Quan trọng: Phải có key khác nhau để Flutter phân biệt
                  return const Center(
                    child: CircularProgressIndicator(
                      key: ValueKey('future_loading'),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  print(
                    "FavoritesScreen Future Error: ${snapshot.error}",
                  ); // Log lỗi Future
                  return Center(
                    child: Text(
                      'Lỗi tải sản phẩm yêu thích: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy thông tin sản phẩm yêu thích.'),
                  );
                }

                final favoriteProducts = snapshot.data!;

                // --- ĐÃ ĐIỀN ĐẦY ĐỦ CODE HIỂN THỊ CARD ---
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: favoriteProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final product = favoriteProducts[index];
                    final formattedPrice = currencyFormatter.format(
                      product.price,
                    );
                    // isFav luôn là true ở màn hình này, nhưng lấy lại cho chắc
                    final bool isFav = favoriteProvider.isFavorite(product.id);

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/details',
                          arguments: product,
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Cột hiển thị ảnh, tên, giá
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                    child: Image.network(
                                      product.imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.error),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 30,
                                      ), // Khoảng cách giữa tên và giá
                                      Text(
                                        '$formattedPrice ₫',
                                        style: const TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Nút thêm giỏ hàng
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: FloatingActionButton.small(
                                heroTag:
                                    'fav_add_cart_${product.id}', // Tag riêng cho màn fav
                                onPressed: () {
                                  cart.addItem(product, 1);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã thêm "${product.name}" vào giỏ hàng!',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                child: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Color.fromARGB(255, 64, 61, 61),
                                ),
                              ),
                            ),
                            // Nút yêu thích (để xóa)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons
                                            .favorite_border, // Dùng isFav để đảm bảo
                                  color: isFav ? Colors.red : Colors.grey,
                                ),
                                onPressed: () {
                                  favoriteProvider.toggleFavorite(product);
                                  // Không cần setState ở đây vì didChangeDependencies sẽ xử lý
                                },
                                tooltip: 'Xóa khỏi yêu thích',
                              ),
                            ),
                          ], // Đóng children Stack
                        ), // Đóng Stack
                      ), // Đóng Card
                    ); // Đóng GestureDetector
                  }, // Đóng itemBuilder
                ); // Đóng GridView.builder
                // ------------------------------------------
              }, // Đóng builder FutureBuilder
            ), // Đóng FutureBuilder
    ); // Đóng Scaffold
  } // Đóng build method

  // Bỏ hàm _buildProductCard_Fav đi vì đã tích hợp vào itemBuilder
} // Đóng class _FavoritesScreenState
