import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/services/notification_service.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';
import 'package:flexisport_app/features/customer/booking/presentation/providers/booking_provider.dart';

class EventPaymentConfirmPage extends StatefulWidget {
  final EventEntity event;
  final int ticketCount;
  final double totalAmount;
  final String name;
  final String phone;
  final String note;

  const EventPaymentConfirmPage({
    super.key,
    required this.event,
    required this.ticketCount,
    required this.totalAmount,
    required this.name,
    required this.phone,
    required this.note,
  });

  @override
  State<EventPaymentConfirmPage> createState() =>
      _EventPaymentConfirmPageState();
}

class _EventPaymentConfirmPageState extends State<EventPaymentConfirmPage> {
  Timer? _countdownTimer;
  Timer? _statusCheckTimer;
  StreamSubscription? _realtimeSubscription;

  int _secondsRemaining = 300; // 5 minutes payment limit
  String _userId = '';

  bool _isLoading = true;
  String _errorMessage = '';

  // State variables for payment session
  String? _bookingId;
  String? _paymentReference;
  String? _vietQRUrl;

  // Merchant Bank Configuration (matching regular court booking)
  final String _bankId = 'MBBank';
  final String _accountNumber = '0354676200';
  final String _accountName = 'NGUYEN HUY GIANG';

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest_user';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeBookingTransaction();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusCheckTimer?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  /// Generates the VietQR Quick Link URL
  String _generateVietQRUrl({
    required String bankId,
    required String accountNumber,
    required String accountName,
    required double amount,
    required String reference,
  }) {
    final cleanName = Uri.encodeComponent(accountName);
    final cleanRef = Uri.encodeComponent(reference);
    final intAmount = amount.toInt();

    return 'https://img.vietqr.io/image/$bankId-$accountNumber-compact.png'
        '?amount=$intAmount'
        '&addInfo=$cleanRef'
        '&accountName=$cleanName';
  }

