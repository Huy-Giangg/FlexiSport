import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flexisport_app/features/payment/presentation/page/payment_confirm_page.dart';
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

  PaymentInfoArgs({
    required this.venue,
    required this.date,
    required this.selectedSlots,
    required this.totalAmount,
    required this.totalHours,
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

  @override
  void initState() {
    super.initState();
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
                                    "• Việc thanh toán được thực hiện trực tiếp giữa bạn và chủ sân.\n"
                                    "• FlexiSport đóng vai trò kết nối, hỗ trợ bạn tìm và đặt sân dễ dàng hơn.\n"
                                    "• Mỗi sân có thể có quy định và chính sách riêng, hãy dành chút thời gian đọc kỹ để đảm bảo quyền lợi cho bạn nhé!",

                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.4, // khoảng cách dòng
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              "Bằng việc bấm Xác nhận và Thanh toán, bạn xác nhận đã đọc và đồng ý với ",
                                        ),

                                        TextSpan(
                                          text: "Điều khoản đặt sân",
                                          style: TextStyle(
                                            color: Color(0xFFE0C33A),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),

                                        TextSpan(text: " và "),

                                        TextSpan(
                                          text:
                                              "Chính sách hoàn tiền và huỷ lịch.",
                                          style: TextStyle(
                                            color: Color(0xFFE0C33A),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
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
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Xử lý thanh toán/đặt lịch ở đây
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
                child: const Text(
                  "XÁC NHẬN & THANH TOÁN",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
