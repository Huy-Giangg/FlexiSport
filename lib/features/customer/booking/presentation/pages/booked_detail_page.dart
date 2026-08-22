import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookedDetailPage extends StatefulWidget {
  final Map<String, dynamic>? booking;
  const BookedDetailPage({super.key, this.booking});

  @override
  State<BookedDetailPage> createState() => _BookedDetailPageState();
}

class _BookedDetailPageState extends State<BookedDetailPage> {
  bool _isLoading = true;
  String _customerName = 'hgtr';
  String _customerPhone = '0987654725';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final bName = widget.booking?['customer_name']?.toString() ?? '';
    final bPhone = widget.booking?['customer_phone']?.toString() ?? '';

    if (bName.isNotEmpty || bPhone.isNotEmpty) {
      setState(() {
        if (bName.isNotEmpty) _customerName = bName;
        if (bPhone.isNotEmpty) _customerPhone = bPhone;
        _isLoading = false;
      });
      return;
    }

    final userId = widget.booking?['user_id']?.toString() ?? '';
    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _customerName = data['name']?.toString() ?? _customerName;
          _customerPhone = data['phone']?.toString() ?? _customerPhone;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin KH: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return const TimeOfDay(hour: 6, minute: 0);
  }

  DateTime? _getBookingEndDateTime(List slots, String openTime, String closeTime) {
    if (slots.isEmpty) return null;
    
    final String dateStr = slots.first['booking_date']?.toString() ?? '';
    if (dateStr.isEmpty) return null;
    
    final dateParts = dateStr.split('-');
    if (dateParts.length != 3) return null;
    final year = int.tryParse(dateParts[0]) ?? 0;
    final month = int.tryParse(dateParts[1]) ?? 0;
    final day = int.tryParse(dateParts[2]) ?? 0;
    
    final open = _parseTime(openTime);
    final close = _parseTime(closeTime);
    int startMinutes = open.hour * 60 + open.minute;
    int endMinutes = close.hour * 60 + close.minute;
    if (endMinutes <= startMinutes) {
      startMinutes = 6 * 60;
      endMinutes = 22 * 60;
    }
    
    final List<int> startMinutesList = [];
    int current = startMinutes;
    while (current < endMinutes) {
      startMinutesList.add(current);
      current += 30;
    }
    
    final List<int> indices = slots.map((s) => s['slot_index'] as int? ?? 0).toList();
    if (indices.isEmpty) return null;
    indices.sort();
    final maxIdx = indices.last;
    
    if (maxIdx < startMinutesList.length) {
      final startMin = startMinutesList[maxIdx];
      final endMin = startMin + 30;
      final endHour = endMin ~/ 60;
      final endMinute = endMin % 60;
      
      return DateTime(year, month, day, endHour, endMinute);
    }
    return null;
  }

  bool _isBookingPassed(List slots, String openTime, String closeTime) {
    final endDateTime = _getBookingEndDateTime(slots, openTime, closeTime);
    if (endDateTime == null) return false;
    return DateTime.now().isAfter(endDateTime);
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

  String _getSportType(List slots) {
    if (slots.isEmpty) return 'Pickleball';
    for (var slot in slots) {
      final courtName = slot['courts']?['name']?.toString().toLowerCase() ?? '';
      if (courtName.contains('pickleball')) return 'Pickleball';
      if (courtName.contains('tennis')) return 'Tennis';
      if (courtName.contains('cầu lông') || courtName.contains('badminton')) return 'Cầu lông';
      if (courtName.contains('bóng đá') || courtName.contains('football') || courtName.contains('soccer')) return 'Bóng đá';
    }
    return 'Pickleball';
  }

  List<Widget> _buildSlotDetailsWidgets(List slots, String openTime, String closeTime) {
    if (slots.isEmpty) return [];

    final Map<String, List<int>> courtToSlots = {};
    final Map<String, String> courtNames = {};
    for (var slot in slots) {
      final courtId = slot['court_id']?.toString() ?? '';
      final courtName = slot['courts']?['name']?.toString() ?? 'Sân';
      final slotIndex = slot['slot_index'] as int? ?? 0;
      courtNames[courtId] = courtName;
      courtToSlots.putIfAbsent(courtId, () => []).add(slotIndex);
    }

    final open = _parseTime(openTime);
    final close = _parseTime(closeTime);
    int startMinutes = open.hour * 60 + open.minute;
    int endMinutes = close.hour * 60 + close.minute;
    if (endMinutes <= startMinutes) {
      startMinutes = 6 * 60;
      endMinutes = 22 * 60;
    }
    final List<String> timeLabels = [];
    int current = startMinutes;
    while (current < endMinutes) {
      timeLabels.add("${(current ~/ 60).toString().padLeft(2, '0')}:${(current % 60).toString().padLeft(2, '0')}");
      current += 30;
    }

    final List<Widget> widgets = [];

    for (var entry in courtToSlots.entries) {
      final courtId = entry.key;
      final courtName = courtNames[courtId] ?? 'Sân';
      final indices = entry.value..sort();

      final List<String> ranges = [];
      int i = 0;
      while (i < indices.length) {
        int startIdx = indices[i];
        int endIdx = startIdx;
        while (i + 1 < indices.length && indices[i + 1] == endIdx + 1) {
          endIdx = indices[i + 1];
          i++;
        }

        if (startIdx < timeLabels.length && endIdx < timeLabels.length) {
          final startStr = timeLabels[startIdx];
          final endBaseStr = timeLabels[endIdx];
          final timeParts = endBaseStr.split(':');
          if (timeParts.length >= 2) {
            int hour = int.tryParse(timeParts[0]) ?? 0;
            int minute = int.tryParse(timeParts[1]) ?? 0;
            int endMinute = minute + 30;
            int endHour = hour;
            if (endMinute >= 60) {
              endMinute -= 60;
              endHour += 1;
            }

            final startParts = startStr.split(':');
            final startH = int.tryParse(startParts[0]) ?? 0;
            final startM = startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0;
            final startFormatted = startM > 0 ? "${startH}h$startM" : "${startH}h";
            final endFormatted = endMinute > 0 ? "${endHour}h$endMinute" : "${endHour}h";

            ranges.add("$startFormatted - $endFormatted");
          }
        }
        i++;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "- $courtName: ${ranges.join(', ')}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    if (booking == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF006D38),
        appBar: _buildAppBar(),
        body: const Center(
          child: Text(
            "Không tìm thấy thông tin chi tiết đơn đặt lịch",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final status = booking['status']?.toString() ?? 'pending';
    final slots = booking['booking_slots'] as List? ?? [];
    final double totalAmount = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;

    String venueName = 'CLB Thể Thao';
    String venueAddress = 'Chưa cập nhật địa chỉ';
    String venuePhone = '0398508386'; // Mock mặc định theo thiết kế
    String openTime = '06:00';
    String closeTime = '22:00';
    String bookingDateStr = '';

    if (slots.isNotEmpty) {
      final firstSlot = slots.first;
      bookingDateStr = _formatDate(firstSlot['booking_date']?.toString() ?? '');
      final court = firstSlot['courts'];
      if (court != null) {
        final venue = court['venues'];
        if (venue != null) {
          venueName = venue['name']?.toString() ?? 'CLB Thể Thao';
          venueAddress = venue['address']?.toString() ?? 'Chưa cập nhật địa chỉ';
          venuePhone = venue['phone']?.toString() ?? '0398508386';
          openTime = venue['open_time']?.toString() ?? '06:00';
          closeTime = venue['close_time']?.toString() ?? '22:00';
        }
      }
    }

    final double totalHours = slots.length * 0.5;
    final int hours = totalHours.toInt();
    final int minutes = ((totalHours - hours) * 60).toInt();
    final String durationStr = hours > 0
        ? "${hours}h${minutes > 0 ? minutes.toString() : ''}"
        : "$minutes phút";

    final sportType = _getSportType(slots);

    final hasPassed = status != 'cancelled' && _isBookingPassed(slots, openTime, closeTime);

    // Trạng thái đơn đặt
    String statusText = 'Chờ chủ sân xác nhận';
    Color statusTextColor = const Color(0xFFE2A62C); // màu vàng như hình

    if (hasPassed) {
      statusText = 'Thành công';
      statusTextColor = const Color(0xFF1EC391);
    } else if (status == 'completed') {
      statusText = 'Đã xác nhận';
      statusTextColor = const Color(0xFF1EC391);
    } else if (status == 'cancelled') {
      statusText = 'Đã huỷ';
      statusTextColor = Colors.redAccent;
    }

    // Trạng thái thanh toán
    String paymentStatusText = 'Chưa thanh toán';
    Color paymentStatusColor = const Color(0xFFE2A62C); // màu vàng như hình
    if (hasPassed || status == 'completed') {
      paymentStatusText = 'Đã thanh toán';
      paymentStatusColor = const Color(0xFF1EC391);
    }

    // Mã đặt lịch ngắn
    final shortCode = booking['id'].toString().substring(0, 5).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF006D38), // Màu nền xanh lá đậm tối
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Card 1: Khách hàng
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005F31), // Màu xanh lá sáng hơn nền một chút
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.purple,
                            child: Text(
                              _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRowInfo("Khách hàng", _customerName),
                                const SizedBox(height: 12),
                                _buildRowInfo("Đối tượng", sportType),
                                const SizedBox(height: 12),
                                _buildRowInfo("Số điện thoại", _customerPhone),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Thông tin đặt lịch
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005F31),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề Thông tin
                          Row(
                            children: const [
                              Icon(
                                Icons.assignment_outlined,
                                color: Color(0xFFE2A62C),
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Thông tin",
                                style: TextStyle(
                                  color: Color(0xFFE2A62C),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Mã đặt lịch
                          _buildFieldRow("Mã lịch đặt", "#$shortCode", valueColor: const Color(0xFFE2A62C)),
                          _buildDivider(),

                          // Trạng thái
                          _buildFieldRow("Trạng thái", statusText, valueColor: statusTextColor),
                          _buildDivider(),

                          // Tên CLB
                          _buildFieldRow("Tên CLB", venueName.toUpperCase()),
                          _buildDivider(),

                          // Địa chỉ
                          _buildFieldRow("Địa chỉ", venueAddress),
                          _buildDivider(),

                          // Số điện thoại CLB + icon gọi điện
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: "Số điện thoại: ",
                                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                                    children: [
                                      TextSpan(
                                        text: venuePhone,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: venuePhone));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã sao chép số điện thoại $venuePhone vào bộ nhớ tạm!'),
                                      backgroundColor: const Color(0xFF006D38),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          _buildDivider(),

                          // Ngày
                          _buildFieldRow("Ngày", bookingDateStr),
                          
                          // Các sân đặt chi tiết
                          ..._buildSlotDetailsWidgets(slots, openTime, closeTime),
                          _buildDivider(),

                          // Tổng giờ
                          _buildFieldRow("Tổng giờ", durationStr),
                          _buildDivider(),

                          // Tổng giảm giá
                          _buildFieldRow("Tổng giảm giá", _formatVND(0.0)),
                          _buildDivider(),

                          // Tổng tiền
                          _buildFieldRow("Tổng tiền", _formatVND(totalAmount)),
                          _buildDivider(),

                          // Trạng thái thanh toán
                          _buildFieldRow("Trạng thái thanh toán", paymentStatusText, valueColor: paymentStatusColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Ghi chú
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005F31),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: "Khách hàng ghi chú: ",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: (widget.booking?['note']?.toString() ?? '').isNotEmpty
                                      ? (widget.booking?['note']?.toString() ?? '')
                                      : "Không có",
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFFE2A62C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: const TextSpan(
                              text: "Chủ sân ghi chú: ",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: "Không có",
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFFE2A62C),
                                    fontWeight: FontWeight.w500,
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        "Chi tiết đặt sân",
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildRowInfo(String label, String value) {
    return RichText(
      text: TextSpan(
        text: "$label: ",
        style: const TextStyle(color: Colors.white70, fontSize: 16),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, {Color? valueColor}) {
    return RichText(
      text: TextSpan(
        text: "$label: ",
        style: const TextStyle(color: Colors.white70, fontSize: 16),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Divider(
        color: Colors.white.withOpacity(0.1),
        height: 1,
      ),
    );
  }
}
