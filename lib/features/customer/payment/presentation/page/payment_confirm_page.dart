import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/services/notification_service.dart';
import 'package:flexisport_app/features/customer/booking/presentation/providers/booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/payment_info_page.dart';
import 'package:flexisport_app/features/customer/payment/data/datasources/payment_remote_datasource.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentConfirmArgs {
  final PaymentInfoArgs infoArgs;
  final String name;
  final String phone;
  final String note;

  PaymentConfirmArgs({
    required this.infoArgs,
    required this.name,
    required this.phone,
    required this.note,
  });
}

class PaymentConfirmPage extends StatefulWidget {
  final PaymentConfirmArgs args;
  const PaymentConfirmPage({super.key, required this.args});

  @override
  State<PaymentConfirmPage> createState() => _PaymentConfirmPageState();
}

class _PaymentConfirmPageState extends State<PaymentConfirmPage> {
  final PaymentRemoteDatasource _paymentDatasource = PaymentRemoteDatasource();
  
  Timer? _countdownTimer;
  StreamSubscription? _realtimeSubscription;
  
  int _secondsRemaining = 300; // 5 minutes payment limit
  String _userId = '';
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  // State variables for payment session
  String? _bookingId;
  String? _paymentReference;
  String? _vietQRUrl;

  // Merchant Bank Configuration (default)
  final String _bankId = 'MBBank'; 
  final String _accountNumber = '0354676200';
  final String _accountName = 'NGUYEN HUY GIANG';

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest_user';
    _initializeBookingTransaction();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

