import 'package:flexisport_app/features/auth/presentation/widgets/button_custom.dart';
import 'package:flexisport_app/features/auth/presentation/widgets/input_text_custom.dart';
import 'package:flexisport_app/features/auth/services/auth_services.dart';
import 'package:flexisport_app/features/auth/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isobscure = true;

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: _isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    // Logo or App Name
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'FLEXISPORT',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: AppColors.onBackground,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            "Thể thao không giới hạn, đặt sân trong tầm tay.",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InputTextCustom(
                                  textEditingController: _emailController,
                                  hintext: "abc@gmail.com",
                                  title: "Địa chỉ Email",
                                  validator: MyValidators.validateEmail,
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  "Nhập mật khẩu",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppColors.outlineVariant,
                                      ),
                                    ),

                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppColors.outlineVariant,
                                      ),
                                    ),

                                    hintText: "***",

                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isobscure = !_isobscure;
                                        });
                                      },
                                      icon: Icon(
                                        _isobscure
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                    ),
                                  ),
                                  obscureText: _isobscure,
                                  validator: MyValidators.validatePassword,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                context.push('/forgetpass');
                              },
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          ButtonCustom(
                            title: "Đăng nhập",
                            ontap: _isLoading ? () {} : _handleLogin,
                          ),

                          const SizedBox(height: 30),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppColors.outlineVariant,
                                  thickness: 1,
                                ),
                              ),

                              const SizedBox(width: 16),

                              const Text(
                                "Đăng nhập bằng cách khác",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Divider(
                                  color: AppColors.outlineVariant,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                            children: [
                              GestureDetector(
                                onTap: () {
                                  ontap: _isLoading ? () {} : _handleGoogleSignIn();
                                },
                                child: Image.asset(
                                  "assets/images/auth/google.png",
                                  height: 40,
                                  width: 40,
                                ),
                              ),

                              GestureDetector(
                                onTap: () {
                                  print("Image clicked");
                                },
                                child: Image.asset(
                                  "assets/images/auth/phone.png",
                                  height: 40,
                                  width: 40,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Bạn chưa có tài khoản? ",
                          style: TextStyle(color: AppColors.secondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/register');
                          },
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(
                  0.5,
                ), // Làm tối màn hình (50% đen)
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green, // Màu của FlexiSport
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    // 1. Kiểm tra Validation (các dòng chữ đỏ)
    if (_formKey.currentState!.validate()) {
      try {
        // Hiển thị loading (tùy chọn)
        setState(() {
          _isLoading = true;
        });

        // 2. Gọi hàm đăng ký từ AuthService
        final user = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          // 3. Đăng nhập thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công!')),
          );

          // Chuyển hướng sang trang chủ hoặc trang đăng nhập
          context.go('/home');
        }
      } catch (e) {
        // 4. Hiển thị lỗi nếu Firebase trả về lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        // 2. Tắt trạng thái loading (luôn chạy dù lỗi hay không)
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
  try {
    setState(() {
      _isLoading = true;
    });

    final user = await AuthService().signInWithGoogle();

    if (user == null) {
      // Người dùng bấm cancel
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bạn đã hủy đăng nhập")),
      );
      return;
    }

    // ✅ Đăng nhập thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Xin chào ${user.displayName}!")),
    );

    context.push('/home');

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
}
