// lib/screens/checkout_success_screen.dart

import 'package:flutter/material.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoàn tất')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Đặt hàng thành công!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Cảm ơn bạn đã mua hàng của shop.'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Quay về trang chủ, xóa hết các màn hình cũ trên stack
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false);
              },
              child: const Text('Tiếp tục mua sắm'),
            ),
          ],
        ),
      ),
    );
  }
}
