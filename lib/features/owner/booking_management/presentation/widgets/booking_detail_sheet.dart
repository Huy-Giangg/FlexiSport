import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/core/services/notification_service.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/providers/owner_booking_provider.dart';

class BookingDetailSheet extends StatelessWidget {
  final OwnerBookingEntity booking;
  final OwnerBookingProvider provider;

  const BookingDetailSheet({
    super.key,
    required this.booking,
    required this.provider,
  });

  static void show(BuildContext context, OwnerBookingEntity booking, OwnerBookingProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingDetailSheet(booking: booking, provider: provider),
    );
  }

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
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return const Color(0xFFEF4444);
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

  void _confirmCancel(BuildContext context) {
    String selectedReason = 'Khách liên hệ yêu cầu hủy đơn';
    final customReasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final quickReasons = [
      'Khách liên hệ yêu cầu hủy đơn',
      'Sân đang bảo trì / gặp sự cố',
      'Thời tiết xấu / mưa bão',
      'Lý do khác (Nhập chi tiết)',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Xác nhận hủy đơn",
                  style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hủy đơn đặt của khách \"${booking.customerName}\"? Khung giờ đã đặt (${booking.timeRangeText}) sẽ được giải phóng ngay lập tức.",
                  style: GoogleFonts.lexend(fontSize: 13, color: Colors.black87),
                ),
                if (booking.isPaid || booking.depositAmount > 0 || booking.totalPrice > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Chính sách: Chủ sân hủy đơn -> Khách hàng được HOÀN TIỀN 100% (${_formatCurrency(booking.depositAmount > 0 ? booking.depositAmount : booking.totalPrice)}).",
                            style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFF166534), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  "Lý do hủy đơn:",
                  style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                ...quickReasons.map((reason) {
                  final isSelected = selectedReason == reason;
                  return InkWell(
                    onTap: () {
                      setDialogState(() {
                        selectedReason = reason;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red.shade50 : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.red.shade400 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 16,
                            color: isSelected ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reason,
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.red.shade900 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (selectedReason == 'Lý do khác (Nhập chi tiết)') ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: customReasonController,
                    maxLines: 2,
                    style: GoogleFonts.lexend(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Nhập lý do cụ thể...",
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("Quay lại", style: GoogleFonts.lexend(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final rawReason = selectedReason == 'Lý do khác (Nhập chi tiết)' &&
                        customReasonController.text.trim().isNotEmpty
                    ? customReasonController.text.trim()
                    : selectedReason;
                final finalReason = "Chủ sân hủy: $rawReason (Hoàn 100%)";

                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Close sheet
                final success = await provider.cancelBooking(booking.id, finalReason);
                
                if (success) {
                  try {
                    await NotificationService.instance.showBookingCancelledNotification(
                      bookingId: booking.id,
                      venueName: booking.venueName,
                      reason: rawReason,
                      isCancelledByHost: true,
                    );
                  } catch (_) {}
                }

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? "Đã hủy đơn đặt sân thành công" : "Hủy đơn thất bại",
                      style: GoogleFonts.lexend(),
                    ),
                    backgroundColor: success ? AppColors.primary : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Hủy đơn", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final shortId = booking.id.length >= 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id;

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
            // Handle Bar
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

            // Header: Mã đơn + Nút đóng
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chi tiết đơn đặt sân",
                        style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            "Mã đơn: #$shortId",
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: booking.id));
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text("Đã sao chép mã đơn", style: GoogleFonts.lexend()),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.effectiveStatus).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getStatusColor(booking.effectiveStatus).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _getStatusText(booking.effectiveStatus),
                              style: GoogleFonts.lexend(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(booking.effectiveStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Thẻ thông tin khách hàng
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "THÔNG TIN KHÁCH HÀNG",
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
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
                      const SizedBox(width: 12),
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
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.customerPhone,
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Nút copy số điện thoại
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: booking.customerPhone));
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text("Đã sao chép SĐT: ${booking.customerPhone}", style: GoogleFonts.lexend()),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                        tooltip: "Sao chép SĐT",
                      ),
                    ],
                  ),
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Ghi chú: ${booking.notes}",
                              style: GoogleFonts.lexend(fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Thẻ thông tin sân & thời gian đặt
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CHI TIẾT SÂN & THỜI GIAN",
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.stadium_rounded, "Cơ sở", booking.venueName),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.sports_tennis_rounded, "Sân thi đấu", "${booking.courtName} (${booking.sportType})"),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.calendar_month_rounded, "Ngày đặt", booking.bookingDate),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.access_time_filled_rounded, "Khung giờ chơi", booking.timeRangeText),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.numbers_rounded, "Số ca (30p/ca)", "${booking.slotsCount} ca"),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Thẻ thông tin thanh toán
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "THÔNG TIN THANH TOÁN",
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Tổng tiền sân:", style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700)),
                      Text(
                        _formatCurrency(booking.totalPrice),
                        style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Tiền đã cọc / thanh toán:", style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700)),
                      Text(
                        _formatCurrency(booking.depositAmount),
                        style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (booking.isCancelled) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Trạng thái tiền:", style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700)),
                        Text(
                          booking.depositAmount > 0 || booking.isPaid ? "Đã hoàn tiền (Refunded)" : "Đã hủy đơn",
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Số tiền còn phải thu:", style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700)),
                        Text(
                          _formatCurrency(booking.remainingAmount),
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: booking.remainingAmount > 0 ? Colors.orange.shade800 : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            if (booking.isCancelled && booking.cancellationReason != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  "Lý do hủy đơn: ${booking.cancellationReason}",
                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.red.shade800),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 4. Thanh nút thao tác nghiệp vụ
            if (booking.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmCancel(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("Từ chối đơn", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final success = await provider.confirmBooking(booking.id);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success ? "Đã duyệt đơn đặt sân" : "Duyệt đơn thất bại", style: GoogleFonts.lexend()),
                            backgroundColor: success ? AppColors.primary : Colors.red,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("Duyệt đơn", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else if (booking.isConfirmed) ...[
              Row(
                children: [
                  if (!booking.isPaid) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final success = await provider.markAsPaid(booking.id);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(success ? "Đã cập nhật: Đã thu đủ tiền 100%" : "Thao tác thất bại", style: GoogleFonts.lexend()),
                              backgroundColor: success ? const Color(0xFF059669) : Colors.red,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFF059669)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text("Đã thu đủ tiền", style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final success = await provider.completeBooking(booking.id);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success ? "Đã check-in hoàn thành đơn" : "Thao tác thất bại", style: GoogleFonts.lexend()),
                            backgroundColor: success ? const Color(0xFF3B82F6) : Colors.red,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("Check-in hoàn thành", style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _confirmCancel(context),
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                  label: Text("Hủy đơn này", style: GoogleFonts.lexend(color: Colors.red, fontSize: 12)),
                ),
              ),
            ] else if (booking.isCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        booking.hasPassed
                            ? "Đơn đặt sân đã qua khung giờ chơi (Hoàn thành)"
                            : "Đơn đặt sân đã check-in hoàn thành",
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text("$label: ", style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade600)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onBackground),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
