import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexisport_app/features/owner/profile/presentation/widgets/booking_policy_dialog.dart';
import 'package:flexisport_app/features/owner/profile/presentation/widgets/change_password_dialog.dart';

class OwnerSettingsSheet extends StatefulWidget {
  const OwnerSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const OwnerSettingsSheet(),
    );
  }

  @override
  State<OwnerSettingsSheet> createState() => _OwnerSettingsSheetState();
}

class _OwnerSettingsSheetState extends State<OwnerSettingsSheet> {
  bool _orderNotifications = true;
  bool _soundAlert = true;
  final String _selectedLanguage = "Tiếng Việt";

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                  color: const Color(0xFF006D38).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_outlined, color: Color(0xFF006D38), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                "Cài đặt hệ thống",
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B1C19),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nhóm thông báo
          Text(
            "Thông báo & Âm thanh",
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _orderNotifications,
                  activeTrackColor: const Color(0xFF006D38),
                  title: Text(
                    "Thông báo đơn đặt sân mới",
                    style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    "Nhận chuông và popup khi có khách đặt",
                    style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  onChanged: (val) => setState(() => _orderNotifications = val),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                SwitchListTile.adaptive(
                  value: _soundAlert,
                  activeTrackColor: const Color(0xFF006D38),
                  title: Text(
                    "Âm thanh cảnh báo",
                    style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    "Phát âm chuông khi phát sinh đơn thanh toán cọc",
                    style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  onChanged: (val) => setState(() => _soundAlert = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nhóm bảo mật & Chính sách
          Text(
            "Bảo mật & Chính sách vận hành",
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: Color(0xFF006D38), size: 20),
                  title: Text("Đổi mật khẩu tài khoản", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.of(context).pop();
                    ChangePasswordDialog.show(context);
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: const Icon(Icons.policy_outlined, color: Color(0xFF006D38), size: 20),
                  title: Text("Chính sách đặt cọc & Hủy sân", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.of(context).pop();
                    BookingPolicyDialog.show(context);
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: Color(0xFF006D38), size: 20),
                  title: Text("Ngôn ngữ hiển thị", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w500)),
                  trailing: Text(_selectedLanguage, style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
