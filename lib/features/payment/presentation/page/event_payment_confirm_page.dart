import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flexisport_app/features/booking/domain/entities/event_entity.dart';
import 'package:flexisport_app/features/booking/presentation/providers/booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final ImagePicker _picker = ImagePicker();
  XFile? _paymentImage;
  Timer? _countdownTimer;
  int _secondsRemaining = 300;
  String _userId = '';
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest_user';
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 300;
    });
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

  void _onTimerExpired() {
    _countdownTimer?.cancel();
    if (mounted) {
      context.pushReplacement("/PaymentCancelPage");
    }
  }

  Future<void> _confirmBooking() async {
    if (_paymentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng tải lên ảnh xác nhận chuyển khoản.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    try {
      _countdownTimer?.cancel();

      final Map<String, dynamic> bookingData = {
        'event_id': widget.event.id,
        'user_id': _userId == 'guest_user' ? null : _userId,
        'ticket_count': widget.ticketCount,
        'total_amount': widget.totalAmount,
        'status': 'completed', // Đã thanh toán
        'customer_name': widget.name,
        'customer_phone': widget.phone,
        'note': widget.note,
      };

      final booking = await context.read<BookingProvider>().registerEvent(
        bookingData,
      );

      // Save booking ID locally if guest user
      if (_userId == 'guest_user') {
        final prefs = await SharedPreferences.getInstance();
        final List<String> guestBookings =
            prefs.getStringList('guest_event_booking_ids') ?? [];
        guestBookings.add(booking.id);
        await prefs.setStringList('guest_event_booking_ids', guestBookings);
      }

      if (mounted) {
        context.push("/PaymentSuccessPage");
      }
    } catch (e) {
      debugPrint("Lỗi xác nhận mua vé: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt vé thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _startTimer();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  String _formatTimeLimit(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Future<void> _pickPaymentImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _paymentImage = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking payment image: $e");
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFE0FFF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D38),
        title: const Text(
          "Thanh toán vé sự kiện",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Warning Countdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              text: "Vui lòng chuyển khoản thanh toán trong ",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: _formatTimeLimit(_secondsRemaining),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Detail summary Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tóm tắt thông tin đặt vé',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF006D38),
                              ),
                            ),
                            const Divider(height: 24),
                            _buildInfoRow("Người mua", widget.name),
                            _buildInfoRow("Số điện thoại", widget.phone),
                            _buildInfoRow("Sự kiện", widget.event.title),
                            _buildInfoRow(
                              "Khung giờ",
                              "${widget.event.startTime} - ${widget.event.endTime}",
                            ),
                            _buildInfoRow("Vị trí", widget.event.courtName),
                            _buildInfoRow(
                              "Số lượng",
                              "${widget.ticketCount} vé",
                            ),
                            _buildInfoRow(
                              "Ghi chú",
                              widget.note.isNotEmpty ? widget.note : "Không có",
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Tổng số tiền",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatVND(widget.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // QR Code Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              "Quét mã QR để chuyển khoản",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Display QR Code
                            Image.asset(
                              "assets/images/qr.jpg",
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Chủ tài khoản: FLEXISPORT APP\nSố tài khoản: 19036783868686\nNgân hàng: Techcombank\nNội dung: Chuyen tien ve SK [Ten cua ban]",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tải ảnh minh chứng chuyển khoản
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Tải lên hình ảnh xác nhận chuyển khoản (*)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _pickPaymentImage,
                              child: Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: _paymentImage != null
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              File(_paymentImage!.path),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _paymentImage = null;
                                                });
                                              },
                                              child: CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Colors.black
                                                    .withOpacity(0.5),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 48,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Nhấn để chọn ảnh chuyển khoản thành công',
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Button Action
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              width: double.infinity,
              height: 66,
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF006D38),
                ),
                onPressed: _isConfirming ? null : _confirmBooking,
                child: _isConfirming
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "XÁC NHẬN ĐÃ CHUYỂN KHOẢN",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
