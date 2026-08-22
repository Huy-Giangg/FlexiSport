import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventPaymentInfoPage extends StatefulWidget {
  final EventEntity event;
  final int ticketCount;
  final double totalAmount;

  const EventPaymentInfoPage({
    super.key,
    required this.event,
    required this.ticketCount,
    required this.totalAmount,
  });

  @override
  State<EventPaymentInfoPage> createState() => _EventPaymentInfoPageState();
}

class _EventPaymentInfoPageState extends State<EventPaymentInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  String _venueName = 'CLB Thể Thao';
  String _venueAddress = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadVenueDetails();
  }

  Future<void> _loadUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final displayName = user.userMetadata?['full_name'] as String? ??
                          user.userMetadata?['name'] as String? ?? '';
      _nameController.text = displayName;
      _phoneController.text = user.phone ?? '';

      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            _nameController.text = data['name'].toString();
          }
          if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
            _phoneController.text = data['phone'].toString();
          }
        }
      } catch (e) {
        debugPrint("Lỗi tải thông tin: $e");
      }
    }
  }

  Future<void> _loadVenueDetails() async {
    try {
      final data = await Supabase.instance.client
          .from('venues')
          .select('name, address')
          .eq('id', widget.event.venueId)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _venueName = data['name']?.toString() ?? 'CLB Thể Thao';
          _venueAddress = data['address']?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin cơ sở: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
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

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('T')[0].split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006D38),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D38),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        title: const Text(
          "Đặt vé sự kiện",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Card 1: Venue Info
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF005F31),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.map_outlined, color: Colors.yellowAccent, size: 24),
                              SizedBox(width: 8),
                              Text(
                                "Thông tin địa điểm",
                                style: TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              text: "Tên CLB: ",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: _venueName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          if (_venueAddress.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                text: "Địa chỉ: ",
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                                children: [
                                  TextSpan(
                                    text: _venueAddress,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Card 2: Ticket Info
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF005F31),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.confirmation_num_outlined, color: Colors.yellowAccent, size: 24),
                              SizedBox(width: 8),
                              Text(
                                "Thông tin vé sự kiện",
                                style: TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              text: "Sự kiện: ",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: widget.event.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: "Sân & Khung giờ: ",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: "${widget.event.courtName} | ${widget.event.startTime} - ${widget.event.endTime}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: "Ngày diễn ra: ",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: _formatDate(widget.event.eventDate),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: "Môn thi đấu: ",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: "${widget.event.sportType} (${widget.event.level})",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: "Số lượng vé: ",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: "${widget.ticketCount} vé",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: "Giá vé: ",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: _formatVND(widget.event.ticketPrice),
                                  style: const TextStyle(color: Colors.yellowAccent),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 20),
                          RichText(
                            text: TextSpan(
                              text: "TỔNG TIỀN VÉ: ",
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: _formatVND(widget.totalAmount),
                                  style: const TextStyle(color: Color(0xFFFFEC88), fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card 3: User Details Form
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TÊN NGƯỜI ĐĂNG KÝ",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                hintText: "Nhập tên của bạn",
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên người đăng ký';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "SỐ ĐIỆN THOẠI LIÊN HỆ",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              style: const TextStyle(color: Colors.black),
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                hintText: "Nhập số điện thoại liên hệ",
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                final phoneRegex = RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$');
                                if (!phoneRegex.hasMatch(value.trim())) {
                                  return 'Số điện thoại không hợp lệ (ví dụ: 0912345678)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "GHI CHÚ (NẾU CÓ)",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _noteController,
                              style: const TextStyle(color: Colors.black),
                              maxLines: 2,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                hintText: "Nhập ghi chú gửi cho ban tổ chức",
                                fillColor: Colors.white,
                                filled: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFFE3B02C),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.push(
                      "/EventPaymentConfirmPage",
                      extra: {
                        'event': widget.event,
                        'ticketCount': widget.ticketCount,
                        'totalAmount': widget.totalAmount,
                        'name': _nameController.text.trim(),
                        'phone': _phoneController.text.trim(),
                        'note': _noteController.text.trim(),
                      },
                    );
                  }
                },
                child: const Text(
                  "TIẾP TỤC THANH TOÁN",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
