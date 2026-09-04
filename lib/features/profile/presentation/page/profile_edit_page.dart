import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/auth/utils/validators.dart';

class ProfileEditPage extends StatefulWidget {
  final User? user;
  const ProfileEditPage({super.key, required this.user});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedGender = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    if (widget.user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Điền sẵn email của tài khoản Auth
      _emailController.text = widget.user!.email ?? '';
      _nameController.text =
          widget.user!.userMetadata?['full_name'] as String? ??
          widget.user!.userMetadata?['name'] as String? ??
          '';

      // 2. Truy vấn dữ liệu bổ sung từ bảng profiles trên database
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.user!.id)
          .maybeSingle();

      if (data != null) {
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          _nameController.text = data['name'].toString();
        }
        _phoneController.text = data['phone']?.toString() ?? '';

        final birthYear = data['birth_year'] as int? ?? 0;
        if (birthYear > 0) {
          _selectedDate = DateTime(birthYear, 1, 1);
          _dateController.text = "01/01/$birthYear";
        }

        _selectedGender = data['gender']?.toString() ?? '';

        final heightVal = (data['height'] as num?)?.toDouble() ?? 0.0;
        _heightController.text = heightVal > 0 ? heightVal.toString() : '';

        final weightVal = (data['weight'] as num?)?.toDouble() ?? 0.0;
        _weightController.text = weightVal > 0 ? weightVal.toString() : '';
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin cá nhân: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006D38), // màu chủ đạo
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (widget.user == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': widget.user!.id,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'birth_year': _selectedDate?.year ?? 0,
        'gender': _selectedGender,
        'height': double.tryParse(_heightController.text.trim()) ?? 0.0,
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
      });

      // Cập nhật metadata trong Auth Session để đồng bộ tên hiển thị trên toàn ứng dụng (banner, card...)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _nameController.text.trim(),
            'name': _nameController.text.trim(),
          },
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true); // Trở về trang trước và báo cập nhật thành công
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu thông tin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryContainer,
                AppColors.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          "Chỉnh sửa thông tin cá nhân",
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
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
                        // 1. Tên đầy đủ
                        _buildFieldLabel("Tên đầy đủ", isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration(
                            hintText: "Nhập họ và tên",
                          ),
                          validator: null,
                        ),
                        const SizedBox(height: 16),

                        // 2. Số điện thoại
                        _buildFieldLabel("Số điện thoại", isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration(
                            hintText: "Nhập số điện thoại",
                            prefixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 12),
                                // Icon cờ Việt Nam (Hình tròn đỏ chứa ngôi sao vàng)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.yellow,
                                    size: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "+ 84",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 22,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          validator: MyValidators.validatePhone,
                        ),
                        const SizedBox(height: 16),

                        // 3. Email
                        _buildFieldLabel("Email", isRequired: false),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          enabled:
                              false, // Không cho phép sửa Email tài khoản chính
                          style: TextStyle(color: Colors.grey.shade600),
                          decoration: _buildInputDecoration(
                            hintText: "Email",
                            filledColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Ngày sinh & Giới tính
                        Row(
                          children: [
                            // Ngày sinh
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    "Ngày sinh",
                                    isRequired: true,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _dateController,
                                    readOnly: true,
                                    onTap: () => _selectDate(context),
                                    decoration: _buildInputDecoration(
                                      hintText: "Chọn ngày sinh",
                                      suffixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Chọn ngày sinh'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Giới tính
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    "Giới tính",
                                    isRequired: true,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedGender.isEmpty
                                        ? null
                                        : _selectedGender,
                                    hint: const Text(
                                      "Chọn giới tính",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    decoration: _buildInputDecoration(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: "Nam",
                                        child: Text("Nam"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Nữ",
                                        child: Text("Nữ"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Khác",
                                        child: Text("Khác"),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGender = value ?? '';
                                      });
                                    },
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Chọn giới tính'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 5. Chiều cao & Cân nặng
                        Row(
                          children: [
                            // Chiều cao
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    "Chiều cao (cm)",
                                    isRequired: false,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _heightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: _buildInputDecoration(
                                      hintText: "Nhập chiều cao",
                                    ),
                                    validator: MyValidators.validateHeight,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Cân nặng
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    "Cân nặng (kg)",
                                    isRequired: false,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _weightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: _buildInputDecoration(
                                      hintText: "Nhập cân nặng",
                                    ),
                                    validator: MyValidators.validateWeight,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Nút Huỷ
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF006D38),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Huỷ",
                        style: TextStyle(
                          color: Color(0xFF006D38),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Nút Lưu
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaving
                            ? Colors.grey.shade300
                            : AppColors.primary, // Nền xám như ảnh mẫu
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Lưu",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String labelText, {required bool isRequired}) {
    return RichText(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: " *",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? filledColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      fillColor: filledColor ?? Colors.white,
      filled: filledColor != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF006D38), width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }
}
