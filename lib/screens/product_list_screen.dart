import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _productsFuture;
  final ProductService _productService = ProductService();
  String appBarTitle = 'Sản phẩm';
  final currencyFormatter = NumberFormat("#,###", "vi_VN");

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;

    // Kiểm tra xem arguments có tồn tại và có 'categoryId' không
    if (args != null && args.containsKey('categoryId')) {
      final categoryId = args['categoryId']!;
      final categoryName = args['categoryName'] ?? 'Danh mục';
      final subCategoryName = args['subCategoryName'] ?? 'Sản phẩm';

      print(
        "ProductListScreen: Received categoryId: $categoryId, categoryName: $categoryName, subCategoryName: $subCategoryName",
      ); // Log arguments

      // Gọi hàm lọc theo categoryId
      _productsFuture = _productService.getFilteredProducts(
        categoryId,
        subCategoryName,
      );

      // Cập nhật title cho AppBar
      appBarTitle = '$subCategoryName - $categoryName';
    } else {
      // Trường hợp không nhận được arguments hợp lệ
      print(
        "ProductListScreen Error: Invalid or missing arguments received.",
      ); // Log lỗi
      _productsFuture = Future.value([]); // Trả về danh sách rỗng
      appBarTitle = 'Lỗi'; // Hiển thị lỗi trên AppBar
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy các provider
    final cart = Provider.of<CartProvider>(context, listen: false);
    // listen: true để icon ❤️ cập nhật
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Hiển thị lỗi, đặc biệt là lỗi thiếu Index
            return Center(
              child: Text(
                'Lỗi tải sản phẩm: ${snapshot.error}. \n\nQUAN TRỌNG: Hãy kiểm tra Debug Console để xem link tạo Index trên Firestore (nếu có).',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('Chưa có sản phẩm nào thuộc mục "$appBarTitle".'),
            );
          }

          final products = snapshot.data!;

          // Hiển thị lưới sản phẩm
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7, // Dùng tỉ lệ 0.7 cho card cao hơn
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              // Gọi hàm helper để build card
              return _buildProductCard(
                context,
                product,
                cart,
                favoriteProvider,
              );
            },
          );
        },
      ),
    );
  }

  // Hàm helper để xây dựng Card sản phẩm (bao gồm cả nút Giỏ hàng và Yêu thích)
  Widget _buildProductCard(
    BuildContext context,
    Product product,
    CartProvider cart,
    FavoriteProvider favoriteProvider,
  ) {
    final formattedPrice = currencyFormatter.format(product.price);
    final bool isFav = favoriteProvider.isFavorite(product.id);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/details', arguments: product);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Cột nội dung (Ảnh, Tên, Giá)
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
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.error));
                      },
                    ),
                  ),
                ),
                Padding(
                  // Thêm padding đáy 48px để chừa chỗ cho nút Giỏ hàng
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 4,
                    bottom: 48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 8), // Khoảng cách giữa tên và giá
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

            // Nút Thêm giỏ hàng
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton.small(
                heroTag:
                    'list_add_cart_${product.id}', // Tag riêng cho màn hình này
                onPressed: () {
                  cart.addItem(product, 1); // Thêm số 1
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm "${product.name}" vào giỏ hàng!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
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

            // Nút Yêu thích
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  favoriteProvider.toggleFavorite(product);
                },
                tooltip: isFav ? 'Xóa khỏi yêu thích' : 'Thêm vào yêu thích',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
