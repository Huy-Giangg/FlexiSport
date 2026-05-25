import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/auth/presentation/widgets/button_custom.dart';
import 'package:flexisport_app/features/auth/presentation/widgets/input_text_custom.dart';
import 'package:flexisport_app/features/auth/services/auth_services.dart';
import 'package:flexisport_app/features/auth/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _isLoading = false;
  bool _isobscure = true;
  bool _isobscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: Icon(Icons.arrow_back_ios_new),
        ),
      ),
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
                            "Bắt đầu hành trình chinh phục sân chơi của bạn.",
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputTextCustom(
                              hintext: "Nguyen Van A",
                              title: "Tên đầy đủ",
                              validator: MyValidators.validateFullName,
                              textEditingController: _nameController,
                            ),

                            const SizedBox(height: 12),

                            InputTextCustom(
                              hintext: "abc@gmail.com",
                              title: "Địa chỉ Email",
                              validator: MyValidators.validateEmail,
                              textEditingController: _emailController,
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

                            const SizedBox(height: 12),

                            Text(
                              "Nhập lại mật khẩu",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _passwordConfirmController,
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
                                      _isobscureConfirm = !_isobscureConfirm;
                                    });
                                  },
                                  icon: Icon(
                                    _isobscureConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                              obscureText: _isobscureConfirm,
                              validator: (value) =>
                                  MyValidators.validatePasswordConfirm(
                                    value,
                                    _passwordController.text,
                                  ),
                            ),

                            const SizedBox(height: 20),

                            ButtonCustom(
                              title: "Đăng Ký",
                              ontap: () {
                                _isLoading ? () {} : _handleRegister();
                              },
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Bạn đã có tài khoản? ",
                          style: TextStyle(color: AppColors.secondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/login');
                          },
                          child: const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
    ;
  }

  void _handleRegister() async {
    // 1. Kiểm tra Validation (các dòng chữ đỏ)
    if (_formKey.currentState!.validate()) {
      try {
        // Hiển thị loading (tùy chọn)
        setState(() {
          _isLoading = true;
        });

        // 2. Gọi hàm đăng ký từ AuthService
        final user = await _authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          // 3. Đăng ký thành công
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));

          // Chuyển hướng sang trang chủ hoặc trang đăng nhập
          context.go('/login');
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
}
