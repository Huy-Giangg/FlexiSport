import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEditCourtDialog extends StatefulWidget {
  final OwnerCourtEntity? court;
  final String defaultSportType;
  final Function({
    required String name,
    required double pricePerHour,
    String? sportType,
  }) onSave;

  const AddEditCourtDialog({
    super.key,
    this.court,
    required this.defaultSportType,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    OwnerCourtEntity? court,
    required String defaultSportType,
    required Function({
      required String name,
      required double pricePerHour,
      String? sportType,
    }) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditCourtDialog(
        court: court,
        defaultSportType: defaultSportType,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditCourtDialog> createState() => _AddEditCourtDialogState();
}

class _AddEditCourtDialogState extends State<AddEditCourtDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late String _selectedSportType;

  final List<String> _sportTypes = [
    'Pickleball',
    'Cầu lông',
    'Bóng đá',
    'Tennis',
    'Bóng rổ',
    'Bóng chuyền',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.court?.name ?? '');
    _priceController = TextEditingController(
      text: widget.court != null
          ? widget.court!.pricePerHour.toInt().toString()
          : '150000',
    );

    final rawSport = (widget.court?.sportType != null && widget.court!.sportType!.trim().isNotEmpty)
        ? widget.court!.sportType!.trim()
        : (widget.defaultSportType.trim().isNotEmpty ? widget.defaultSportType.trim() : 'Pickleball');

    _selectedSportType = rawSport;
    if (!_sportTypes.contains(_selectedSportType)) {
      _sportTypes.insert(0, _selectedSportType);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 150000.0;

      Navigator.of(context).pop();

      widget.onSave(
        name: name,
        pricePerHour: price,
        sportType: _selectedSportType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.court != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo drag handle
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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? "Chỉnh sửa sân con" : "Thêm sân con mới",
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tên sân
              Text(
                "Tên sân *",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Ví dụ: Sân Pickleball 1, Sân VIP...",
                  hintStyle: GoogleFonts.lexend(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.stadium_outlined, color: AppColors.primary),
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
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên sân';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Môn thể thao
              Text(
                "Môn thể thao *",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedSportType,
                style: GoogleFonts.lexend(fontSize: 14, color: AppColors.onBackground),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.sports_tennis_outlined, color: AppColors.primary),
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
                ),
                items: _sportTypes.toSet().map((sport) {
                  return DropdownMenuItem(
                    value: sport,
                    child: Text(sport),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSportType = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Giá thuê mỗi giờ
              Text(
                "Giá thuê mỗi giờ (VNĐ/giờ) *",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "150000",
                  hintStyle: GoogleFonts.lexend(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
                  suffixText: "đ/h",
                  suffixStyle: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryContainer,
                  ),
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
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập giá thuê';
                  }
                  final p = double.tryParse(val.replaceAll('.', '').replaceAll(',', '').trim());
                  if (p == null || p < 0) {
                    return 'Giá tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "Hủy",
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEditing ? "Lưu thay đổi" : "Thêm sân",
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
