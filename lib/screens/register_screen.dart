import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _authService = AuthService();

  void _handleAuthError(dynamic e) {
    String message = "Đã xảy ra lỗi. Vui lòng thử lại.";
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          message = 'Mật khẩu quá yếu.';
          break;
        case 'email-already-in-use':
          message = 'Email đã được sử dụng.';
          break;
        default:
          message = e.message ?? message;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _authService.registerWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        _handleAuthError(e);
      }
    }
  }

  Widget _buildRule(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isValid ? Colors.green : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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

              // Mật khẩu
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 8) {
                    return 'Mật khẩu phải có ít nhất 8 ký tự';
                  }
                  if (!RegExp(r'^[A-Z]').hasMatch(value)) {
                    return 'Chữ cái đầu phải viết hoa';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Mật khẩu phải chứa ít nhất 1 số';
                  }
                  return null;
                },
              ),
              // Checklist mật khẩu tự đổi màu
              const SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: _passwordController,
                builder: (context, value, child) {
                  final password = value.text;
                  final isLength = password.length >= 8;
                  final isUppercase = RegExp(r'^[A-Z]').hasMatch(password);
                  final isNumber = RegExp(r'[0-9]').hasMatch(password);

                  return Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRule("Ít nhất 8 ký tự", isLength),
                        _buildRule("Chữ cái đầu viết hoa", isUppercase),
                        _buildRule("Chứa ít nhất 1 số", isNumber),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Xác nhận mật khẩu
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    }),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Nút Đăng ký
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Đăng ký'),
                ),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đã có tài khoản? Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
