import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Import service mới

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;

  // Hàm xử lý lỗi (giữ nguyên, đã rất tốt)
  void _handleAuthError(dynamic e) {
    String message = "Đã xảy ra lỗi. Vui lòng thử lại.";

    if (e is FirebaseAuthException) {
      switch (e.code) {
        // ... (các case lỗi của bạn giữ nguyên)
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản này.';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không đúng.';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ.';
          break;
        default:
          if (e.message != null &&
              e.message!.contains('auth credential is incorrect')) {
            message = 'Email hoặc mật khẩu không hợp lệ.';
          } else {
            message =
                'Lỗi không xác định: ${e.message ?? 'Không rõ nguyên nhân.'}';
          }
      }
    }
    // Kiểm tra mounted trước khi hiển thị SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // Hàm điều hướng khi thành công
  void _navigateToHome() {
    // Kiểm tra mounted trước khi điều hướng
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ----- Gọi hàm đăng nhập từ service -----
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Đăng nhập Firebase
        print("LoginScreen: Attempting Firebase sign in...");
        await _authService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        print("LoginScreen: Firebase sign in successful.");

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print("LoginScreen: Error - User is null after sign in.");
          throw Exception("Không tìm thấy người dùng sau khi đăng nhập.");
        }
        print("LoginScreen: User found with UID: ${user.uid}");
        // Lấy role từ Firestore
        print("LoginScreen: Fetching user role from Firestore...");
        final userDocSnapshot = await _authService.getUserRole(user.uid);
        String role = 'user'; // Mặc định là user
        if (userDocSnapshot.exists && userDocSnapshot.data() != null) {
          final data = userDocSnapshot.data() as Map<String, dynamic>?;
          role = data?['role'] ?? 'user'; // Lấy role, nếu null thì là 'user'
          print("LoginScreen: Document found. Role is: $role");
        } else {
          print(
            "LoginScreen: Role document not found for UID. Defaulting to 'user'.",
          ); // Log 7
        }
        // Kiểm tra và điều hướng
        if (!mounted) return;
        print("LoginScreen: Navigating based on role: $role");
        if (role == 'admin') {
          print("LoginScreen: Navigating to /admin");
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          // user thường sẽ qua AuthWrapper để vào trang user
          print("LoginScreen: Navigating to /auth-wrapper");
          Navigator.pushReplacementNamed(context, '/auth-wrapper');
        }
      } catch (e) {
        print("LoginScreen: Error during login or role check: $e"); // Log Lỗi
        _handleAuthError(e);
      }
    }
  }

  // ----- Gọi hàm đăng nhập Google từ service -----
  Future<void> _signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      _navigateToHome();
    } catch (e) {
      _handleAuthError(e);
    }
  }

  // --- HÀM MỚI: GỬI EMAIL QUÊN MẬT KHẨU ---
  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email để khôi phục.')),
      );
      return;
    }

    try {
      // Gọi trực tiếp hàm của Firebase
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi link khôi phục. Vui lòng kiểm tra email.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Tái sử dụng hàm xử lý lỗi của bạn
      _handleAuthError(e);
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // ... (giữ nguyên validator của bạn)
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                // --- CẬP NHẬT 1: SỬ DỤNG BIẾN STATE ---
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  // Xóa const
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  // --- CẬP NHẬT 2: THÊM NÚT XEM/ẨN MẬT KHẨU ---
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  // ... (giữ nguyên validator của bạn)
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),

              // --- CẬP NHẬT 3: THÊM NÚT QUÊN MẬT KHẨU ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sendPasswordResetEmail,
                  child: const Text('Quên mật khẩu?'),
                ),
              ),

              // -----------------------------------------
              const SizedBox(height: 10), // Giảm khoảng cách một chút
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Tạo tài khoản mới (Đăng ký)'),
              ),
              const SizedBox(height: 25),
              // ... (Phần "HOẶC" và Đăng nhập Google giữ nguyên)
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('HOẶC'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset('assets/google_logo.png', height: 22),
                  label: const Text('Đăng nhập với Google'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
