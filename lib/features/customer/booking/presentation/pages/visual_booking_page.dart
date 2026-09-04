import 'package:flexisport_app/core/services/court_pricing_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/customer/booking/data/models/court_model.dart';
import 'package:flexisport_app/features/customer/booking/presentation/widgets/date_picker.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/features/customer/booking/presentation/providers/booking_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/data/models/sports_complex_model.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/payment_info_page.dart';

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

  String _userId = '';
  SportsComplexEntity? _venue;
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ); // Mặc định là ngày hôm nay (chỉ lấy phần ngày)

  String get _formattedQueryDate {
    final year = _selectedDate.year;
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  TimeOfDay _parseTime(String timeStr, {TimeOfDay fallback = const TimeOfDay(hour: 6, minute: 0)}) {
    final cleaned = timeStr.trim();
    if (cleaned.isEmpty) return fallback;
    final parts = cleaned.split(':');
    if (parts.isNotEmpty) {
      final hour = int.tryParse(parts[0]) ?? fallback.hour;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? fallback.minute) : 0;
      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    }
    return fallback;
  }

  bool _isSlotInPast(int slotIndex, String openTime) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    // 1. Nếu là ngày trong quá khứ -> toàn bộ ô đều bị khóa
    if (selectedDateOnly.isBefore(todayDate)) {
      return true;
    }
    // 2. Nếu là ngày trong tương lai (từ ngày mai trở đi) -> toàn bộ ô đều khả dụng
    if (selectedDateOnly.isAfter(todayDate)) {
      return false;
    }
    
    // 3. Nếu là ngày hôm nay -> chỉ khóa các ô đã kết thúc trước giờ hiện tại
    final open = _parseTime(openTime, fallback: const TimeOfDay(hour: 6, minute: 0));
    final startMinutes = open.hour * 60 + open.minute;
    final slotEndMinutes = startMinutes + (slotIndex + 1) * 30; // Thời điểm kết thúc ca này
    final currentMinutes = now.hour * 60 + now.minute;
    
    return slotEndMinutes <= currentMinutes;
  }

  List<String> _generateTimeLabels(String openTimeStr, String closeTimeStr) {
    final open = _parseTime(openTimeStr, fallback: const TimeOfDay(hour: 6, minute: 0));
    final close = _parseTime(closeTimeStr, fallback: const TimeOfDay(hour: 22, minute: 0));

    int startMinutes = open.hour * 60 + open.minute;
    int endMinutes = close.hour * 60 + close.minute;

    if (endMinutes <= startMinutes) {
      startMinutes = 6 * 60;
      endMinutes = 22 * 60;
    }

    final List<String> labels = [];
    int current = startMinutes;
    while (current <= endMinutes) {
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

  late BookingProvider _bookingProvider;

  bool _isVenueLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookingProvider = Provider.of<BookingProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    // Lấy thông tin UID từ Supabase, dự phòng guest_user
    _userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest_user';
    _loadVenueData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      provider.loadCourts(widget.venueId).then((_) {
        provider.loadActiveLocks(widget.venueId, _formattedQueryDate);
        provider.loadBookedSlots(widget.venueId, _formattedQueryDate);
        provider.loadCourtBlocks(widget.venueId, _formattedQueryDate);
        provider.loadEventSlots(widget.venueId, _formattedQueryDate);
        provider.loadEvents(widget.venueId);
      });
    });
  }

  Future<void> _loadVenueData() async {
    try {
      final res = await Supabase.instance.client
          .from('venues')
          .select('id, name, address, rating, open_time, close_time, latitude, longitude, sports_type, logo_url')
          .eq('id', widget.venueId)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() {
          _venue = SportsComplexModel.fromJson(res);
          _isVenueLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin venue: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isVenueLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_selectedSlots.isNotEmpty) {
      _bookingProvider.releaseAllUserLocks(
        venueId: widget.venueId,
        date: _formattedQueryDate,
        userId: _userId,
      );
    }
    super.dispose();
  }

  // Kiểm tra xem ô này có thuộc sự kiện/giải đấu không
  bool _isEventSlot(CourtEntity court, int slotIndex, BookingProvider bookingProvider, SportsComplexEntity venue) {
    // 1. Kiểm tra qua bảng event_slots
    final hasEventSlot = bookingProvider.eventSlots.any((e) {
      final evDateClean = e.eventDate.split('T')[0].split(' ')[0].trim();
      return e.courtId == court.id &&
          e.slotIndex == slotIndex &&
          (evDateClean == _formattedQueryDate || e.eventDate == _formattedQueryDate);
    });
    if (hasEventSlot) return true;

    // 2. Dự phòng trực tiếp từ bảng events
    if (bookingProvider.events.isNotEmpty) {
      final openT = _parseTime(venue.open_time, fallback: const TimeOfDay(hour: 6, minute: 0));
      final slotStartMin = openT.hour * 60 + openT.minute + slotIndex * 30;
      final slotEndMin = slotStartMin + 30;

      for (final ev in bookingProvider.events) {
        if (!ev.isActive) continue;

        final evDateClean = ev.eventDate.split('T')[0].split(' ')[0].trim();
        if (evDateClean != _formattedQueryDate) continue;

        final courtNameClean = court.name.trim().toLowerCase();
        final evCourtClean = ev.courtName.trim().toLowerCase();

        final isSameCourt = courtNameClean == evCourtClean ||
            evCourtClean.contains(courtNameClean) ||
            courtNameClean.contains(evCourtClean);

        if (isSameCourt) {
          final evStart = _parseTime(ev.startTime, fallback: const TimeOfDay(hour: 15, minute: 0));
          final evEnd = _parseTime(ev.endTime, fallback: const TimeOfDay(hour: 18, minute: 0));

          final evStartMin = evStart.hour * 60 + evStart.minute;
          final evEndMin = evEnd.hour * 60 + evEnd.minute;

          if (slotStartMin < evEndMin && slotEndMin > evStartMin) {
            return true;
          }
        }
      }
    }
    return false;
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
  double _calculateTotalAmount(List<CourtEntity> courts, String openTime) {
    double total = 0;
    for (var key in _selectedSlots) {
      final lastUnderscore = key.lastIndexOf('_');
      if (lastUnderscore == -1) continue;
      final courtId = key.substring(0, lastUnderscore);
      final slotIndex = int.tryParse(key.substring(lastUnderscore + 1)) ?? 0;
      final court = courts.firstWhere(
        (c) => c.id == courtId,
        orElse: () => CourtModel(id: courtId, name: 'Sân', pricePerHour: 140000.0, venueId: widget.venueId),
      );
      total += CourtPricingService.instance.calculateSlotPrice(
        courtId: court.id,
        slotIndex: slotIndex,
        date: _selectedDate,
        openTime: openTime,
        fallbackBasePrice: court.pricePerHour,
      );
    }
    return total;
  }

  // Xử lý sự kiện khi chạm vào một ô lưới giờ
  void _onSlotTap(String courtId, int slotIndex, SlotStatus status, {bool isPast = false}) {
    final bookingProvider = context.read<BookingProvider>();
    final court = bookingProvider.courts.firstWhere(
      (c) => c.id == courtId,
      orElse: () => CourtModel(id: courtId, name: 'Sân', pricePerHour: 140000.0, venueId: widget.venueId),
    );

    final slotKey = "${courtId}_$slotIndex";
    final isSelected = _selectedSlots.contains(slotKey);

    // 1. Nếu ô này đã được chọn -> Bấm vào để hủy chọn ngay lập tức và giải phóng giữ chỗ
    if (isSelected) {
      setState(() {
        _selectedSlots.remove(slotKey);
      });
      bookingProvider.releaseCourtSlot(
        venueId: widget.venueId,
        courtId: courtId,
        slotIndex: slotIndex,
        date: _formattedQueryDate,
        userId: _userId,
      );
      return;
    }

    // 2. Khung giờ đã qua trong ngày (quá khứ) -> Chặn và thông báo
    if (isPast) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Khung giờ này đã qua trong ngày hôm nay, vui lòng chọn khung giờ khác hoặc chuyển sang ngày mai."),
            backgroundColor: Colors.grey.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 3. Sân bảo trì -> Chặn và thông báo
    if (!court.isActive || court.status == 'maintenance') {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sân \"${court.name}\" đang trong thời gian bảo trì, vui lòng chọn sân khác."),
            backgroundColor: const Color(0xFFED6C02),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 4. Ô đã có người đặt, tạm khóa hoặc là sự kiện -> Chặn và thông báo
    if (status != SlotStatus.empty) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == SlotStatus.booked
                ? "Ô thời gian này đã có người đặt trước!"
                : (status == SlotStatus.event
                    ? "Ô thời gian này đang diễn ra sự kiện thể thao!"
                    : "Ô thời gian này đang tạm khóa.")),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 5. Chọn mới ô này thành công -> Cập nhật UI và giữ chỗ tức thì trong DB
    setState(() {
      _selectedSlots.add(slotKey);
    });
    bookingProvider.holdCourtSlot(
      venueId: widget.venueId,
      courtId: courtId,
      slotIndex: slotIndex,
      date: _formattedQueryDate,
      userId: _userId,
    );
  }

  List<SelectedSlotDetail> _buildSelectedSlotDetails(List<CourtEntity> courts, List<String> timeLabels, String openTime) {
    final List<SelectedSlotDetail> list = [];

    // 1. Phân nhóm các slotIndex theo courtId
    final Map<String, List<int>> courtToSlots = {};
    for (var key in _selectedSlots) {
      final lastUnderscore = key.lastIndexOf('_');
      if (lastUnderscore == -1) continue;
      final courtId = key.substring(0, lastUnderscore);
      final slotIndex = int.tryParse(key.substring(lastUnderscore + 1)) ?? 0;
      courtToSlots.putIfAbsent(courtId, () => []).add(slotIndex);
    }

    // 2. Với mỗi sân, sắp xếp các index và gộp các ô liền kề
    for (var entry in courtToSlots.entries) {
      final courtId = entry.key;
      final slotIndices = entry.value..sort(); // Sắp xếp tăng dần

      CourtEntity? court;
      for (final c in courts) {
        if (c.id == courtId) {
          court = c;
          break;
        }
      }
      if (court == null) continue;

      // 3. Thuật toán gộp các khoảng liền kề
      int i = 0;
      while (i < slotIndices.length) {
        int startIdx = slotIndices[i];
        int endIdx = startIdx;

        // Tìm điểm kết thúc của chuỗi liên tục
        while (i + 1 < slotIndices.length && slotIndices[i + 1] == endIdx + 1) {
          endIdx = slotIndices[i + 1];
          i++;
        }

        // Tạo chuỗi thời gian hiển thị từ startIdx đến endIdx
        final startTimeStr = timeLabels[startIdx];
        final endTimeBaseStr = timeLabels[endIdx];

        // Tính thời gian kết thúc thực tế của slot cuối cùng (endTimeBaseStr + 30 phút)
        final timeParts = endTimeBaseStr.split(':');
        String formattedTimeRange = startTimeStr;
        if (timeParts.length >= 2) {
          int hour = int.tryParse(timeParts[0]) ?? 0;
          int minute = int.tryParse(timeParts[1]) ?? 0;
          int endMinute = minute + 30;
          int endHour = hour;
          if (endMinute >= 60) {
            endMinute -= 60;
            endHour += 1;
          }

          final startParts = startTimeStr.split(':');
          int startHour = int.tryParse(startParts[0]) ?? 0;
          int startMinute = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;

          final startStr = "${startHour.toString().padLeft(2, '0')}h${startMinute.toString().padLeft(2, '0')}";
          final endStr = "${endHour.toString().padLeft(2, '0')}h${endMinute.toString().padLeft(2, '0')}";
          formattedTimeRange = "$startStr - $endStr";
        }

        double totalPrice = 0.0;
        for (int s = startIdx; s <= endIdx; s++) {
          totalPrice += CourtPricingService.instance.calculateSlotPrice(
            courtId: court.id,
            slotIndex: s,
            date: _selectedDate,
            openTime: openTime,
            fallbackBasePrice: court.pricePerHour,
          );
        }

        list.add(SelectedSlotDetail(
          courtName: court.name,
          timeRange: formattedTimeRange,
          price: totalPrice,
        ));

        i++;
      }
    }

    return list;
  }

  String _formatDateVN(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return "$day/$month/$year";
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final courts = bookingProvider.courts;

    final sportsComplexProvider = context.watch<SportsComplexProvider>();
    SportsComplexEntity? foundVenue = _venue;
    if (foundVenue == null) {
      for (final s in sportsComplexProvider.stadiums) {
        if (s.id == widget.venueId) {
          foundVenue = s;
          break;
        }
      }
    }
    final venue = foundVenue ?? SportsComplexEntity(
      id: widget.venueId,
      name: 'Sân chơi',
      address: '',
      logoUrl: '',
      rating: 5.0,
      open_time: '06:00',
      close_time: '22:00',
    );

    final timeLabels = _generateTimeLabels(venue.open_time, venue.close_time);

    if (bookingProvider.isLoading || _isVenueLoading) {
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
        backgroundColor: const Color(0xFFE0FFF0),
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

    final totalSlots = timeLabels.length > 1 ? timeLabels.length - 1 : 0;

    // Khởi tạo/cập nhật grid đặt sân động dựa trên danh sách sân thực tế và số lượng ô giờ
    for (int idx = 0; idx < courts.length; idx++) {
      final court = courts[idx];
      final currentMap = _bookingGrid[court.id];
      if (currentMap == null || currentMap.length != totalSlots) {
        final map = <int, SlotStatus>{};
        for (int i = 0; i < totalSlots; i++) {
          map[i] = SlotStatus.empty;
        }
        _bookingGrid[court.id] = map;
      }
    }

    // Chiều rộng cơ bản của một ô giờ, nhân với hệ số zoom factor
    final double cellWidth = 70.0 * _zoomFactor;
    const double cellHeight = 60.0;
    const double courtColumnWidth = 125.0;
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
                          // Khi đổi ngày, chúng ta cần xoá các ô đang chọn cũ
                          _selectedSlots.clear();
                        });
                        // Load lại các khóa giữ chỗ, các sân đã đặt, sân bị khóa và sự kiện cho ngày mới
                        final provider = context.read<BookingProvider>();
                        provider.loadActiveLocks(widget.venueId, _formattedQueryDate);
                        provider.loadBookedSlots(widget.venueId, _formattedQueryDate);
                        provider.loadCourtBlocks(widget.venueId, _formattedQueryDate);
                        provider.loadEventSlots(widget.venueId, _formattedQueryDate);
                        provider.loadEvents(widget.venueId);
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

            // Banner thông báo nếu toàn bộ cơ sở đang trong thời gian bảo trì
            if (courts.isNotEmpty && courts.every((c) => !c.isActive || c.status == 'maintenance'))
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF3E0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cơ sở hiện đang bảo trì toàn bộ sân. Tạm ngưng nhận đặt lịch trực tuyến.",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
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
                            color: const Color(0xFFDDF3F8),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1.2),
                              right: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Sân",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ),
                        // Danh sách tên sân
                        ...courts.map((court) {
                          final isMaintenance = !court.isActive || court.status == 'maintenance';
                          return Container(
                            width: courtColumnWidth,
                            height: cellHeight,
                            decoration: BoxDecoration(
                              color: isMaintenance ? const Color(0xFFFFF8E1) : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                                right: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  court.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isMaintenance ? Colors.grey.shade700 : Colors.black87,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                                if (isMaintenance) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.build_circle_outlined, size: 9, color: Color(0xFFE65100)),
                                        SizedBox(width: 2),
                                        Text(
                                          "Bảo trì",
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),

                    // Vùng Lưới Giờ cuộn ngang (Scrollable Columns)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dòng Header Khung Giờ dạng Thước Đo Thời Gian (Timeline Ruler)
                            Container(
                              width: totalSlots * cellWidth,
                              height: headerHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDF3F8), // Nền xanh nhạt giống ảnh mẫu
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade300, width: 1.2),
                                ),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Các mốc vạch và nhãn giờ ở từng đầu/cuối của mỗi ô (từ mốc mở cửa đến mốc đóng cửa)
                                  for (int i = 0; i <= totalSlots; i++)
                                    Positioned(
                                      left: (i * cellWidth) - 25,
                                      top: 0,
                                      bottom: 0,
                                      width: 50,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Nhãn thời gian căn giữa chính xác trên từng vạch mốc
                                          Align(
                                            alignment: Alignment.topCenter,
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                timeLabels[i],
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Vạch tick mark chỉ mốc thời gian màu vàng cam ở đáy header
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              width: 2,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B),
                                                borderRadius: BorderRadius.circular(1),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Các dòng Lưới Ô giờ tương ứng từng Sân
                            Column(
                              children: courts.map((court) {
                                final courtSlots = _bookingGrid[court.id] ?? {};
                                final isCourtMaintenance = !court.isActive || court.status == 'maintenance';

                                return Row(
                                  children: List.generate(totalSlots, (slotIndex) {
                                    var status = courtSlots[slotIndex] ?? SlotStatus.empty;

                                    // Nếu sân đang bảo trì, toàn bộ ô giờ bị khóa
                                    if (isCourtMaintenance) {
                                      status = SlotStatus.locked;
                                    } else {
                                      // Kiểm tra xem ô này đã được đặt thành công chưa (từ Supabase)
                                      final isBooked = bookingProvider.bookedSlots.any((b) =>
                                          b.courtId == court.id &&
                                          b.slotIndex == slotIndex);

                                      // Kiểm tra xem ô này có bị khóa hành chính bởi Admin/Chủ sân không (từ Supabase)
                                      final isBlocked = bookingProvider.courtBlocks.any((b) =>
                                          b.courtId == court.id &&
                                          b.slotIndex == slotIndex);

                                      // Kiểm tra ô sự kiện (qua event_slots và trực tiếp từ bảng events)
                                      final isEvent = _isEventSlot(court, slotIndex, bookingProvider, venue);

                                      if (isBooked) {
                                        status = SlotStatus.booked; // Hiển thị là đã đặt
                                      } else if (isBlocked) {
                                        status = SlotStatus.locked; // Hiển thị là đã khóa
                                      } else if (isEvent) {
                                        status = SlotStatus.event; // Hiển thị là sự kiện
                                      } else {
                                        // Kiểm tra xem ô này có bị người dùng khác giữ chỗ hay không
                                        final isLockedByOther = bookingProvider.activeLocks.any((lock) =>
                                            lock.courtId == court.id &&
                                            lock.slotIndex == slotIndex &&
                                            lock.userId != _userId &&
                                            !lock.isExpired);

                                        if (isLockedByOther) {
                                          status = SlotStatus.locked; // Hiển thị là đã khoá
                                        }
                                      }
                                    }

                                    final slotKey = "${court.id}_$slotIndex";
                                    final isSelected = _selectedSlots.contains(slotKey);
                                    final isPast = _isSlotInPast(slotIndex, venue.open_time);

                                    return _buildGridCell(
                                      status: status,
                                      isSelected: isSelected,
                                      width: cellWidth,
                                      height: cellHeight,
                                      isPast: isPast,
                                      onTap: () => _onSlotTap(court.id, slotIndex, status, isPast: isPast),
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
             _buildBottomControls(courts, venue, timeLabels),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCell({
    required SlotStatus status,
    required bool isSelected,
    required double width,
    required double height,
    required VoidCallback onTap,
    bool isPast = false,
  }) {
    Color cellColor = Colors.white;
    BorderSide borderSide = BorderSide(color: Colors.grey.shade200, width: 0.8);
    Widget? child;

    final isLockedSlot = isPast || status == SlotStatus.locked;

    if (isSelected) {
      cellColor = const Color(0xFF81C784); // Xanh lá khi chọn
      borderSide = const BorderSide(color: Color(0xFF388E3C), width: 1.2);
      child = const Icon(Icons.check_circle, color: Colors.white, size: 18);
    } else if (isLockedSlot) {
      cellColor = const Color(0xFFEBEBEB); // Nền xám nhạt đồng bộ chính xác theo ảnh
      borderSide = BorderSide(color: Colors.grey.shade300, width: 0.8);
      child = const Icon(Icons.lock_rounded, color: Color(0xFF9E9E9E), size: 18); // Icon ổ khóa bo tròn ở giữa
    } else if (status == SlotStatus.booked) {
      cellColor = const Color(0xFFFFCDD2); // Đỏ pastel đã đặt
      borderSide = BorderSide(color: Colors.red.shade200, width: 0.8);
      child = Icon(Icons.block_flipped, color: Colors.red.shade400, size: 16);
    } else if (status == SlotStatus.event) {
      cellColor = const Color(0xFFF3E5F5); // Tím pastel sự kiện nổi bật
      borderSide = const BorderSide(color: Color(0xFFCE93D8), width: 1.0);
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.emoji_events_rounded, color: Color(0xFF7B1FA2), size: 15),
          SizedBox(height: 1),
          Text(
            "SỰ KIỆN",
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7B1FA2),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    return Material(
      color: cellColor,
      child: InkWell(
        onTap: onTap,
        splashColor: isLockedSlot ? Colors.transparent : const Color(0xFF81C784).withValues(alpha: 0.4),
        highlightColor: isLockedSlot ? Colors.transparent : const Color(0xFF81C784).withValues(alpha: 0.2),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border(
              right: borderSide,
              bottom: borderSide,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  // Thanh điều khiển Zoom Slider và thanh Checkout nổi
   Widget _buildBottomControls(List<CourtEntity> courts, SportsComplexEntity venue, List<String> timeLabels) {
    final hasSelection = _selectedSlots.isNotEmpty;
    final totalAmount = _calculateTotalAmount(courts, venue.open_time);
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
                            final slotDetails = _buildSelectedSlotDetails(courts, timeLabels, venue.open_time);
                            final args = PaymentInfoArgs(
                              venue: venue,
                              date: _formatDateVN(_selectedDate),
                              selectedSlots: slotDetails,
                              totalAmount: totalAmount,
                              totalHours: totalHours,
                            );
                            context.push('/paymentinfopage', extra: args);
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
