import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/event_management/domain/entities/owner_event_entity.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/providers/owner_event_provider.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/widgets/add_edit_event_sheet.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/widgets/event_attendees_sheet.dart';

class OwnerEventCardWidget extends StatelessWidget {
  final OwnerEventEntity event;
  final String venueId;
  final List<OwnerCourtEntity> courts;
  final OwnerEventProvider provider;

  const OwnerEventCardWidget({
    super.key,
    required this.event,
    required this.venueId,
    required this.courts,
    required this.provider,
  });

  String _formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }

  String _formatDate(String dateStr) {
    try {
      final clean = dateStr.split('T')[0].split(' ')[0].trim();
      final parts = clean.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        final d = parsed.day.toString().padLeft(2, '0');
        final m = parsed.month.toString().padLeft(2, '0');
        return "$d/$m/${parsed.year}";
      }
    } catch (_) {}
    return dateStr;
  }

  void _confirmCancelAndRefund(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Hủy sự kiện & Hoàn vé?",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          "Bạn có chắc muốn hủy sự kiện '${event.title}' không? Toàn bộ các ô giờ của sự kiện trên lịch đặt sân sẽ được giải phóng ngay lập tức để khách khác đặt, và vé của người tham gia sẽ được chuyển sang trạng thái đã hủy/hoàn tiền.",
          style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Đóng", style: GoogleFonts.lexend(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await provider.cancelEvent(
                event.id,
                reason: 'Chủ sân hủy sự kiện do chưa đủ số lượng người đăng ký. Toàn bộ tiền vé đã được hoàn lại.',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Đã hủy sự kiện và giải phóng ô giờ thành công." : "Không thể hủy sự kiện."),
                    backgroundColor: success ? const Color(0xFF2E7D32) : Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text("Xác nhận hủy & Hoàn vé", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Xóa sự kiện?",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa sự kiện '${event.title}' không? Thao tác này không thể hoàn tác.",
          style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Hủy", style: GoogleFonts.lexend(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await provider.deleteEvent(event.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Đã xóa sự kiện thành công." : "Không thể xóa sự kiện."),
                    backgroundColor: success ? const Color(0xFF2E7D32) : Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text("Xóa vĩnh viễn", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPassed = event.hasPassed;
    final isSoldOut = event.isSoldOut;
    final isUnderbooked = event.isUnderbooked;
    final booked = event.bookedTicketsCount;
    final max = event.maxTickets > 0 ? event.maxTickets : 1;
    final progress = (booked / max).clamp(0.0, 1.0);

    // Status config
    String statusText = "Đang mở";
    Color statusBg = Colors.green.shade50;
    Color statusColor = Colors.green.shade700;

    if (!event.isActive) {
      statusText = "Đã hủy / Tạm ngưng";
      statusBg = Colors.red.shade50;
      statusColor = Colors.red.shade700;
    } else if (hasPassed) {
      statusText = "Đã kết thúc";
      statusBg = Colors.blueGrey.shade50;
      statusColor = Colors.blueGrey.shade700;
    } else if (isSoldOut) {
      statusText = "Đã hết vé";
      statusBg = Colors.orange.shade50;
      statusColor = Colors.orange.shade800;
    } else if (event.isWithinCancellationWindow && isUnderbooked) {
      statusText = "Cảnh báo thiếu người";
      statusBg = Colors.amber.shade50;
      statusColor = Colors.amber.shade900;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner or Header Strip
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: event.bannerUrl != null && event.bannerUrl!.isNotEmpty
                    ? Image.network(
                        event.bannerUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(),
                      )
                    : _buildFallbackBanner(),
              ),

              // Status Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),

              // Sport & Level Badges
              Positioned(
                bottom: 10,
                left: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sports_tennis_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            event.sportType,
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.level,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Actions Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (action) {
                        if (action == 'edit') {
                          AddEditEventSheet.show(
                            context,
                            event: event,
                            venueId: venueId,
                            courts: courts,
                            provider: provider,
                          );
                        } else if (action == 'toggle') {
                          provider.toggleEventStatus(event.id);
                        } else if (action == 'cancel') {
                          _confirmCancelAndRefund(context);
                        } else if (action == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text("Chỉnh sửa", style: GoogleFonts.lexend(fontSize: 13)),
                            ],
                          ),
                        ),
                        if (event.isActive)
                          PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_outlined, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text("Hủy sự kiện & Hoàn vé", style: GoogleFonts.lexend(fontSize: 13, color: Colors.orange.shade800)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                event.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                size: 18,
                                color: event.isActive ? Colors.orange : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                event.isActive ? "Tạm ngưng nhận vé" : "Mở lại nhận vé",
                                style: GoogleFonts.lexend(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Text("Xóa sự kiện", style: GoogleFonts.lexend(fontSize: 13, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date, Time & Court
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(event.eventDate),
                      style: GoogleFonts.lexend(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      "${event.startTime} - ${event.endTime}",
                      style: GoogleFonts.lexend(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.stadium_outlined, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.courtName,
                        style: GoogleFonts.lexend(fontSize: 12, color: AppColors.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Ticket Sales Progress Bar & Min Tickets Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Đã bán: $booked / ${event.maxTickets} vé (Tối thiểu: ${event.minTickets} vé)",
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        Text(
                          _formatCurrency(event.ticketPrice),
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0
                              ? Colors.orange
                              : (progress > 0.7 ? const Color(0xFF0288D1) : AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),

                // Cảnh báo nếu chưa đủ người trước 2 tiếng
                if (event.isActive && !hasPassed && event.isWithinCancellationWindow && isUnderbooked) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE65100)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Chưa đạt tối thiểu (${event.bookedTicketsCount}/${event.minTickets} vé). Sẽ tự động hủy trước 2h thi đấu.",
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Bottom Action: View Attendees Sheet
                InkWell(
                  onTap: () => EventAttendeesSheet.show(context, event: event, provider: provider),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_rounded, color: Color(0xFF0288D1), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Xem người tham gia (${event.attendeesCount} lượt đặt)",
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0288D1),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Thu: ${_formatCurrency(event.totalRevenue)}",
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      ],
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

  Widget _buildFallbackBanner() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF0288D1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.sports_tennis_rounded, size: 40, color: Colors.white.withOpacity(0.35)),
      ),
    );
  }
}
