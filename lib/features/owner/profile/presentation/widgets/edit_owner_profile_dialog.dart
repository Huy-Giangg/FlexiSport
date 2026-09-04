import 'package:flutter/material.dart';
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

    _nameController = TextEditingController(text: currentName);
    _phoneController = TextEditingController(text: currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
            content: Text("Cập nhật thông tin thành công!", style: GoogleFonts.lexend()),
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

              TextFormField(
                controller: _nameController,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Họ và tên *",
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Vui lòng nhập họ tên" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Số điện thoại *",
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Vui lòng nhập số điện thoại" : null,
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
