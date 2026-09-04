import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class PartnerSupportSheet extends StatelessWidget {
  const PartnerSupportSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PartnerSupportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
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
                child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                "Trung tâm hỗ trợ Đối tác Chủ sân",
                style: GoogleFonts.lexend(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            "Đội ngũ kỹ thuật và chuyên viên vận hành FlexiSport luôn sẵn sàng hỗ trợ 24/7.",
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          _buildContactTile(
            context,
            icon: Icons.phone_in_talk_rounded,
            color: const Color(0xFF10B981),
            title: "Tổng đài hỗ trợ đối tác",
            value: "1900 6868 (Nhánh 2)",
            actionText: "Sao chép",
          ),
          const SizedBox(height: 10),

          _buildContactTile(
            context,
            icon: Icons.chat_rounded,
            color: const Color(0xFF3B82F6),
            title: "Kênh Zalo Hỗ Trợ Chủ Sân",
            value: "0988 123 456 (Zalo CSKH)",
            actionText: "Sao chép",
          ),
          const SizedBox(height: 10),

          _buildContactTile(
            context,
            icon: Icons.mail_outline_rounded,
            color: const Color(0xFFF59E0B),
            title: "Email tiếp nhận khiếu nại & hợp tác",
            value: "partners@flexisport.vn",
            actionText: "Sao chép",
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Đã hiểu", style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String actionText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value.split(' ').first));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đã sao chép: $value", style: GoogleFonts.lexend())),
              );
            },
            child: Text(actionText, style: GoogleFonts.lexend(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
