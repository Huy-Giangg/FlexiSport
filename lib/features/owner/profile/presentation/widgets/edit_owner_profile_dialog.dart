import 'package:flexisport_app/features/auth/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class EditOwnerProfileDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback onSaved;

  const EditOwnerProfileDialog({
    super.key,
    this.initialData,
    required this.onSaved,
  });

  static void show(BuildContext context, {Map<String, dynamic>? initialData, required VoidCallback onSaved}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditOwnerProfileDialog(
        initialData: initialData,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<EditOwnerProfileDialog> createState() => _EditOwnerProfileDialogState();
}

class _EditOwnerProfileDialogState extends State<EditOwnerProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final currentName = widget.initialData?['name']?.toString() ??
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        '';
    final currentPhone = widget.initialData?['phone']?.toString() ??
        user?.userMetadata?['phone'] as String? ??
        '';
    final currentEmail = user?.email ?? widget.initialData?['email']?.toString() ?? '';

    _nameController = TextEditingController(text: currentName);
    _phoneController = TextEditingController(text: currentPhone);
    _emailController = TextEditingController(text: currentEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // 1. Cập nhật bảng profiles
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'phone': phone,
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Cập nhật user metadata trong auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': name,
            'name': name,
            'phone': phone,
          },
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cập nhật thông tin chủ sân thành công!", style: GoogleFonts.lexend()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi lưu thông tin: $e", style: GoogleFonts.lexend()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Chỉnh sửa thông tin cá nhân",
                    style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email (Read only)
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: GoogleFonts.lexend(fontSize: 14, color: Colors.grey.shade600),
                decoration: InputDecoration(
                  labelText: "Email tài khoản",
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Full Name
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Họ và tên chủ sân *",
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorMaxLines: 2,
                  errorStyle: GoogleFonts.lexend(fontSize: 11.5),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Vui lòng nhập họ và tên";
                  }
                  if (val.trim().length < 2) {
                    return "Tên quá ngắn";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Số điện thoại liên hệ *",
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorMaxLines: 2,
                  errorStyle: GoogleFonts.lexend(fontSize: 11.5),
                ),
                validator: MyValidators.validatePhone,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Lưu thay đổi", style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