  /// Step 1: Create PENDING_PAYMENT booking, slots, and payment reference using RPC
  Future<void> _initializeBookingTransaction() async {
    try {
      final dateStr = widget.args.infoArgs.date; // e.g. "30/05/2026"
      final dateParts = dateStr.split('/');
      String queryDate = "";
      if (dateParts.length == 3) {
        queryDate = "${dateParts[2]}-${dateParts[1]}-${dateParts[0]}";
      } else {
        queryDate = dateStr;
      }

      // 1. Get temporary locked slots from court_locks
      final locksResponse = await Supabase.instance.client
          .from('court_locks')
          .select('court_id, slot_index, booking_date')
          .eq('user_id', _userId)
          .eq('booking_date', queryDate);

      final List locks = locksResponse as List? ?? [];
      if (locks.isEmpty) {
        throw Exception('Không tìm thấy thông tin giữ chỗ (phiên giữ chỗ có thể đã hết hạn).');
      }

      final List<Map<String, dynamic>> slotsToInsert = locks.map((lock) {
        return {
          'court_id': lock['court_id'],
          'booking_date': lock['booking_date'],
          'slot_index': lock['slot_index'],
        };
      }).toList();

      // 2. Call RPC to create database transaction
      final result = await _paymentDatasource.createBookingTransaction(
        userId: _userId,
        totalAmount: widget.args.infoArgs.totalAmount,
        name: widget.args.name,
        phone: widget.args.phone,
        note: widget.args.note,
        slots: slotsToInsert,
      );

      // Save guest booking ID locally if applicable
      if (_userId == 'guest_user') {
        final prefs = await SharedPreferences.getInstance();
        final List<String> guestBookings = prefs.getStringList('guest_booking_ids') ?? [];
        guestBookings.add(result.bookingId);
        await prefs.setStringList('guest_booking_ids', guestBookings);
      }

      // 3. Generate VietQR Link
      final qrUrl = _generateVietQRUrl(
        bankId: _bankId,
        accountNumber: _accountNumber,
        accountName: _accountName,
        amount: widget.args.infoArgs.totalAmount,
        reference: result.paymentReference,
      );

      if (!mounted) return;
      setState(() {
        _bookingId = result.bookingId;
        _paymentReference = result.paymentReference;
        _vietQRUrl = qrUrl;
        _isLoading = false;
      });

      // 4. Start timer & Subscribe to Realtime notifications
      _startTimer();
      _subscribeToRealtimePaymentStatus(result.bookingId);

    } catch (e) {
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

  /// Step 3: Listen to Supabase Realtime changes for booking status updates
  void _subscribeToRealtimePaymentStatus(String bookingId) {
    _realtimeSubscription?.cancel();
    
    _realtimeSubscription = Supabase.instance.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final booking = data.first;
            final String status = booking['status'] ?? '';
            
            debugPrint("Realtime payment status update received: $status");

            if (status == 'completed' || status == 'confirmed') {
              _realtimeSubscription?.cancel();
              _countdownTimer?.cancel();
              
              // 1. Gửi thông báo thành công cho khách hàng
              final slots = widget.args.infoArgs.selectedSlots;
              final courtName = slots.isNotEmpty ? slots.first.courtName : 'Sân thể thao';
              final timeRange = slots.isNotEmpty ? slots.first.timeRange : '';
              final venueName = widget.args.infoArgs.venue.name;
              final bookingDate = widget.args.infoArgs.date;

              try {
                NotificationService.instance.showBookingSuccessNotification(
                  bookingId: bookingId,
                  venueName: venueName,
                  courtName: courtName,
                  timeRange: timeRange,
                  date: bookingDate,
                );
              } catch (e) {
                debugPrint("Lỗi bắn thông báo đặt sân thành công: $e");
              }

              // 2. Gửi thông báo cho Chủ sân
              try {
                NotificationService.instance.notifyOwnerNewBooking(
                  bookingId: bookingId,
                  venueId: widget.args.infoArgs.venue.id,
                  venueName: venueName,
                  courtName: courtName,
                  timeRange: timeRange,
                  date: bookingDate,
                  customerName: widget.args.name,
                  totalAmount: widget.args.infoArgs.totalAmount,
                );
              } catch (e) {
                debugPrint("Lỗi gửi thông báo cho chủ sân: $e");
              }

              // 3. Đồng bộ nhắc lịch thi đấu
              if (_userId != 'guest_user') {
                try {
                  NotificationService.instance.syncMatchReminders(_userId);
                } catch (e) {
                  debugPrint("Error syncing notifications: $e");
                }
              }
              
              if (mounted) {
                context.pushReplacement("/PaymentSuccessPage");
              }
            } else if (status == 'cancelled') {
              _realtimeSubscription?.cancel();
              _countdownTimer?.cancel();
              if (mounted) {
                context.pushReplacement("/PaymentCancelPage");
              }
            }
          }
        }, onError: (error) {
          debugPrint("Realtime subscription error: $error");
        });
  }

  /// Action on timer expiry: Cancel booking and release database locks
  Future<void> _onTimerExpired() async {
    _countdownTimer?.cancel();
    _realtimeSubscription?.cancel();

    if (_bookingId != null) {
      await _paymentDatasource.cancelBooking(_bookingId!);
    }

    final dateStr = widget.args.infoArgs.date; // e.g. "30/05/2026"
    final dateParts = dateStr.split('/');
    String queryDate = "";
    if (dateParts.length == 3) {
      queryDate = "${dateParts[2]}-${dateParts[1]}-${dateParts[0]}";
    } else {
      queryDate = dateStr;
    }

    if (mounted) {
      await context.read<BookingProvider>().releaseAllUserLocks(
            venueId: widget.args.infoArgs.venue.id,
            date: queryDate,
            userId: _userId,
          );
      context.pushReplacement("/PaymentCancelPage");
    }
  }

  /// Confirm cancellation when user presses back/cancel
  Future<void> _handleUserCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: const Text("Bạn muốn hủy giao dịch thanh toán? Các ô giờ đã giữ chỗ sẽ được giải phóng."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Tiếp tục thanh toán"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hủy đặt sân", style: TextStyle(color: Colors.red)),
          ),
        ],
      )
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleUserCancel();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE0FFF0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF006D38),
          title: const Text(
            "Thanh toán VietQR",
            style: TextStyle(fontSize: 22, color: Colors.white),
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
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF006D38)))
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
              "Lỗi Khởi Tạo Đặt Lịch",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[800]),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => context.pop(),
              child: const Text("Quay lại", style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentQRContent() {
    final amountFormatted = _formatVND(widget.args.infoArgs.totalAmount);
    
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
              const Icon(Icons.timer_outlined, size: 22, color: Colors.deepOrange),
              const SizedBox(width: 8),
              const Text(
                "Lưới giữ sân sẽ tự động hủy sau: ",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              Text(
                _formatTimeLimit(_secondsRemaining),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 2,
                  margin: const EdgeInsets.all(12),
                  child: ExpansionTile(
                    shape: const Border(), // Xóa viền/đường kẻ khi mở rộng
                    collapsedShape: const Border(), // Xóa viền/đường kẻ khi thu gọn
                    initiallyExpanded: false,
                    title: const Text(
                      'Thông tin đặt sân',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                          children: [
                            _buildInfoRow("Tên khách hàng", widget.args.name, Icons.person),
                            const SizedBox(height: 10),
                            _buildInfoRow("Số điện thoại", widget.args.phone, Icons.phone),
                            const SizedBox(height: 10),
                            _buildInfoRow("Mã giao dịch tạm", _paymentReference ?? "", Icons.vpn_key),
                            const SizedBox(height: 10),
                            _buildInfoRow("Tổng thời gian", "${widget.args.infoArgs.totalHours} giờ", Icons.access_time),
                            const SizedBox(height: 10),
                            _buildDetailsRow(),
                            const Divider(height: 20),
                            _buildInfoRow("Tổng thanh toán", amountFormatted, Icons.payment, isPrice: true),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // 3. VietQR Dynamic Code Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          "Mã QR Thanh Toán Tự Động",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006D38)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Quét mã qua ứng dụng ngân hàng của bạn\n để hoàn tất đặt chỗ tức thì.",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // QR Image loader
                        if (_vietQRUrl != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFC6F7CC), width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            ),
                            child: Image.network(
                              _vietQRUrl!,
                              width: 230,
                              height: 230,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  width: 230,
                                  height: 230,
                                  child: Center(child: CircularProgressIndicator(color: Color(0xFF006D38))),
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
                                      style: TextStyle(color: Colors.red, fontSize: 13),
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
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Column(
                            children: [
                              _buildTransferRow("Ngân hàng", "MBBank (MB)"),
                              const Divider(height: 16),
                              _buildTransferRow("Chủ tài khoản", _accountName),
                              const Divider(height: 16),
                              _buildTransferRow("Số tài khoản", _accountNumber),
                              const Divider(height: 16),
                              _buildTransferRow("Số tiền", amountFormatted),
                              const Divider(height: 16),
                              _buildTransferRow(
                                "Nội dung chuyển khoản", 
                                _paymentReference ?? "", 
                                isHighlight: true
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Loading indicator waiting for webhook
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D38).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF006D38)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Đang chờ hệ thống ghi nhận thanh toán...",
                          style: TextStyle(
                            fontStyle: FontStyle.italic, 
                            fontWeight: FontWeight.w600, 
                            color: Color(0xFF006D38),
                            fontSize: 14
                          ),
                        )
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

  Widget _buildInfoRow(String title, String value, IconData icondata, {bool isPrice = false}) {
    return Row(
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
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                value, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: isPrice ? 16 : 14, 
                  color: isPrice ? Colors.green[800] : Colors.black87
                )
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFC6F7CC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.calendar_month, color: Color(0xFF006D38), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chi tiết đơn đặt', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                widget.args.infoArgs.date,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              ...widget.args.infoArgs.selectedSlots.map(
                (slot) => Text(
                  '• ${slot.courtName}: ${slot.timeRange}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransferRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 16 : 14,
              color: isHighlight ? Colors.red[800] : Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        )
      ],
    );
  }
}
