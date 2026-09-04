import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';

class OwnerBookingCardWidget extends StatelessWidget {
  final OwnerBookingEntity booking;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const OwnerBookingCardWidget({
    super.key,
    required this.booking,
    required this.onTap,
    this.onConfirm,
    this.onMarkPaid,
    this.onComplete,
    this.onCancel,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF10B981); // Emerald
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'completed':
        return const Color(0xFF3B82F6); // Blue
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'pending':
        return 'Chờ duyệt';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getPaymentColor(String status) {
    if (booking.isCancelled || status == 'refunded' || status == 'cancelled') {
      return const Color(0xFF6B7280); // Màu xám trung tính cho đơn đã hủy/hoàn tiền
    }
    switch (status) {
      case 'paid':
      case 'completed':
        return const Color(0xFF059669);
      case 'deposit_paid':
        return const Color(0xFFD97706);
      case 'refunded':
        return const Color(0xFF6B7280);
      case 'unpaid':
      default:
        return const Color(0xFFDC2626);
    }
  }

  String _getPaymentText(String status) {
    if (booking.isCancelled || status == 'refunded' || status == 'cancelled') {
      return (booking.depositAmount > 0 || booking.isPaid) ? 'Đã hoàn tiền' : 'Đã hủy đơn';
    }
    switch (status) {
      case 'paid':
      case 'completed':
        return 'Đã thanh toán đủ';
      case 'deposit_paid':
        return 'Đã nhận cọc';
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'unpaid':
      default:
        return 'Chưa thanh toán';
    }
  }

  IconData _getSportIcon(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('pickleball')) return Icons.sports_tennis_rounded;
    if (s.contains('cầu lông') || s.contains('badminton')) return Icons.sports_tennis;
    if (s.contains('bóng đá') || s.contains('football')) return Icons.sports_soccer_rounded;
    if (s.contains('tennis')) return Icons.sports_tennis_outlined;
    if (s.contains('bóng rổ') || s.contains('basketball')) return Icons.sports_basketball_rounded;
    return Icons.stadium_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.effectiveStatus);
    final paymentColor = _getPaymentColor(booking.paymentStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: booking.isPending ? Colors.amber.shade200 : Colors.grey.shade200,
            width: booking.isPending ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Header Card: Khách hàng + Trạng thái đơn
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  // Avatar khách hàng
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: booking.customerAvatarUrl != null
                        ? NetworkImage(booking.customerAvatarUrl!)
                        : null,
                    child: booking.customerAvatarUrl == null
                        ? Text(
                            booking.customerName.isNotEmpty
                                ? booking.customerName.trim()[0].toUpperCase()
                                : 'K',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Tên khách hàng & SĐT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.customerName,
                          style: GoogleFonts.lexend(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              booking.customerPhone,
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Badge Trạng thái đơn
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(booking.effectiveStatus),
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // 2. Body Card: Sân, Ngày & Khung giờ
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    // Sân & Môn thể thao
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getSportIcon(booking.sportType),
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.courtName,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onBackground,
                            ),
                          ),
                        ),
                        // Badge thanh toán
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: paymentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getPaymentText(booking.paymentStatus),
                            style: GoogleFonts.lexend(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: paymentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Ngày & Giờ chơi
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          booking.bookingDate,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          booking.timeRangeText,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Footer: Tổng tiền, Cọc, Số tiền còn lại & Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  // Tiền
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Tổng tiền: ",
                              style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              _formatCurrency(booking.totalPrice),
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                        if (booking.depositAmount > 0 && booking.depositAmount < booking.totalPrice) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Còn lại: ${_formatCurrency(booking.remainingAmount)}",
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Nút thao tác nhanh
                  if (booking.isPending) ...[
                    OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 34),
                      ),
                      child: Text("Từ chối", style: GoogleFonts.lexend(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 34),
                        elevation: 0,
                      ),
                      child: Text("Duyệt đơn", style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ] else if (booking.isConfirmed) ...[
                    if (!booking.isPaid && onMarkPaid != null) ...[
                      OutlinedButton.icon(
                        onPressed: onMarkPaid,
                        icon: const Icon(Icons.check_circle_outline, size: 14),
                        label: Text("Đã thu đủ", style: GoogleFonts.lexend(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFF059669)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.sports_rounded, size: 14),
                      label: Text("Check-in", style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 32),
                        elevation: 0,
                      ),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline, size: 15, color: AppColors.primary),
                      label: Text("Chi tiết", style: GoogleFonts.lexend(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
