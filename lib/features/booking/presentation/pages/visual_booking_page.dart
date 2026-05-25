import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexisport_app/features/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/booking/presentation/widgets/date_picker.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/features/booking/presentation/providers/booking_provider.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/sports_complex/presentation/providers/sports_complex_provider.dart';

// Trạng thái của từng ô thời gian
enum SlotStatus { empty, booked, locked, event }


// Model đại diện cho thông tin một ô giờ
class TimeSlot {
  final int index;
  final String timeLabel;
  final SlotStatus status;

  TimeSlot({
    required this.index,
    required this.timeLabel,
    required this.status,
  });
}

class VisualBookingPage extends StatefulWidget {
  final String venueId;
  const VisualBookingPage({super.key, required this.venueId});

  @override
  State<VisualBookingPage> createState() => _VisualBookingPageState();
}

class _VisualBookingPageState extends State<VisualBookingPage> {
  // Hệ số Phóng to / Thu nhỏ chiều rộng ô lưới (Zoom Factor)
  double _zoomFactor = 1.0;

  // Trạng thái giữ chỗ tạm thời
  Timer? _checkoutTimer;
  int _secondsRemaining = 300; // 5 phút đếm ngược
  String _userId = '';
  DateTime _selectedDate = DateTime(2026, 5, 21); // Thống nhất ngày mặc định

