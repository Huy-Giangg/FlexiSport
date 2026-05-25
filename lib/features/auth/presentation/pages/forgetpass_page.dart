import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/auth/presentation/widgets/button_custom.dart';
import 'package:flexisport_app/features/auth/presentation/widgets/input_text_custom.dart';
import 'package:flexisport_app/features/auth/services/auth_services.dart';
import 'package:flexisport_app/features/auth/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgetpassPage extends StatefulWidget {
  const ForgetpassPage({super.key});

  @override
  State<ForgetpassPage> createState() => _ForgetpassPageState();
}

class _ForgetpassPageState extends State<ForgetpassPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
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
        title: Text(
          "Quên mật khẩu",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
          ),
        ),

        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: _isLoading,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vui lòng nhập địa chỉ email của bạn. Chúng tôi sẽ gửi hướng dẫn khôi phục mật khẩu.",

                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Form(
                          key: _formKey,
                          child: InputTextCustom(
                            hintext: "abc@gmail.com",
                            title: "Nhập email của bạn",
                            validator: MyValidators.validateEmail,
                            textEditingController: _emailController,
                          ),
                        ),

                        const SizedBox(height: 16),

                        ButtonCustom(
                          title: 'Tiếp tục',
                          ontap: () {
                            _isLoading? (){} : _handleResetPass();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 200),
                ],
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

  void _handleResetPass() async {
    // 1. Kiểm tra validation của ô nhập Email
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 2. Gọi hàm gửi email reset từ Service
        // Không cần kiểm tra 'user != null' vì hàm này chỉ thực hiện hành động gửi mail
        await _authService.resetPassword(_emailController.text.trim());

        // 3. Thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Liên kết đặt lại mật khẩu đã được gửi vào Email của bạn!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // 4. Chuyển hướng quay lại trang Login sau khi gửi thành công
          // Dùng GoRouter (context.go) hoặc Navigator tùy cấu trúc của bạn
          context.go('/login');
        }
      } catch (e) {
        // 5. Hiển thị lỗi (ví dụ: email không tồn tại)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        // 6. Tắt trạng thái loading
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
