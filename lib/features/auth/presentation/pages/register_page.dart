import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/auth/presentation/widgets/button_custom.dart';
import 'package:flexisport_app/features/auth/presentation/widgets/input_text_custom.dart';
import 'package:flexisport_app/features/auth/services/auth_services.dart';
import 'package:flexisport_app/features/auth/utils/validators.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/customer/booking/presentation/providers/booking_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  // 0: Khách hàng (customer), 1: Chủ sân (owner)
  int _selectedRoleIndex = 0;

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
          icon: const Icon(Icons.arrow_back_ios_new),
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

                          Text(
                            _selectedRoleIndex == 0
                                ? "Bắt đầu hành trình chinh phục sân chơi của bạn."
                                : "Đăng ký tài khoản Chủ sân để quản lý cụm sân thể thao.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tab bar chuyển đổi giữa Khách hàng và Chủ sân
                    Row(
                      children: [
                        _buildTabButton(
                          index: 0,
                          title: 'Khách hàng',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(width: 8),
                        _buildTabButton(
                          index: 1,
                          title: 'Chủ sân',
                          icon: Icons.storefront_outlined,
                        ),
                      ],
                    ),

                    // Container Form Đăng ký
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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

                            const Text(
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

                            const Text(
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

                            const SizedBox(height: 24),

                            ButtonCustom(
                              title: _selectedRoleIndex == 0
                                  ? "Đăng Ký Khách Hàng"
                                  : "Đăng Ký Chủ Sân",
                              ontap: () {
                                _isLoading ? null : _handleRegister();
                              },
                            ),

                            const SizedBox(height: 16),
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
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final bool isSelected = _selectedRoleIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedRoleIndex != index) {
          setState(() {
            _selectedRoleIndex = index;
            _formKey.currentState?.reset();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          border: isSelected
              ? Border.all(color: AppColors.outlineVariant, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRegister() async {
    // 1. Kiểm tra Validation (các dòng chữ đỏ)
    if (_formKey.currentState!.validate()) {
      try {
        // Hiển thị loading
        setState(() {
          _isLoading = true;
        });

        final role = _selectedRoleIndex == 0 ? 'customer' : 'owner';

        // 2. Gọi hàm đăng ký từ AuthService với Role
        final user = await _authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: role,
        );

        if (user != null) {
          if (role == 'customer') {
            // Đồng bộ lịch đặt vãng lai sang tài khoản mới đăng ký
            await BookingSyncService.syncGuestBookings(user.id);
          }

          // 3. Đăng ký thành công
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  role == 'owner'
                      ? 'Đăng ký tài khoản Chủ sân thành công!'
                      : 'Đăng ký tài khoản Khách hàng thành công!',
                ),
                backgroundColor: AppColors.primary,
              ),
            );

            if (role == 'customer') {
              // Chuyển hướng sang trang chủ người dùng và hiện navbar
              context.read<MainPageProvider>().showNavbar();
              context.go('/home');
            } else {
              // Tài khoản chủ sân chuyển tới trang chủ
              context.go('/dashboard');
            }
          }
        }
      } catch (e) {
        // 4. Hiển thị lỗi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        // 5. Tắt trạng thái loading
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
