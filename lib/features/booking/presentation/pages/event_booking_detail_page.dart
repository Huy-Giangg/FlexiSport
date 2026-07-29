import 'package:flexisport_app/features/booking/domain/entities/event_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';

class EventBookingDetailPage extends StatefulWidget {
  final EventEntity event;
  final int bookedCount;
  final bool showNavbarOnPop;

  const EventBookingDetailPage({
    super.key,
    required this.event,
    required this.bookedCount,
    this.showNavbarOnPop = false,
  });

  @override
  State<EventBookingDetailPage> createState() => _EventBookingDetailPageState();
}

class _EventBookingDetailPageState extends State<EventBookingDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  String _venueName = 'Đang tải...';
  String _venueAddress = 'Đang tải...';
  int _selectedTickets = 1;

  @override
  void initState() {
    super.initState();
    _loadVenueDetails();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
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
          _venueName = data['name']?.toString() ?? 'CLB Ferry Pickleball';
          _venueAddress = data['address']?.toString() ?? '';
        });
      } else {
        setState(() {
          _venueName = 'Ferry Pickleball';
          _venueAddress =
              'Khách sạn Kim Liên, số 7 P. Đào Duy Anh, Phương Liên, Đống Đa, Hà Nội';
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin cơ sở: $e");
      if (mounted) {
        setState(() {
          _venueName = 'Ferry Pickleball';
          _venueAddress =
              'Khách sạn Kim Liên, số 7 P. Đào Duy Anh, Phương Liên, Đống Đa, Hà Nội';
        });
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final displayName =
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          '';
      _nameController.text = displayName;
      _phoneController.text = user.phone ?? '';

      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null && mounted) {
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

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('T')[0].split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return dateStr;
  }

  String _getShortEventCode(String id) {
    if (id.length >= 4) {
      return id.substring(id.length - 4).toUpperCase();
    }
    return id.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final maxAvailable = widget.event.maxTickets - widget.bookedCount;
    final totalPrice = widget.event.ticketPrice * _selectedTickets;
    final displayPriceText = widget.event.ticketPrice >= 1000
        ? "${(widget.event.ticketPrice / 1000).toInt()}k/Người"
        : "${_formatVND(widget.event.ticketPrice)}/Người";

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && widget.showNavbarOnPop) {
          context.read<MainPageProvider>().showNavbar();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF006D38),
        appBar: AppBar(
          backgroundColor: const Color(0xFF006D38),
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          title: const Text(
            "Đặt lịch sự kiện",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Thông tin sân
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005F31),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.map_outlined,
                                    color: Color(0xFFFFEC88),
                                    size: 20.0,
                                  ),
                                  SizedBox(width: 8.0),
                                  Text(
                                    "Thông tin sân",
                                    style: TextStyle(
                                      color: Color(0xFFFFEC88),
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12.0),

                              TitleText("Tên CLB: ", _venueName),

                              const SizedBox(height: 12.0),

                              TitleText("Địa chỉ: ", _venueAddress),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Card 2: Thông tin sự kiện
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005F31),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.confirmation_number_outlined,
                                    color: Color(0xFFFFEC88),
                                    size: 20.0,
                                  ),
                                  SizedBox(width: 8.0),
                                  Text(
                                    "Thông tin sự kiện",
                                    style: TextStyle(
                                      color: Color(0xFFFFEC88),
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12.0),

                              TitleText(
                                "Mã sự kiện: ",
                                "#${_getShortEventCode(widget.event.id)}",
                              ),

                              const SizedBox(height: 12.0),

                              TitleText("Tên sự kiện: ", widget.event.title),

                              const SizedBox(height: 12.0),

                              TitleText(
                                "Sân & Thời gian:",
                                " - ${widget.event.courtName}: ${widget.event.startTime} - ${widget.event.endTime}",
                              ),

                              const SizedBox(height: 12.0),

                              TitleText(
                                "Ngày: ",
                                _formatDate(widget.event.eventDate),
                              ),

                              const SizedBox(height: 12.0),

                              TitleText(
                                "Giá vé: ",
                                _formatDate(displayPriceText),
                              ),

                              const SizedBox(height: 12.0),

                              Row(
                                children: [
                                  const Text(
                                    "Trình độ: ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  const SizedBox(width: 4.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(
                                        100.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4.0),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3A8DEE),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.sports_tennis_rounded,
                                            color: Colors.white,
                                            size: 10.0,
                                          ),
                                        ),
                                        const SizedBox(width: 6.0),
                                        Text(
                                          widget.event.sportType,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        const SizedBox(width: 6.0),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0,
                                            vertical: 2.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3A8DEE),
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          child: Text(
                                            widget.event.level,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12.0),

                              TitleText(
                                "Số lượng vé còn lại: ",
                                "$maxAvailable",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Card 4: Số lượng vé muốn đặt
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005F31),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Số lượng vé muốn đặt",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: _selectedTickets > 1
                                            ? () => setState(
                                                () => _selectedTickets--,
                                              )
                                            : null,
                                        child: Container(
                                          width: 36.0,
                                          height: 36.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE5A93C),
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.remove,
                                            color: Colors.white,
                                            size: 20.0,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 80.0,
                                        height: 36.0,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2.0,
                                        ),
                                        alignment: Alignment.center,
                                        color: Colors.white,
                                        child: Text(
                                          "$_selectedTickets",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _selectedTickets < maxAvailable
                                            ? () => setState(
                                                () => _selectedTickets++,
                                              )
                                            : null,
                                        child: Container(
                                          width: 36.0,
                                          height: 36.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE5A93C),
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 20.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                      ),
                                      children: [
                                        const TextSpan(text: "Tổng tiền: "),
                                        TextSpan(
                                          text: _formatVND(totalPrice),
                                          style: const TextStyle(
                                            color: Color(0xFFFFEC88),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Section 6: Tên khách hàng
                        const Text(
                          "Tên khách hàng",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                          ),
                          decoration: InputDecoration(
                            hintText: "Nhập họ và tên",
                            hintStyle: const TextStyle(color: Colors.grey),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.grey,
                              ),
                              onPressed: () => _nameController.clear(),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập họ tên khách hàng';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        // Section 7: Số điện thoại
                        const Text(
                          "Số điện thoại liên hệ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                          ),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: "Nhập số điện thoại",
                            hintStyle: const TextStyle(color: Colors.grey),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.grey,
                              ),
                              onPressed: () => _phoneController.clear(),
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
                              return 'Số điện thoại không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        // Section 8: Ghi chú
                        const Text(
                          "Ghi chú",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _noteController,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                          ),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Nhập ghi chú (nếu có)",
                            hintStyle: const TextStyle(color: Colors.grey),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.grey,
                              ),
                              onPressed: () => _noteController.clear(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  color: const Color(0xFF006D38),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEC88),
                        foregroundColor: const Color(0xFF006D38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2.0,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.push(
                            "/EventPaymentConfirmPage",
                            extra: {
                              'event': widget.event,
                              'ticketCount': _selectedTickets,
                              'totalAmount': totalPrice,
                              'name': _nameController.text.trim(),
                              'phone': _phoneController.text.trim(),
                              'note': _noteController.text.trim(),
                            },
                          );
                        }
                      },
                      child: const Text(
                        "ĐĂNG KÝ VÀ THANH TOÁN",
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget TitleText(String title, String content) {
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        children: [
          TextSpan(
            text: content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
