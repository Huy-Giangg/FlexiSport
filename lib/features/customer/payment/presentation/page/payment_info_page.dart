import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/payment_confirm_page.dart';
import 'package:flexisport_app/features/customer/booking/data/datasources/booking_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectedSlotDetail {
  final String courtName;
  final String timeRange;
  final double price;

  SelectedSlotDetail({
    required this.courtName,
    required this.timeRange,
    required this.price,
  });
}

class PaymentInfoArgs {
  final SportsComplexEntity venue;
  final String date;
  final List<SelectedSlotDetail> selectedSlots;
  final double totalAmount;
  final double totalHours;
  final List<Map<String, dynamic>> rawSlots;
  final String? lockToken;

  PaymentInfoArgs({
    required this.venue,
    required this.date,
    required this.selectedSlots,
    required this.totalAmount,
    required this.totalHours,
    this.rawSlots = const [],
    this.lockToken,
  });
}

class PaymentInfoPage extends StatefulWidget {
  final PaymentInfoArgs args;

  const PaymentInfoPage({super.key, required this.args});

  @override
  State<PaymentInfoPage> createState() => _PaymentInfoPageState();
}

class _PaymentInfoPageState extends State<PaymentInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _refundRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _showTermsAndPolicyModal(context, initialTabIndex: 0);
    _refundRecognizer = TapGestureRecognizer()
      ..onTap = () => _showTermsAndPolicyModal(context, initialTabIndex: 1);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // 1. Điền tạm thời từ Auth Session metadata trước để tránh hiển thị trống
      final displayName =
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          '';
      _nameController.text = displayName;
      _phoneController.text = user.phone ?? '';

      // 2. Truy vấn từ bảng profiles để lấy thông tin cập nhật mới nhất (nếu có)
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
        debugPrint("Lỗi tải thông tin thanh toán: $e");
      }
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _refundRecognizer.dispose();
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

  @override
  Widget build(BuildContext context) {
    final double totalHours = widget.args.totalHours;
    final int hours = totalHours.toInt();
    final int minutes = ((totalHours - hours) * 60).toInt();
    final String durationStr = hours > 0
        ? "${hours}h${minutes.toString().padLeft(2, '0')}"
        : "$minutes phút";

    String sportType = "THỂ THAO";
    if (widget.args.selectedSlots.isNotEmpty) {
      final nameLower = widget.args.selectedSlots.first.courtName.toLowerCase();
      if (nameLower.contains('pickleball')) {
        sportType = "PICKLEBALL";
      } else if (nameLower.contains('tennis')) {
        sportType = "TENNIS";
      } else if (nameLower.contains('cầu lông') ||
          nameLower.contains('badminton')) {
        sportType = "CẦU LÔNG";
      } else if (nameLower.contains('bóng đá') ||
          nameLower.contains('football') ||
          nameLower.contains('soccer')) {
        sportType = "BÓNG ĐÁ";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF006D38),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D38),
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          "Đặt lịch ngày trực quan",
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
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF005F31),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          Row(
                            children: const [
                              Icon(
                                Icons.map_outlined,
                                color: Colors.yellowAccent,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Thông tin sân",
                                style: TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          RichText(
                            text: TextSpan(
                              text: "Tên CLB: ",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text: widget.args.venue.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          RichText(
                            text: TextSpan(
                              text: "Địa chỉ: ",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text: widget.args.venue.address,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF005F31),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          Row(
                            children: const [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.yellowAccent,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Thông tin đặt lịch",
                                style: TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          RichText(
                            text: TextSpan(
                              text: "Ngày: ",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text: widget.args.date,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          ...widget.args.selectedSlots.map(
                            (slot) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: RichText(
                                text: TextSpan(
                                  text: "- ${slot.courtName}: ",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "${slot.timeRange} | ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _formatVND(slot.price),
                                      style: const TextStyle(
                                        color: Colors.yellowAccent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          RichText(
                            text: TextSpan(
                              text: "Đối tượng: ",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text: sportType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          RichText(
                            text: TextSpan(
                              text: "Tổng giờ: ",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text: durationStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          RichText(
                            text: TextSpan(
                              text: "Tổng tiền: ",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text: _formatVND(widget.args.totalAmount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      margin: const EdgeInsets.all(8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TÊN CỦA BẠN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: "Nhập tên của bạn",
                                hintStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                suffixIcon: IconButton(
                                  onPressed: () => _nameController.clear(),
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: Color.fromARGB(255, 11, 47, 12),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên của bạn';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              "SỐ ĐIỆN THOẠI",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _phoneController,
                              style: const TextStyle(color: Colors.black),
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: "Nhập số điện thoại",
                                hintStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                suffixIcon: IconButton(
                                  onPressed: () => _phoneController.clear(),
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: Color.fromARGB(255, 11, 47, 12),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                final phoneRegex = RegExp(
                                  r'^(0|\+84)[3|5|7|8|9][0-9]{8}$',
                                );
                                if (!phoneRegex.hasMatch(value.trim())) {
                                  return 'Số điện thoại không hợp lệ (ví dụ: 0912345678)';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              "GHI CHÚ CHO CHỦ SÂN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _noteController,
                              style: const TextStyle(color: Colors.black),
                              maxLines: 2,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: "Nhập ghi chú",
                                hintStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFF005F31),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFFE0C33A), // vàng đậm
                                          Color(0x66E0C33A), // vàng mờ dần
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.warning_amber_sharp,
                                          color: Color.fromARGB(
                                            255,
                                            86,
                                            74,
                                            27,
                                          ),
                                        ),

                                        SizedBox(width: 8),

                                        Text(
                                          "Lưu ý: ",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF006D38),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  const Text(
                                    "• Khung giờ đã chọn sẽ được giữ chỗ trong 10 phút để bạn hoàn tất thanh toán.\n"
                                    "• Thanh toán chuyển khoản tự động qua mã VietQR, hệ thống sẽ xác nhận lịch đặt ngay sau khi nhận được tiền.\n"
                                    "• Bạn có thể bấm xem chi tiết quy định sử dụng sân bãi và chính sách hoàn tiền bên dưới.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      height: 1.45,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              "Bằng việc bấm Xác nhận và Thanh toán, bạn xác nhận đã đọc và đồng ý với ",
                                        ),

                                        TextSpan(
                                          text: "Điều khoản đặt sân",
                                          style: const TextStyle(
                                            color: Color(0xFFE0C33A),
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          recognizer: _termsRecognizer,
                                        ),

                                        const TextSpan(text: " và "),

                                        TextSpan(
                                          text:
                                              "Chính sách hoàn tiền và huỷ lịch.",
                                          style: const TextStyle(
                                            color: Color(0xFFE0C33A),
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          recognizer: _refundRecognizer,
                                        ),
                                      ],
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
            ),

            Container(
              margin: const EdgeInsets.all(12),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFFE3B02C),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSubmitting = true;
                          });

                          // Kiểm tra quyền giữ chỗ & gia hạn 10 phút trước khi sang màn thanh toán
                          if (widget.args.rawSlots.isNotEmpty) {
                            try {
                              final bookingDatasource = BookingRemoteDatasource(Supabase.instance.client);
                              final result = await bookingDatasource.verifyAndHoldSlotsBatch(
                                slots: widget.args.rawSlots,
                                lockToken: widget.args.lockToken,
                                durationMinutes: 10,
                              );

                              if (!mounted) return;
                              setState(() {
                                _isSubmitting = false;
                              });

                              if (result['success'] != true) {
                                if (!mounted) return;
                                final msg = result['message']?.toString() ??
                                    "Thời gian giữ chỗ của bạn đã hết hạn hoặc khung giờ này đã có người khác đặt.";
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Row(
                                      children: const [
                                        Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Phiên giữ chỗ hết hạn",
                                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      "$msg\n\nVui lòng quay lại màn hình chọn sân để chọn khung giờ khác.",
                                      style: const TextStyle(fontSize: 14.5, height: 1.45),
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF016B34),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          if (mounted) {
                                            context.pop(); // Quay lại màn hình chọn sân
                                          }
                                        },
                                        child: const Text("QUAY LẠI CHỌN GIỜ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                            } catch (_) {
                              if (mounted) {
                                setState(() {
                                  _isSubmitting = false;
                                });
                              }
                            }
                          } else {
                            if (mounted) {
                              setState(() {
                                _isSubmitting = false;
                              });
                            }
                          }

                          if (!mounted) return;
                          context.push(
                            "/PaymentConfirmPage",
                            extra: PaymentConfirmArgs(
                              infoArgs: widget.args,
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              note: _noteController.text.trim(),
                            ),
                          );
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "XÁC NHẬN & THANH TOÁN",
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsAndPolicyModal(BuildContext context, {int initialTabIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          initialIndex: initialTabIndex,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Thanh kéo
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                // Tiêu đề & Nút đóng
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Quy định & Chính sách",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006D38),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                // TabBar
                TabBar(
                  labelColor: const Color(0xFF006D38),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF006D38),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13.5),
                  tabs: const [
                    Tab(text: "Điều khoản đặt sân"),
                    Tab(text: "Chính sách hoàn tiền & huỷ"),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // TabBarView Content
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTermsTabContent(),
                      _buildRefundPolicyTabContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsTabContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildPolicySection(
          number: '1',
          title: 'Quy trình đặt sân & giữ chỗ',
          content:
              '• Khách hàng chọn sân, ngày và khung giờ trực tiếp trên ứng dụng FlexiSport.\n'
              '• Sau khi chuyển sang bước thanh toán, khung giờ đã chọn sẽ được hệ thống tạm khóa (giữ chỗ) trong vòng 10 phút.\n'
              '• Nếu quá 10 phút quý khách chưa hoàn tất chuyển khoản, ca đặt sẽ tự động bị hủy và mở lại cho người khác đặt.',
        ),
        const SizedBox(height: 14),
        _buildPolicySection(
          number: '2',
          title: 'Thanh toán tự động qua VietQR',
          content:
              '• Thanh toán 100% qua chuyển khoản ngân hàng quét mã VietQR tự động.\n'
              '• Vui lòng giữ nguyên mã giao dịch và số tiền trong nội dung chuyển khoản để hệ thống đối soát tự động.\n'
              '• Ngay khi ngân hàng ghi nhận số dư thành công, đơn đặt sân sẽ tự động chuyển sang trạng thái "Đã xác nhận".',
        ),
        const SizedBox(height: 14),
        _buildPolicySection(
          number: '3',
          title: 'Nhận sân thi đấu',
          content:
              '• Quý khách xuất trình mã đặt sân (booking code) hoặc số điện thoại tại quầy lễ tân của cơ sở để nhận sân.\n'
              '• Vui lòng có mặt trước giờ thi đấu 5 - 10 phút để chuẩn bị và khởi động.',
        ),
        const SizedBox(height: 14),
        _buildPolicySection(
          number: '4',
          title: 'Quy định nội quy sân bãi',
          content:
              '• Sử dụng giày thể thao đế bằng, đế cao su chuyên dụng (cầu lông, tennis, pickleball, bóng đá...). Không sử dụng giày cao gót hoặc giày đế đinh cứng gây hư hại mặt sân.\n'
              '• Giữ gìn vệ sinh chung, không hút thuốc lá, không mang đồ ăn có mùi hoặc rượu bia vào khu vực thi đấu.\n'
              '• Bàn giao sân đúng giờ quy định để không làm ảnh hưởng đến ca thi đấu tiếp theo.',
        ),
      ],
    );
  }

  Widget _buildRefundPolicyTabContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text(
          "Chi tiết tỷ lệ và điều kiện hoàn tiền khi hủy lịch:",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildRefundTierCard(
          title: "Hủy trước ≥ 24 giờ / Chờ duyệt",
          rate: "Hoàn 100%",
          badgeColor: const Color(0xFF16A34A),
          description:
              "Được hoàn trả 100% số tiền đã thanh toán vào tài khoản ngân hàng của bạn.",
        ),
        const SizedBox(height: 10),
        _buildRefundTierCard(
          title: "Hủy từ 2h - 24h trước giờ chơi",
          rate: "Hoàn 50%",
          badgeColor: const Color(0xFFEA580C),
          description:
              "Hoàn lại 50% số tiền đã thanh toán; 50% còn lại dùng để hỗ trợ chi phí vận hành và giữ sân cho cơ sở.",
        ),
        const SizedBox(height: 10),
        _buildRefundTierCard(
          title: "Hủy sát giờ chơi (< 2 giờ)",
          rate: "Không hoàn (0%)",
          badgeColor: const Color(0xFFDC2626),
          description:
              "Hệ thống tự động khóa tính năng hủy trực tuyến. Quý khách vui lòng liên hệ trực tiếp hotline của cơ sở để được hỗ trợ trong trường hợp bất khả kháng.",
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.access_time_rounded, size: 18, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Thời gian xử lý hoàn tiền",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tiền hoàn sẽ được chuyển về tài khoản ngân hàng thụ hưởng của quý khách trong vòng 1 - 3 ngày làm việc sau khi đơn hủy được xác nhận.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildPolicySection(
          number: '★',
          title: 'Chính sách đổi / dời lịch',
          content:
              'Khách hàng có nhu cầu đổi giờ hoặc dời sang ngày khác vui lòng liên hệ trực tiếp hotline ban quản lý sân trước giờ bắt đầu để được hỗ trợ tùy theo tình trạng sân trống thực tế.',
        ),
      ],
    );
  }

  Widget _buildPolicySection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF006D38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundTierCard({
    required String title,
    required String rate,
    required Color badgeColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  rate,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