  /// Step 1: Create pending event booking and initialize VietQR code
  Future<void> _initializeBookingTransaction() async {
    try {
      // If free event (0đ), immediately complete booking
      if (widget.totalAmount <= 0) {
        final Map<String, dynamic> bookingData = {
          'event_id': widget.event.id,
          'user_id': _userId == 'guest_user' ? null : _userId,
          'ticket_count': widget.ticketCount,
          'total_amount': 0.0,
          'status': 'completed',
          'customer_name': widget.name,
          'customer_phone': widget.phone,
          'note': widget.note,
        };

        final booking = await context
            .read<BookingProvider>()
            .registerEvent(bookingData);

        if (_userId == 'guest_user') {
          final prefs = await SharedPreferences.getInstance();
          final List<String> guestBookings =
              prefs.getStringList('guest_event_booking_ids') ?? [];
          guestBookings.add(booking.id);
          await prefs.setStringList('guest_event_booking_ids', guestBookings);
        }

        _bookingId = booking.id;
        _checkBookingStatus('completed');
        return;
      }

      // Generate unique transaction reference in format FLEXI + 8 hex chars (e.g. FLEXI4938B80F)
      final timeHex = DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
      final microHex = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toRadixString(16).toUpperCase();
      final combo = timeHex + microHex;
      final hex8 = combo.substring(combo.length - 8);
      final refCode = 'FLEXI$hex8';

      final noteWithRef = widget.note.trim().isNotEmpty
          ? '${widget.note.trim()} [Mã GD: $refCode]'
          : 'Mã GD: $refCode';

      final Map<String, dynamic> bookingData = {
        'event_id': widget.event.id,
        'user_id': _userId == 'guest_user' ? null : _userId,
        'ticket_count': widget.ticketCount,
        'total_amount': widget.totalAmount,
        'status': 'pending', // Pending payment
        'customer_name': widget.name,
        'customer_phone': widget.phone,
        'note': noteWithRef,
      };

      final booking = await context
          .read<BookingProvider>()
          .registerEvent(bookingData);

      // Save guest booking ID locally if applicable
      if (_userId == 'guest_user') {
        final prefs = await SharedPreferences.getInstance();
        final List<String> guestBookings =
            prefs.getStringList('guest_event_booking_ids') ?? [];
        guestBookings.add(booking.id);
        await prefs.setStringList('guest_event_booking_ids', guestBookings);
      }

      // Generate VietQR Link
      final qrUrl = _generateVietQRUrl(
        bankId: _bankId,
        accountNumber: _accountNumber,
        accountName: _accountName,
        amount: widget.totalAmount,
        reference: refCode,
      );

      if (!mounted) return;
      setState(() {
        _bookingId = booking.id;
        _paymentReference = refCode;
        _vietQRUrl = qrUrl;
        _isLoading = false;
      });

      // Start 5-minute timer & subscribe to Realtime updates
      _startTimer();
      _subscribeToRealtimePaymentStatus(booking.id);
    } catch (e) {
      debugPrint("Lỗi khởi tạo giao dịch vé sự kiện: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  /// Step 2: Start 5-minute countdown
  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (!mounted) return;
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onTimerExpired();
      }
    });
  }

  /// Step 3: Listen to Supabase Realtime changes and poll periodically
  void _subscribeToRealtimePaymentStatus(String bookingId) {
    _realtimeSubscription?.cancel();
    _statusCheckTimer?.cancel();

    // 1. Supabase Realtime stream
    _realtimeSubscription = Supabase.instance.client
        .from('event_bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .listen(
          (List<Map<String, dynamic>> data) {
            if (data.isNotEmpty) {
              final booking = data.first;
              final String status = booking['status'] ?? '';
              _checkBookingStatus(status);
            }
          },
          onError: (error) {
            debugPrint("Realtime event booking stream error: $error");
          },
        );

    // 2. Fallback polling every 3 seconds for Postman / network simulation
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final res = await Supabase.instance.client
            .from('event_bookings')
            .select('status')
            .eq('id', bookingId)
            .maybeSingle();

        if (res != null) {
          final String status = res['status'] ?? '';
          _checkBookingStatus(status);
        }
      } catch (e) {
        debugPrint("Error polling event booking status: $e");
      }
    });
  }

  void _checkBookingStatus(String rawStatus) {
    final status = rawStatus.toLowerCase().trim();
    debugPrint("Event payment status received: $status");

    if (status == 'completed' || status == 'confirmed' || status == 'paid') {
      _realtimeSubscription?.cancel();
      _countdownTimer?.cancel();
      _statusCheckTimer?.cancel();

      // 1. Gửi thông báo thành công cho khách hàng
      try {
        NotificationService.instance.showEventBookingSuccessNotification(
          bookingId: _bookingId ?? '',
          eventTitle: widget.event.title,
          courtName: widget.event.courtName,
          timeRange: "${widget.event.startTime} - ${widget.event.endTime}",
          ticketCount: widget.ticketCount,
        );
      } catch (e) {
        debugPrint("Lỗi bắn thông báo đặt vé thành công: $e");
      }

      // 2. Gửi thông báo cho Chủ sân
      try {
        NotificationService.instance.notifyOwnerNewEventBooking(
          bookingId: _bookingId ?? '',
          eventId: widget.event.id,
          eventTitle: widget.event.title,
          customerName: widget.name,
          ticketCount: widget.ticketCount,
          totalAmount: widget.totalAmount,
        );
      } catch (e) {
        debugPrint("Lỗi gửi thông báo vé sự kiện cho chủ sân: $e");
      }

      // 3. Đồng bộ nhắc lịch thi đấu
      if (_userId != 'guest_user') {
        try {
          NotificationService.instance.syncMatchReminders(_userId);
        } catch (e) {
          debugPrint("Error syncing match reminders: $e");
        }
      }

      if (mounted) {
        context.pushReplacement("/PaymentSuccessPage");
      }
    } else if (status == 'cancelled' || status == 'canceled') {
      _realtimeSubscription?.cancel();
      _countdownTimer?.cancel();
      _statusCheckTimer?.cancel();

      if (mounted) {
        context.pushReplacement("/PaymentCancelPage");
      }
    }
  }

  /// Action on timer expiry: Cancel booking
  Future<void> _onTimerExpired() async {
    _countdownTimer?.cancel();
    _realtimeSubscription?.cancel();
    _statusCheckTimer?.cancel();

    if (_bookingId != null) {
      try {
        await context.read<BookingProvider>().updateEventBookingStatus(
              bookingId: _bookingId!,
              status: 'cancelled',
            );
      } catch (e) {
        debugPrint("Lỗi hủy vé sự kiện hết hạn: $e");
      }
    }

    if (mounted) {
      context.pushReplacement("/PaymentCancelPage");
    }
  }

  /// Confirm cancellation when user presses back/cancel
  Future<void> _handleUserCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: const Text(
          "Bạn muốn hủy giao dịch thanh toán vé sự kiện? Vé giữ chỗ sẽ được giải phóng.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Tiếp tục thanh toán"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hủy đặt vé", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      await _onTimerExpired();
    }
  }

  String _formatTimeLimit(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
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
    return "${buffer.toString()}đ";
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return "";
    try {
      if (rawDate.contains('/')) {
        return rawDate.split('T').first;
      }
      final parsed = DateTime.parse(rawDate);
      final d = parsed.day.toString().padLeft(2, '0');
      final m = parsed.month.toString().padLeft(2, '0');
      final y = parsed.year.toString();
      return "$d/$m/$y";
    } catch (_) {
      return rawDate.split('T').first;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đã sao chép $label"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleUserCancel();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE0FFF0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF006D38),
          title: const Text(
            "Thanh toán VietQR",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: _handleUserCancel,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF006D38)),
                )
              : _errorMessage.isNotEmpty
                  ? _buildErrorWidget()
                  : _buildPaymentQRContent(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Lỗi Khởi Tạo Giao Dịch",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => context.pop(),
              child: const Text(
                "Quay lại",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentQRContent() {
    final amountFormatted = _formatVND(widget.totalAmount);

    return Column(
      children: [
        // 1. Countdown timer banner
        Container(
          width: double.infinity,
          color: const Color(0xFFFFECE6),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 22,
                color: Colors.deepOrange,
              ),
              const SizedBox(width: 8),
              const Text(
                "Vé giữ chỗ sẽ tự động hủy sau: ",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                _formatTimeLimit(_secondsRemaining),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 2. Booking Information Summary
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 2,
                  margin: const EdgeInsets.all(12),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    initiallyExpanded: false,
                    title: const Text(
                      'Tóm tắt thông tin đặt vé',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              "Người mua",
                              widget.name,
                              Icons.person,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Số điện thoại",
                              widget.phone,
                              Icons.phone,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Mã giao dịch",
                              _paymentReference ?? "",
                              Icons.vpn_key,
                            ),
                            if (_bookingId != null) ...[
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                "Mã đơn (ID)",
                                _bookingId!,
                                Icons.receipt_long,
                                canCopy: true,
                              ),
                            ],
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Sự kiện",
                              widget.event.title,
                              Icons.event,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Khung giờ",
                              "${widget.event.startTime} - ${widget.event.endTime}",
                              Icons.access_time,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Ngày diễn ra",
                              _formatDate(widget.event.eventDate),
                              Icons.calendar_month,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Vị trí",
                              widget.event.courtName,
                              Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Số lượng",
                              "${widget.ticketCount} vé",
                              Icons.confirmation_number_outlined,
                            ),
                            if (widget.note.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                "Ghi chú",
                                widget.note,
                                Icons.notes_rounded,
                              ),
                            ],
                            const Divider(height: 20),
                            _buildInfoRow(
                              "Tổng thanh toán",
                              amountFormatted,
                              Icons.payment,
                              isPrice: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. VietQR Dynamic Code Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          "Mã QR Thanh Toán Tự Động",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006D38),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Quét mã qua ứng dụng ngân hàng của bạn\nđể hoàn tất đặt vé tức thì.",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // QR Image loader
                        if (_vietQRUrl != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFC6F7CC),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Image.network(
                              _vietQRUrl!,
                              width: 230,
                              height: 230,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  width: 230,
                                  height: 230,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF006D38),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 230,
                                  height: 230,
                                  child: Center(
                                    child: Text(
                                      "Không thể tải mã QR.\nVui lòng chuyển khoản thủ công theo thông tin bên dưới.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Bank Transfer Details
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FDF9),
                            border: Border.all(color: const Color(0xFFE0FFF0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildTransferRow("Ngân hàng", "MBBank (MB)"),
                              const Divider(height: 16),
                              _buildTransferRow(
                                "Chủ tài khoản",
                                _accountName,
                              ),
                              const Divider(height: 16),
                              _buildTransferRow(
                                "Số tài khoản",
                                _accountNumber,
                                canCopy: true,
                              ),
                              const Divider(height: 16),
                              _buildTransferRow(
                                "Số tiền",
                                amountFormatted,
                                canCopy: true,
                                copyValue: widget.totalAmount.toInt().toString(),
                              ),
                              if (_paymentReference != null) ...[
                                const Divider(height: 16),
                                _buildTransferRow(
                                  "Nội dung chuyển khoản",
                                  _paymentReference!,
                                  isHighlight: true,
                                  canCopy: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Loading indicator waiting for webhook / Postman
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D38).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF006D38),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Đang chờ hệ thống ghi nhận thanh toán...",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF006D38),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String title,
    String value,
    IconData icondata, {
    bool isPrice = false,
    bool canCopy = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFC6F7CC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icondata, color: const Color(0xFF006D38), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isPrice ? 16 : 14,
                        color: isPrice ? Colors.green[800] : Colors.black87,
                      ),
                    ),
                  ),
                  if (canCopy)
                    InkWell(
                      onTap: () => _copyToClipboard(value, title),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: Color(0xFF006D38),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransferRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool canCopy = false,
    String? copyValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isHighlight ? 15 : 14,
                    color: isHighlight ? Colors.red[800] : Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () =>
                      _copyToClipboard(copyValue ?? value, label),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Color(0xFF006D38),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
