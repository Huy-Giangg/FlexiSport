import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class BookingPolicyDialog extends StatefulWidget {
  const BookingPolicyDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BookingPolicyDialog(),
    );
  }

  @override
  State<BookingPolicyDialog> createState() => _BookingPolicyDialogState();
}

class _BookingPolicyDialogState extends State<BookingPolicyDialog> {
  int _depositPercent = 50;
  int _cancelHours = 12;

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
                    color: const Color(0xFFE2A62C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.policy_rounded, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Chính sách đặt & Hủy sân",
                    style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Cấu hình các điều kiện đặt lịch và hoàn hủy để bảo vệ quyền lợi của chủ sân.",
              style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // 1. Tỷ lệ cọc bắt buộc
            Text("Tỷ lệ tiền cọc tối thiểu", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [30, 50, 100].map((pct) {
                final isSelected = _depositPercent == pct;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text("$pct% tổng tiền", style: GoogleFonts.lexend(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                    ),
                    onSelected: (_) => setState(() => _depositPercent = pct),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 2. Thời gian hủy sân
            Text("Hủy lịch trước giờ chơi tối thiểu", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [6, 12, 24].map((hours) {
                final isSelected = _cancelHours == hours;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text("$hours tiếng", style: GoogleFonts.lexend(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF059669),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300),
                    ),
                    onSelected: (_) => setState(() => _cancelHours = hours),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 3. Quy định nội bộ mẫu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nội quy cơ sở:", style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
                  const SizedBox(height: 6),
                  Text("• Mang đúng giày thể thao đế mềm phù hợp cho mặt sân thi đấu.", style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text("• Giữ gìn vệ sinh chung, không hút thuốc hoặc mang đồ uống có cồn vào sân.", style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text("• Khách hàng có mặt trước 10 phút để nhận sân và làm thủ tục.", style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade700)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Đã lưu chính sách đặt & hủy sân!", style: GoogleFonts.lexend()),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text("Lưu chính sách", style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
