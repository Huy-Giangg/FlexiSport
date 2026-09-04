import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/core/services/notification_service.dart';

class BookingCancelBottomSheet extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onSuccess;

  const BookingCancelBottomSheet({
    super.key,
    required this.booking,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> booking,
    required VoidCallback onSuccess,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingCancelBottomSheet(
        booking: booking,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<BookingCancelBottomSheet> createState() => _BookingCancelBottomSheetState();
}

class _BookingCancelBottomSheetState extends State<BookingCancelBottomSheet> {
  final List<String> _quickReasons = [
    'Thay đổi kế hoạch đột xuất',
    'Thời tiết xấu / mưa bão',
    'Đặt nhầm sân hoặc khung giờ',
    'Lý do cá nhân khác',
  ];

  final List<String> _bankList = [
    'MBBank (MB)',
    'Vietcombank (VCB)',
    'Techcombank (TCB)',
    'BIDV',
    'VietinBank (CTG)',
    'ACB',
    'VPBank',
    'TPBank',
    'Sacombank',
    'Ngân hàng khác',
  ];

  late String _selectedReason;
  late String _selectedBank;
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankHolderController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = _quickReasons.first;
    _selectedBank = _bankList.first;
    _bankHolderController.text = (widget.booking['customer_name']?.toString() ?? '').toUpperCase();
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    _bankAccountController.dispose();
    _bankHolderController.dispose();
    super.dispose();
  }

  DateTime? _getBookingStartDateTime(List slots, String openTime, String closeTime) {
    if (slots.isEmpty) return null;
    final String dateStr = slots.first['booking_date']?.toString() ?? '';
    if (dateStr.isEmpty) return null;

    final dateParts = dateStr.split('-');
    if (dateParts.length != 3) return null;
    final year = int.tryParse(dateParts[0]) ?? 0;
    final month = int.tryParse(dateParts[1]) ?? 0;
    final day = int.tryParse(dateParts[2]) ?? 0;

    int openH = 6;
    int openM = 0;
    final parts = openTime.split(':');
    if (parts.isNotEmpty) openH = int.tryParse(parts[0]) ?? 6;
    if (parts.length > 1) openM = int.tryParse(parts[1]) ?? 0;

    final baseMinutes = openH * 60 + openM;
    final List<int> indices = slots.map((s) => (s['slot_index'] as num?)?.toInt() ?? 0).toList();
    if (indices.isEmpty) return null;
    indices.sort();
    final minIdx = indices.first;

    final startMinutes = baseMinutes + minIdx * 30;
    final startH = startMinutes ~/ 60;
    final startM = startMinutes % 60;

    return DateTime(year, month, day, startH, startM);
  }

  String _formatTimeRange(List slots, String openTime) {
    if (slots.isEmpty) return 'Chưa chọn ca';

    int openH = 6;
    int openM = 0;
    final parts = openTime.split(':');
    if (parts.isNotEmpty) openH = int.tryParse(parts[0]) ?? 6;
    if (parts.length > 1) openM = int.tryParse(parts[1]) ?? 0;

    final baseMinutes = openH * 60 + openM;
    final List<int> indices = slots.map((s) => (s['slot_index'] as num?)?.toInt() ?? 0).toList();
    if (indices.isEmpty) return 'Chưa chọn ca';
    indices.sort();

    final firstSlot = indices.first;
    final lastSlot = indices.last;

    final startMinutes = baseMinutes + firstSlot * 30;
    final endMinutes = baseMinutes + (lastSlot + 1) * 30;

    final sH = (startMinutes ~/ 60).toString().padLeft(2, '0');
    final sM = (startMinutes % 60).toString().padLeft(2, '0');
    final eH = (endMinutes ~/ 60).toString().padLeft(2, '0');
    final eM = (endMinutes % 60).toString().padLeft(2, '0');

    return "$sH:$sM - $eH:$eM (${indices.length} ca)";
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatVND(double amount) {
    final String str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return "${buffer.toString()} đ";
  }

  void _showRefundPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Quy định hoàn tiền",
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
                "Chi tiết tỷ lệ và điều kiện hoàn tiền khi hủy đặt sân:",
                style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              _buildPolicyItem(
                title: "Hủy trước ≥ 24 giờ / Chờ duyệt",
                rate: "Hoàn 100%",
                color: const Color(0xFF16A34A),
                description: "Được hoàn trả 100% số tiền đã thanh toán vào tài khoản của bạn.",
              ),
              const SizedBox(height: 10),
              _buildPolicyItem(
                title: "Hủy từ 2h - 24h trước giờ chơi",
                rate: "Hoàn 50%",
                color: Colors.orange.shade800,
                description: "Áp dụng hoàn 50% tiền cọc/tiền sân để hỗ trợ chi phí vận hành cho cơ sở.",
              ),
              const SizedBox(height: 10),
              _buildPolicyItem(
                title: "Hủy sát giờ chơi (< 2 giờ)",
                rate: "Không hoàn (0%)",
                color: Colors.red.shade700,
                description: "Khóa hủy trực tuyến. Quý khách vui lòng liên hệ hotline cơ sở để được hỗ trợ.",
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: Colors.blue.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Thời gian xử lý: Tiền hoàn sẽ được hoàn về tài khoản trong 1-3 ngày làm việc.",
                        style: GoogleFonts.lexend(fontSize: 11, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Đã hiểu", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem({
    required String title,
    required String rate,
    required Color color,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rate,
                  style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelBooking(String finalReason, String venueName, double refundAmount) async {
    setState(() => _isLoading = true);
    final bookingId = widget.booking['id']?.toString() ?? '';

    // Xây dựng thông tin hoàn tiền chi tiết nếu có
    String fullReason = finalReason;
    if (refundAmount > 0 && _bankAccountController.text.trim().isNotEmpty) {
      final bankInfo = " | Hoàn ${_formatVND(refundAmount)} qua $_selectedBank - STK: ${_bankAccountController.text.trim()} - Chủ TK: ${_bankHolderController.text.trim().toUpperCase()}";
      fullReason = "$finalReason$bankInfo";
    }

    try {
      final supabase = Supabase.instance.client;

      // Cập nhật trạng thái đơn sang đã hủy và lưu lý do (giữ nguyên booking_slots để không mất thông tin ngày giờ, sân)

      // 2. Cập nhật trạng thái đơn sang đã hủy và cập nhật lý do
      try {
        await supabase.from('bookings').update({
          'status': 'cancelled',
          'cancellation_reason': fullReason,
        }).eq('id', bookingId);
      } catch (_) {
        try {
          await supabase.from('bookings').update({
            'status': 'cancelled',
            'note': fullReason,
          }).eq('id', bookingId);
        } catch (_) {
          await supabase.from('bookings').update({
            'status': 'cancelled',
          }).eq('id', bookingId);
        }
      }

      // 3. Gửi thông báo cục bộ tới người dùng (Khách hàng)
      try {
        await NotificationService.instance.showBookingCancelledNotification(
          bookingId: bookingId,
          venueName: venueName,
          reason: refundAmount > 0 ? "$finalReason (Dự kiến hoàn ${_formatVND(refundAmount)})" : finalReason,
          isCancelledByHost: false,
        );
      } catch (e) {
        debugPrint("Lỗi gửi thông báo hủy cho khách: $e");
      }

      // 4. Gửi thông báo đến Chủ sân (Owner) qua cơ sở dữ liệu nếu có
      try {
        final slots = widget.booking['booking_slots'] as List? ?? [];
        if (slots.isNotEmpty) {
          final venue = slots.first['courts']?['venues'];
          final ownerId = venue?['user_id'] ?? venue?['owner_id'];
          if (ownerId != null) {
            final shortId = bookingId.length >= 5 ? bookingId.substring(0, 5).toUpperCase() : bookingId;
            final customerName = widget.booking['customer_name']?.toString() ?? 'Khách hàng';
            await supabase.from('notifications').insert({
              'user_id': ownerId,
              'title': 'Đơn đặt sân đã bị hủy',
              'body': 'Khách $customerName đã hủy đơn #$shortId tại $venueName. Lý do: $finalReason',
              'type': 'booking_cancelled',
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      } catch (_) {
        // Bỏ qua nếu bảng notifications chưa cấu hình trigger
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Đã hủy lịch đặt sân thành công!",
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: const Color(0xFF006D38),
          ),
        );
      }
    } catch (e) {
      debugPrint("Lỗi khi hủy đơn: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi hủy lịch: $e", style: GoogleFonts.lexend()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status']?.toString() ?? 'pending';
    final slots = widget.booking['booking_slots'] as List? ?? [];
    final double totalAmount = (widget.booking['total_amount'] as num?)?.toDouble() 
        ?? (widget.booking['total_price'] as num?)?.toDouble() 
        ?? 0.0;

    String venueName = 'Sân thể thao';
    String venueAddress = 'Chưa cập nhật địa chỉ';
    String venuePhone = '0398508386';
    String courtName = 'Sân thể thao';
    String sportType = 'Thể thao';
    String openTime = '06:00';
    String closeTime = '22:00';
    String rawDateStr = '';

    if (slots.isNotEmpty) {
      final firstSlot = slots.first;
      rawDateStr = firstSlot['booking_date']?.toString() ?? '';
      final court = firstSlot['courts'];
      if (court != null) {
        courtName = court['name']?.toString() ?? courtName;
        final venue = court['venues'];
        if (venue != null) {
          venueName = venue['name']?.toString() ?? venueName;
          venueAddress = venue['address']?.toString() ?? venueAddress;
          venuePhone = venue['phone']?.toString() ?? venuePhone;
          sportType = venue['sports_type']?.toString() ?? sportType;
          openTime = venue['open_time']?.toString() ?? openTime;
          closeTime = venue['close_time']?.toString() ?? closeTime;
        }
      }
    }

    final bookingDateFormatted = _formatDate(rawDateStr);
    final timeRangeText = _formatTimeRange(slots, openTime);

    final startDateTime = _getBookingStartDateTime(slots, openTime, closeTime);
    final now = DateTime.now();

    double hoursUntilStart = 999;
    if (startDateTime != null) {
      hoursUntilStart = startDateTime.difference(now).inMinutes / 60.0;
    }

    final isPending = status == 'pending';
    final isTooLateToCancel = !isPending && hoursUntilStart < 2.0;

    // Tính toán số tiền được hoàn lại
    double refundPercentage = 1.0;
    String refundPolicyLabel = 'Hoàn 100%';
    String refundPolicyDesc = 'Hủy trước ≥ 24 giờ';
    Color refundColor = const Color(0xFF16A34A);

    if (isPending || hoursUntilStart >= 24.0) {
      refundPercentage = 1.0;
      refundPolicyLabel = 'Hoàn 100%';
      refundPolicyDesc = isPending ? 'Đơn đang chờ duyệt' : 'Hủy trước ≥ 24 giờ';
      refundColor = const Color(0xFF16A34A);
    } else if (hoursUntilStart >= 2.0) {
      refundPercentage = 0.5;
      refundPolicyLabel = 'Hoàn 50%';
      refundPolicyDesc = 'Hủy từ 2h - 24h trước giờ chơi';
      refundColor = Colors.orange.shade800;
    } else {
      refundPercentage = 0.0;
      refundPolicyLabel = '0%';
      refundPolicyDesc = 'Sát giờ chơi (< 2 giờ)';
      refundColor = Colors.red.shade700;
    }

    final double refundAmount = totalAmount * refundPercentage;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Hủy lịch đặt sân",
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. CARD CHI TIẾT SÂN & THỜI GIAN
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CHI TIẾT SÂN ĐẶT",
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
                      const Icon(Icons.stadium_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          venueName,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          venueAddress,
                          style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.sports_tennis_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        "$courtName ($sportType)",
                        style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(bookingDateFormatted, style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade800)),
                      const Spacer(),
                      const Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        timeRangeText,
                        style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. CARD CHI TIẾT TIỀN & SỐ TIỀN ĐƯỢC HOÀN LẠI
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (hoursUntilStart >= 24 || isPending) ? const Color(0xFFF0FDF4) : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (hoursUntilStart >= 24 || isPending) ? const Color(0xFFBBF7D0) : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "THÔNG TIN HOÀN TIỀN",
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (hoursUntilStart >= 24 || isPending) ? const Color(0xFF166534) : Colors.orange.shade900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _showRefundPolicyDialog(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: (hoursUntilStart >= 24 || isPending) ? const Color(0xFF166534) : Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: refundColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          refundPolicyLabel,
                          style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold, color: refundColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Tổng tiền đã thanh toán:", style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700)),
                      Text(
                        _formatVND(totalAmount),
                        style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Điều kiện áp dụng:", style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600)),
                      Text(
                        refundPolicyDesc,
                        style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Số tiền hoàn lại:",
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatVND(refundAmount),
                        style: GoogleFonts.lexend(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: refundColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TRƯỜNG HỢP SÁT GIỜ CHƠI (< 2 TIẾNG): KHÓA HỦY ONLINE
            if (isTooLateToCancel) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Không thể hủy online sát giờ chơi",
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Theo quy định của hệ thống, các ca đặt trong vòng 2 tiếng trước giờ bắt đầu không thể tự hủy trên ứng dụng để đảm bảo quyền lợi vận hành sân.",
                      style: GoogleFonts.lexend(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Vui lòng liên hệ trực tiếp số điện thoại/hotline của cơ sở để được hỗ trợ:",
                      style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: venuePhone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã sao chép SĐT cơ sở: $venuePhone", style: GoogleFonts.lexend()),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_rounded, color: Color(0xFF006D38), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Hotline sân: $venuePhone",
                              style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF006D38)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Đã hiểu & Đóng", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                ),
              ),
            ]
            // TRƯỜNG HỢP ĐỦ ĐIỀU KIỆN HỦY
            else ...[
              // 3. THÔNG TIN TÀI KHOẢN NHẬN TIỀN HOÀN (NẾU CÓ TIỀN HOÀN > 0)
              if (refundAmount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF006D38)),
                          const SizedBox(width: 8),
                          Text(
                            "THÔNG TIN NHẬN TIỀN HOÀN (1-3 ngày)",
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Dropdown Ngân hàng
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBank,
                            isExpanded: true,
                            style: GoogleFonts.lexend(fontSize: 13, color: Colors.black87),
                            items: _bankList.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBank = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Ô nhập Số tài khoản
                      TextField(
                        controller: _bankAccountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.lexend(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Nhập số tài khoản ngân hàng nhận tiền...",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          prefixIcon: const Icon(Icons.credit_card_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Ô nhập Tên chủ tài khoản
                      TextField(
                        controller: _bankHolderController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Tên chủ tài khoản (viết hoa không dấu)...",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4. LÝ DO HỦY ĐẶT SÂN
              Text(
                "LÝ DO HỦY ĐẶT SÂN",
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Danh sách chọn lý do
              ..._quickReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF006D38) : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? const Color(0xFF006D38) : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF006D38) : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              if (_selectedReason == 'Lý do cá nhân khác') ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _customReasonController,
                  maxLines: 2,
                  style: GoogleFonts.lexend(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Nhập lý do chi tiết của bạn...",
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Giữ lại đơn", style: GoogleFonts.lexend(color: Colors.grey.shade700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              final finalReason = _selectedReason == 'Lý do cá nhân khác' &&
                                      _customReasonController.text.trim().isNotEmpty
                                  ? _customReasonController.text.trim()
                                  : _selectedReason;
                              _handleCancelBooking(finalReason, venueName, refundAmount);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text("Xác nhận hủy", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
