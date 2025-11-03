import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sportapp/providers/favorite_provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final currencyFormatter = NumberFormat("#,###", "vi_VN");
  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = []; // Danh sách đầy đủ
  List<Product> _displayedProducts = []; // Danh sách để hiển thị (đã lọc)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
    // Thêm listener để tự động lọc khi gõ
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  // Tải tất cả sản phẩm về
  Future<void> _loadAllProducts() async {
    _allProducts = await _productService.getAllProducts();
    setState(() {
      _displayedProducts = _allProducts; // Ban đầu, hiển thị tất cả
      _isLoading = false;
    });
  }

  // Logic lọc sản phẩm
  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _displayedProducts = _allProducts; // Nếu ô tìm kiếm rỗng, hiện tất cả
      } else {
        // Lọc danh sách
        _displayedProducts = _allProducts.where((product) {
          return product.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0), // Thêm padding chung
              child: Column(
                children: [
                  // THANH TÌM KIẾM
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Tìm kiếm sản phẩm...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      // Thêm nút 'x' để xóa nhanh
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 17),

                  // LƯỚI SẢN PHẨM
                  Expanded(
                    child: _displayedProducts.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy sản phẩm nào.'),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: _displayedProducts.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.68,
                                ),
                            itemBuilder: (context, index) {
                              final product = _displayedProducts[index];
                              final favoriteProvider =
                                  Provider.of<FavoriteProvider>(context);
                              return _buildProductCard(
                                context,
                                product,
                                cart,
                                favoriteProvider,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // Hàm build card sản phẩm (giữ nguyên, đã có nút giỏ hàng)
  Widget _buildProductCard(
    BuildContext context,
    Product product,
    CartProvider cart,
    FavoriteProvider favoriteProvider,
  ) {
    // Lấy FavoriteProvider
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    // Kiểm tra xem sản phẩm này có yêu thích không
    final bool isFav = favoriteProvider.isFavorite(product.id);
    final formattedPrice = currencyFormatter.format(product.price);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/details', arguments: product);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias, // ✅ Quan trọng
        child: Stack(
          children: [
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
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 4,
                    bottom: 4,
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
                      const SizedBox(height: 30), // Khoảng cách giữa tên và giá
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
            // Nút Yêu thích
            Positioned(
              top: 4, // Góc trên bên phải
              right: 4,
              child: IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite
                      : Icons.favorite_border, // Đổi icon dựa trên isFav
                  color: isFav ? Colors.red : Colors.grey, // Đổi màu
                ),
                onPressed: () {
                  // Gọi hàm toggleFavorite từ provider
                  favoriteProvider.toggleFavorite(product);
                },
                // Có thể thêm tooltip
                tooltip: isFav ? 'Xóa khỏi yêu thích' : 'Thêm vào yêu thích',
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton.small(
                heroTag: 'home_add_cart_${product.id}',
                onPressed: () {
                  cart.addItem(product, 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm "${product.name}" vào giỏ hàng!'),
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
          ],
        ),
      ),
    );
  }
}
