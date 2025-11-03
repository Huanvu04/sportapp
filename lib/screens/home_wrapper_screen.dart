import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'user_order_list_screen.dart';

class HomeWrapperScreen extends StatefulWidget {
  const HomeWrapperScreen({super.key});

  @override
  State<HomeWrapperScreen> createState() => _HomeWrapperScreenState();
}

class _HomeWrapperScreenState extends State<HomeWrapperScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(), // Cửa hàng
    const CategoriesScreen(), // Danh mục
    const UserOrderListScreen(), // Danh sách đơn hàng người dùng
    ProfileScreen(), // Tài khoản
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  String _getTitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return 'Cửa hàng';
      case 1:
        return 'Danh mục';
      case 2:
        return 'Đơn hàng của tôi';
      case 3:
        return 'Tài khoản';
      default:
        return 'Cửa hàng';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(context, _selectedIndex)),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (_, favProvider, ch) => IconButton(
              icon: Icon(
                favProvider.favoriteIds.isEmpty
                    ? Icons.favorite_border
                    : Icons.favorite,
                color: favProvider.favoriteIds.isEmpty ? null : Colors.red,
              ),
              tooltip: 'Yêu thích',
              onPressed: () {
                Navigator.of(context).pushNamed('/favorites');
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history), // Icon lịch sử
            tooltip: 'Lịch sử mua hàng',
            onPressed: () {
              Navigator.of(context).pushNamed('/purchase-history');
            },
          ),
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: ch,
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.of(context).pushNamed('/cart');
              },
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Cửa hàng'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Danh mục',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
