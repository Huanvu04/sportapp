import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// provider imports
import 'providers/cart_provider.dart';
import 'providers/favorite_provider.dart';
// models imports
import 'models/category_model.dart';
import 'models/product.dart';
// screens imports
import 'screens/cart_screen.dart';
import 'screens/checkout_success_screen.dart';
import 'screens/details_screen.dart';
import 'screens/home_wrapper_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/sub_categories_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/user_order_list_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/purchase_history_screen.dart';
import 'screens/checkout_screen.dart';
// admin imports
import 'admin/auth_wrapper.dart';
import 'admin/admin_wrapper.dart';
import 'admin/admin_category_list_screen.dart';
import 'admin/admin_add_edit_category_screen.dart';
import 'admin/admin_product_list_screen.dart';
import 'admin/admin_add_edit_product_screen.dart';
import 'admin/admin_order_list_screen.dart';
import 'admin/admin_statistics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      // <-- SỬA LẠI ĐỂ DÙNG MultiProvider
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(),
        ), // <-- THÊM FAVORITE PROVIDER
      ],
      child: const SportApp(),
    ),
  );
}

class SportApp extends StatelessWidget {
  const SportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Store',
      theme: ThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.deepPurple, width: 1.4),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        // Core
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/auth-wrapper': (context) => const AuthWrapper(),

        // User
        '/home': (context) => const HomeWrapperScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/sub-categories': (context) => const SubCategoriesScreen(),
        '/product-list': (context) => const ProductListScreen(),
        '/details': (context) => DetailsScreen(),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/checkout-success': (context) => CheckoutSuccessScreen(),
        '/user-orders': (context) => const UserOrderListScreen(),
        '/purchase-history': (context) => const PurchaseHistoryScreen(),
        '/favorites': (context) => const FavoritesScreen(),

        // Admin
        '/admin': (context) => const AdminWrapper(),
        '/admin-statistics': (context) => const AdminStatisticsScreen(),
        '/admin-orders': (context) => const AdminOrderListScreen(),

        // Admin Products (Sửa lỗi 'AdminAddEditProductScreen' undefined)
        '/admin-products': (context) => const AdminProductListScreen(),
        '/admin-add-edit-product': (context) {
          final product =
              ModalRoute.of(context)!.settings.arguments as Product?;
          return AdminAddEditProductScreen(product: product);
        },

        // Admin Categories (Sửa lỗi 'AdminAddEditCategoryScreen' not a function)
        '/admin-categories': (context) => const AdminCategoryListScreen(),
        '/admin-add-edit-category': (context) {
          final category =
              ModalRoute.of(context)!.settings.arguments as CategoryModel?;
          return AdminAddEditCategoryScreen(category: category);
        },
      },
    );
  }
}