  String get _formattedQueryDate {
    final year = _selectedDate.year;
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 6;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 6, minute: 0);
  }

  List<String> _generateTimeLabels(String openTimeStr, String closeTimeStr) {
    final open = _parseTime(openTimeStr);
    final close = _parseTime(closeTimeStr);

    int startMinutes = open.hour * 60 + open.minute;
    int endMinutes = close.hour * 60 + close.minute;

    if (endMinutes <= startMinutes) {
      startMinutes = 6 * 60;
      endMinutes = 22 * 60;
    }

    final List<String> labels = [];
    int current = startMinutes;
    while (current < endMinutes) {
      final hour = current ~/ 60;
      final minute = current % 60;
      final hourStr = hour.toString().padLeft(2, '0');
      final minuteStr = minute.toString().padLeft(2, '0');
      labels.add("$hourStr:$minuteStr");
      current += 30; // 30 phút mỗi ô
    }
    return labels;
  }

  // Lưu trữ các trạng thái đặt lịch giả lập của từng sân
  // Key: courtId
  // Value: Map của <slotIndex, SlotStatus>
  final Map<String, Map<int, SlotStatus>> _bookingGrid = {};

  // Lưu trữ danh sách các ô giờ đang được người dùng chọn
  // Lưu dưới dạng chuỗi: "courtId_slotIndex"
  final Set<String> _selectedSlots = {};

  @override
  void initState() {
    super.initState();
    // Lấy thông tin UID từ Firebase, dự phòng guest_user
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      provider.loadCourts(widget.venueId).then((_) {
        provider.loadActiveLocks(widget.venueId, _formattedQueryDate);
      });
    });
  }

  @override
  void dispose() {
    _checkoutTimer?.cancel();
    // Giải phóng các ô giữ chỗ khi đóng trang để tránh giữ vô thời hạn
    if (_selectedSlots.isNotEmpty) {
      context.read<BookingProvider>().releaseAllUserLocks(
        venueId: widget.venueId,
        date: _formattedQueryDate,
        userId: _userId,
      );
    }
    super.dispose();
  }

  void _startCountdown() {
    _checkoutTimer?.cancel();
    setState(() {
      _secondsRemaining = 300;
    });
    _checkoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onCountdownExpired();
      }
    });
  }

  void _onCountdownExpired() {
    _checkoutTimer?.cancel();
    // Giải phóng tất cả ô giờ trên Supabase
    context.read<BookingProvider>().releaseAllUserLocks(
      venueId: widget.venueId,
      date: _formattedQueryDate,
      userId: _userId,
    );
    setState(() {
      _selectedSlots.clear();
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Hết thời gian giữ chỗ"),
        content: const Text("Đã quá 5 phút giữ chỗ tạm thời. Các ô giờ của bạn đã được giải phóng để người khác có thể đặt."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  String _formatTimeLimit(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  // Định dạng tiền tệ VND thủ công không dùng thư viện ngoài
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

  // Tính tổng số tiền dựa trên các ô đang chọn
  double _calculateTotalAmount(List<CourtEntity> courts) {
    double total = 0;
    for (var key in _selectedSlots) {
      final parts = key.split('_');
      final courtId = parts[0];
      final court = courts.firstWhere((c) => c.id == courtId);
      // Mỗi slot tương đương 30 phút (0.5 giờ)
      total += court.pricePerHour * 0.5;
    }
    return total;
  }

  // Xử lý sự kiện khi chạm vào một ô lưới giờ
  void _onSlotTap(String courtId, int slotIndex, SlotStatus status) async {
    if (status != SlotStatus.empty) return; // Chỉ cho phép chọn ô trống

    final slotKey = "${courtId}_$slotIndex";
    final isSelected = _selectedSlots.contains(slotKey);
    final bookingProvider = context.read<BookingProvider>();

    if (isSelected) {
      // Hủy chọn: giải phóng giữ chỗ trên Supabase
      setState(() {
        _selectedSlots.remove(slotKey);
        if (_selectedSlots.isEmpty) {
          _checkoutTimer?.cancel();
        }
      });
      try {
        await bookingProvider.releaseCourtSlot(
          venueId: widget.venueId,
          courtId: courtId,
          slotIndex: slotIndex,
          date: _formattedQueryDate,
          userId: _userId,
        );
      } catch (e) {
        debugPrint("Lỗi giải phóng giữ chỗ: $e");
      }
    } else {
      // Chọn mới: tiến hành giữ chỗ tạm thời trên Supabase
      final success = await bookingProvider.holdCourtSlot(
        venueId: widget.venueId,
        courtId: courtId,
        slotIndex: slotIndex,
        date: _formattedQueryDate,
        userId: _userId,
      );

      if (success) {
        setState(() {
          _selectedSlots.add(slotKey);
          if (_selectedSlots.length == 1) {
            _startCountdown();
          }
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ô thời gian này vừa mới được đặt hoặc có người giữ chỗ trước!"),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final courts = bookingProvider.courts;

    final sportsComplexProvider = context.watch<SportsComplexProvider>();
    SportsComplexEntity? foundVenue;
    for (final s in sportsComplexProvider.stadiums) {
      if (s.id == widget.venueId) {
        foundVenue = s;
        break;
      }
    }
    final venue = foundVenue ?? SportsComplexEntity(
      id: widget.venueId,
      name: 'Sân chơi',
      address: '',
      imageUrl: '',
      rating: 5.0,
      open_time: '06:00',
      close_time: '22:00',
    );

    final timeLabels = _generateTimeLabels(venue.open_time, venue.close_time);

    if (bookingProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAF7),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF016B34)),
          ),
        ),
      );
    }

    if (bookingProvider.errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAF7),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Đã xảy ra lỗi: ${bookingProvider.errorMessage}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<BookingProvider>().loadCourts(widget.venueId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 1, 107, 52),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Tải lại"),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (courts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAF7),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 1, 107, 52),
          elevation: 0,
          title: const Text(
            "Đặt lịch ngày trực quan",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            onPressed: () {
              context.pop();
              context.read<MainPageProvider>().showNavbar();
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            "Không có sân nào được tìm thấy tại cơ sở này.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    // Khởi tạo/cập nhật grid đặt sân động dựa trên danh sách sân thực tế
    for (int idx = 0; idx < courts.length; idx++) {
      final court = courts[idx];
      if (!_bookingGrid.containsKey(court.id)) {
        final map = <int, SlotStatus>{};
        for (int i = 0; i < timeLabels.length; i++) {
          map[i] = SlotStatus.empty;
        }
        _bookingGrid[court.id] = map;

        // Gán trạng thái giả lập cho đẹp mắt dựa trên index
        if (idx == 0) {
          if (timeLabels.isNotEmpty) map[0] = SlotStatus.locked;
          if (timeLabels.length > 1) map[1] = SlotStatus.locked;
          if (timeLabels.length > 2) map[2] = SlotStatus.locked;
          if (timeLabels.length > 4) map[4] = SlotStatus.booked;
          if (timeLabels.length > 5) map[5] = SlotStatus.booked;
          if (timeLabels.length > 6) map[6] = SlotStatus.booked;
        } else if (idx == 1) {
          if (timeLabels.isNotEmpty) map[0] = SlotStatus.locked;
          if (timeLabels.length > 1) map[1] = SlotStatus.locked;
          if (timeLabels.length > 2) map[2] = SlotStatus.locked;
          if (timeLabels.length > 3) map[3] = SlotStatus.locked;
          if (timeLabels.length > 22) map[22] = SlotStatus.booked;
          if (timeLabels.length > 23) map[23] = SlotStatus.booked;
          if (timeLabels.length > 24) map[24] = SlotStatus.booked;
          if (timeLabels.length > 25) map[25] = SlotStatus.booked;
        } else if (idx == 2) {
          if (timeLabels.length > 16) map[16] = SlotStatus.event;
          if (timeLabels.length > 17) map[17] = SlotStatus.event;
          if (timeLabels.length > 18) map[18] = SlotStatus.event;
          if (timeLabels.length > 19) map[19] = SlotStatus.event;
        }
      }
    }

    // Chiều rộng cơ bản của một ô giờ, nhân với hệ số zoom factor
    final double cellWidth = 70.0 * _zoomFactor;
    const double cellHeight = 60.0;
    const double courtColumnWidth = 100.0;
    const double headerHeight = 40.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 107, 52),
        elevation: 0,
        title: const Text(
          "Đặt lịch ngày trực quan",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () {
            context.pop();
            context.read<MainPageProvider>().showNavbar();
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header màu xanh chứa DatePicker & Legends
            Container(
              color: const Color.fromARGB(255, 1, 107, 52),       
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: DatePickerButton(
                      selectedDate: _selectedDate,
                      onDateChanged: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                          // Khi đổi ngày, chúng ta cần xoá các ô đang chọn cũ và tắt đếm ngược
                          _selectedSlots.clear();
                          _checkoutTimer?.cancel();
                        });
                        // Load lại các khóa giữ chỗ cho ngày mới
                        context.read<BookingProvider>().loadActiveLocks(widget.venueId, _formattedQueryDate);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem(
                        color: Colors.white,
                        borderColor: Colors.grey.shade400,
                        label: "Trống",
                      ),
                      _buildLegendItem(
                        color: const Color(0xFFFF8A80),
                        label: "Đã đặt",
                      ),
                      _buildLegendItem(
                        color: Colors.grey.shade400,
                        label: "Khoá",
                      ),
                      _buildLegendItem(
                        color: const Color(0xFFCE93D8),
                        label: "Sự kiện",
                        icon: Icons.priority_high,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 22, top: 4),
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      child: const Text(
                        "Xem sân & bảng giá",
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.yellowAccent,
                          decorationThickness: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Banner lưu ý/cảnh báo màu xanh ngọc nhạt
            Container(
              width: double.infinity,
              color: const Color(0xFFE0F2F1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, height: 1.3),
                  children: [
                    TextSpan(
                      text: "Lưu ý: ",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: "Nếu bạn cần đặt lịch cố định vui lòng liên hệ: ",
                      style: TextStyle(color: Color(0xFF004D40)),
                    ),
                    TextSpan(
                      text: "0388.533.159",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: " để được hỗ trợ.",
                      style: TextStyle(color: Color(0xFF004D40)),
                    ),
                  ],
                ),
              ),
            ),

            // Lưới Đặt Sân Cuộn 2 Chiều Đồng Bộ
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột Tên Sân cố định (Frozen Column)
                    Column(
                      children: [
                        // Ô góc trên bên trái (Giao giữa Header giờ và Sân)
                        Container(
                          width: courtColumnWidth,
                          height: headerHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                              right: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Sân",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                          ),
                        ),
                        // Danh sách tên sân
                        ...courts.map((court) {
                          return Container(
                            width: courtColumnWidth,
                            height: cellHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                                right: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              court.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                    ),

                    // Vùng Lưới Giờ cuộn ngang (Scrollable Columns)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dòng Header Khung Giờ
                            Row(
                              children: List.generate(timeLabels.length, (index) {
                                return Container(
                                  width: cellWidth,
                                  height: headerHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                                      right: BorderSide(color: Colors.grey.shade200, width: 1),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        timeLabels[index],
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        width: 2,
                                        height: 6,
                                        color: Colors.orange.shade400,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),

                            // Các dòng Lưới Ô giờ tương ứng từng Sân
                            Column(
                              children: courts.map((court) {
                                final courtSlots = _bookingGrid[court.id] ?? {};
                                return Row(
                                  children: List.generate(timeLabels.length, (slotIndex) {
                                    var status = courtSlots[slotIndex] ?? SlotStatus.empty;

                                    // Kiểm tra xem ô này có bị người dùng khác giữ chỗ hay không
                                    final isLockedByOther = bookingProvider.activeLocks.any((lock) =>
                                        lock.courtId == court.id &&
                                        lock.slotIndex == slotIndex &&
                                        lock.userId != _userId &&
                                        !lock.isExpired);

                                    if (isLockedByOther) {
                                      status = SlotStatus.locked; // Hiển thị là đã khoá
                                    }

                                    final slotKey = "${court.id}_$slotIndex";
                                    final isSelected = _selectedSlots.contains(slotKey);

                                    return GestureDetector(
                                      onTap: () => _onSlotTap(court.id, slotIndex, status),
                                      child: _buildGridCell(
                                        status: status,
                                        isSelected: isSelected,
                                        width: cellWidth,
                                        height: cellHeight,
                                      ),
                                    );
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Phần thanh điều khiển và Checkout Bar ở dưới cùng
             _buildBottomControls(courts),
          ],
        ),
      ),
    );
  }

  // Widget xây dựng ô lưới chi tiết
  Widget _buildGridCell({
    required SlotStatus status,
    required bool isSelected,
    required double width,
    required double height,
  }) {
    Color cellColor = Colors.white;
    BorderSide borderSide = BorderSide(color: Colors.grey.shade200, width: 0.8);
    Widget? child;

    if (isSelected) {
      cellColor = const Color(0xFF81C784); // Xanh lá dịu mắt khi chọn
      borderSide = const BorderSide(color: Color(0xFF388E3C), width: 1.2);
      child = const Icon(Icons.check_circle, color: Colors.white, size: 18);
    } else {
      switch (status) {
        case SlotStatus.empty:
          cellColor = Colors.white;
          break;
        case SlotStatus.booked:
          cellColor = const Color(0xFFFFCDD2); // Đỏ pastel
          borderSide = BorderSide(color: Colors.red.shade200, width: 0.8);
          child = Icon(Icons.block_flipped, color: Colors.red.shade400, size: 16);
          break;
        case SlotStatus.locked:
          cellColor = const Color(0xFFE0E0E0); // Xám
          borderSide = BorderSide(color: Colors.grey.shade400, width: 0.8);
          child = Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 16);
          break;
        case SlotStatus.event:
          cellColor = const Color(0xFFE1BEE7); // Tím pastel
          borderSide = BorderSide(color: Colors.purple.shade200, width: 0.8);
          child = Icon(Icons.priority_high_rounded, color: Colors.purple.shade700, size: 16);
          break;
      }
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cellColor,
        border: Border(
          right: borderSide,
          bottom: borderSide,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  // Thanh điều khiển Zoom Slider và thanh Checkout nổi
   Widget _buildBottomControls(List<CourtEntity> courts) {
    final hasSelection = _selectedSlots.isNotEmpty;
    final totalAmount = _calculateTotalAmount(courts);
    final totalHours = _selectedSlots.length * 0.5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hiển thị đếm ngược giữ chỗ tạm thời nếu có sân đang chọn
          if (hasSelection)
            Container(
              width: double.infinity,
              color: Colors.amber.shade50,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      children: [
                        const TextSpan(text: "Bạn có "),
                        TextSpan(
                          text: _formatTimeLimit(_secondsRemaining),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const TextSpan(text: " để hoàn tất đặt chỗ trước khi các ô giờ bị giải phóng."),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Zoom Slider Capsule Card floating (giống ảnh thực tế)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0A000000),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.zoom_out, color: Colors.grey.shade600, size: 20),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF4CAF50),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: const Color(0xFF4CAF50),
                        overlayColor: const Color(0x1F4CAF50),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _zoomFactor,
                        min: 0.7,
                        max: 2.0,
                        onChanged: (value) {
                          setState(() {
                            _zoomFactor = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Icon(Icons.zoom_in, color: Colors.grey.shade600, size: 20),
                ],
              ),
            ),
          ),

          // Checkout Summary & Nút TIẾP THEO
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Thông tin tóm tắt bên trái
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                            children: [
                              const TextSpan(text: "Đã chọn: "),
                              TextSpan(
                                text: "${_selectedSlots.length} ô",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF016B34)),
                              ),
                              TextSpan(text: " ($totalHours giờ)"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasSelection ? _formatVND(totalAmount) : "0 đ",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút TIẾP THEO
                  ElevatedButton(
                    onPressed: hasSelection
                        ? () {
                            // Xử lý chuyển bước thanh toán
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Xác nhận"),
                                content: Text("Bạn đã chọn đặt $totalHours giờ chơi.\nTổng cộng: ${_formatVND(totalAmount)}"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Huỷ"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // Thêm logic chuyển tiếp tại đây
                                    },
                                    child: const Text("Tiếp tục"),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2A62C), // Màu vàng cam gold chuyên nghiệp
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "TIẾP THEO",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper tạo Legend item
  Widget _buildLegendItem({
    required Color color,
    Color? borderColor,
    required String label,
    IconData? icon,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null ? Border.all(color: borderColor, width: 0.8) : null,
          ),
          child: icon != null ? Icon(icon, color: Colors.white, size: 14) : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
