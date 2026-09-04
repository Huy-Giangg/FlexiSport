import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourtCardWidget extends StatelessWidget {
  final OwnerCourtEntity court;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback onViewDetail;
  final VoidCallback? onOpenSchedule;

  const CourtCardWidget({
    super.key,
    required this.court,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onViewDetail,
    this.onOpenSchedule,
  });

  String _formatPrice(double price) {
    final intPrice = price.toInt();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = intPrice.toString().replaceAllMapped(regex, (Match m) => '${m[1]}.');
    return "$formatted đ/h";
  }

  IconData _getSportIcon(String? sportType) {
    final s = sportType?.toLowerCase() ?? '';
    if (s.contains('pickleball')) return Icons.sports_tennis_rounded;
    if (s.contains('cầu lông') || s.contains('badminton')) return Icons.sports_tennis;
    if (s.contains('bóng đá') || s.contains('football')) return Icons.sports_soccer_rounded;
    if (s.contains('tennis')) return Icons.sports_tennis_outlined;
    if (s.contains('bóng rổ') || s.contains('basketball')) return Icons.sports_basketball_rounded;
    return Icons.stadium_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = court.isActive;
    final sportType = court.sportType ?? 'Thể thao';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.grey.shade200 : Colors.orange.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header card: Tên sân, Thể thao, Trạng thái (Đã bỏ nút 3 chấm)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon thể thao với nền tròn
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryLightBg
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getSportIcon(court.sportType),
                    color: isActive ? AppColors.primary : Colors.orange.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Tên sân & Tag môn thể thao
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              court.name,
                              style: GoogleFonts.lexend(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge trạng thái
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive ? Colors.green.shade200 : Colors.orange.shade200,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.shade600 : Colors.orange.shade700,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? "Hoạt động" : "Bảo trì",
                                  style: GoogleFonts.lexend(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.green.shade700 : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sportType,
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "•",
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatPrice(court.pricePerHour),
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Body: Thống kê đặt sân & Khóa giờ trong ngày
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Đã đặt hôm nay
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Đã đặt",
                                style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey.shade600),
                              ),
                              Text(
                                "${court.todayBookingsCount} khung giờ",
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Đã khóa / Bảo trì
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lock_clock_rounded,
                            size: 16,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Khóa bảo trì",
                                style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey.shade600),
                              ),
                              Text(
                                "${court.todayBlockedCount} khung giờ",
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer Action Buttons: [ Nút Bảo trì / Mở lại ] & [ Nút Xem chi tiết & Cấu hình ]
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                // Nút Bảo trì / Mở lại nhanh ngoài card
                OutlinedButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    isActive ? Icons.build_circle_outlined : Icons.play_circle_outline_rounded,
                    size: 16,
                    color: isActive ? const Color(0xFFED6C02) : const Color(0xFF2E7D32),
                  ),
                  label: Text(
                    isActive ? "Bảo trì" : "Mở lại",
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? const Color(0xFFED6C02) : const Color(0xFF2E7D32),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    side: BorderSide(
                      color: isActive ? Colors.orange.shade300 : Colors.green.shade400,
                      width: 1,
                    ),
                    backgroundColor: isActive ? Colors.orange.shade50 : Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Nút Xem chi tiết & Cấu hình
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: onViewDetail,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        "Xem chi tiết & Cấu hình",
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLightBg,
                        foregroundColor: AppColors.primaryContainer,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFD4E8DC), width: 1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
