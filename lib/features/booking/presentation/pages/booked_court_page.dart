import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexisport_app/features/booking/domain/entities/event_booking_entity.dart';
import 'package:flexisport_app/features/booking/presentation/providers/booking_provider.dart';
import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/matchmaking/data/models/matchmaking_post_model.dart';
import 'package:flexisport_app/features/sports_complex/presentation/providers/sports_complex_provider.dart';

class BookedCourtPage extends StatefulWidget {
  final String from;
  const BookedCourtPage({super.key, this.from = ''});

  @override
  State<BookedCourtPage> createState() => _BookedCourtPageState();
}

class _BookedCourtPageState extends State<BookedCourtPage> {
  List<dynamic> _bookings = [];
  List<EventBookingEntity> _eventBookings = [];
  bool _isLoading = true;
  bool _isEventLoading = false;
  String? _errorMessage;
  DateTime? _selectedFilterDate;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _loadBookings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEventBookings();
      }
    });
  }

  Future<void> _loadEventBookings() async {
    if (!mounted) return;
    setState(() {
      _isEventLoading = true;
    });

    try {
      final provider = context.read<BookingProvider>();
      if (_userId.isNotEmpty) {
        await provider.loadUserEventBookings(_userId);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final guestBookingIds = prefs.getStringList('guest_event_booking_ids') ?? [];
        await provider.loadGuestEventBookings(guestBookingIds);
      }
      if (mounted) {
        setState(() {
          _eventBookings = provider.eventBookings;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách vé sự kiện: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isEventLoading = false;
        });
      }
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      dynamic response;

      if (_userId.isNotEmpty) {
        response = await supabase
            .from('bookings')
            .select('*, booking_slots(*, courts(*, venues(*))), venue_reviews(id), matchmaking_posts(*, host:profiles!host_id ( name, phone ))')
            .eq('user_id', _userId)
            .order('created_at', ascending: false);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final guestBookingIds = prefs.getStringList('guest_booking_ids') ?? [];
        if (guestBookingIds.isEmpty) {
          response = [];
        } else {
          response = await supabase
              .from('bookings')
              .select('*, booking_slots(*, courts(*, venues(*))), venue_reviews(id), matchmaking_posts(*, host:profiles!host_id ( name, phone ))')
              .inFilter('id', guestBookingIds)
              .order('created_at', ascending: false);
        }
      }

      setState(() {
        _bookings = response as List? ?? [];
      });
    } catch (e) {
      debugPrint("Lỗi tải danh sách đặt lịch: $e");
      setState(() {
        _errorMessage = "Lỗi khi tải thông tin: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectFilterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006D38), // màu chủ đạo
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedFilterDate = null;
    });
  }

  String _formatBookingSlots(List slots, String openTime, String closeTime) {
    if (slots.isEmpty) return '';

    // Phân nhóm slots theo courtId
    final Map<String, List<int>> courtToSlots = {};
    final Map<String, String> courtNames = {};
    for (var slot in slots) {
      final courtId = slot['court_id']?.toString() ?? '';
      final courtName = slot['courts']?['name']?.toString() ?? 'Sân';
      final slotIndex = slot['slot_index'] as int? ?? 0;
      courtNames[courtId] = courtName;
      courtToSlots.putIfAbsent(courtId, () => []).add(slotIndex);
    }

    final List<String> courtBookingStrings = [];

    // Generate time labels
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
      final hour = current ~/ 60;
      final minute = current % 60;
      timeLabels.add("${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
      current += 30;
    }

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

        // Format time range
        if (startIdx < timeLabels.length && endIdx < timeLabels.length) {
          final startStr = timeLabels[startIdx];
          final endBaseStr = timeLabels[endIdx];
          final timeParts = endBaseStr.split(':');
          String formattedRange = startStr;
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

            formattedRange = "$startFormatted - $endFormatted";
          }
          ranges.add(formattedRange);
        }
        i++;
      }
      courtBookingStrings.add("$courtName: ${ranges.join(', ')}");
    }

    return courtBookingStrings.join(' | ');
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

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return dateStr;
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

  String _getBookingTimeRange(List slots, String openTime, String closeTime) {
    if (slots.isEmpty) return '';
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
      final hour = current ~/ 60;
      final minute = current % 60;
      timeLabels.add("${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
      current += 30;
    }

    final List<int> indices = slots.map((s) => s['slot_index'] as int? ?? 0).toList();
    if (indices.isEmpty) return '';
    indices.sort();
    final minIdx = indices.first;
    final maxIdx = indices.last;

    if (minIdx < timeLabels.length && maxIdx < timeLabels.length) {
      final startStr = timeLabels[minIdx];
      final endBaseStr = timeLabels[maxIdx];
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
        final endStr = "${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}";
        return "$startStr-$endStr";
      }
    }
    return '';
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

  DateTime? _getBookingStartDateTime(List slots, String openTime, String closeTime) {
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
    final minIdx = indices.first;
    
    if (minIdx < startMinutesList.length) {
      final startMin = startMinutesList[minIdx];
      final startHour = startMin ~/ 60;
      final startMinute = startMin % 60;
      
      return DateTime(year, month, day, startHour, startMinute);
    }
    return null;
  }

  bool _isBookingStarted(List slots, String openTime, String closeTime) {
    final startDateTime = _getBookingStartDateTime(slots, openTime, closeTime);
    if (startDateTime == null) return false;
    return DateTime.now().isAfter(startDateTime);
  }

  String _formatCreatedAt(String? createdAtStr) {
    if (createdAtStr == null || createdAtStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(createdAtStr).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      return "Đặt lúc: $hour:$minute · $day/$month/$year";
    } catch (_) {
      return '';
    }
  }

  Future<void> _cancelBooking(dynamic booking) async {
    final bookingId = booking['id'];
    try {
      // 1. Xóa các slot giờ tương ứng để giải phóng sân con
      await Supabase.instance.client
          .from('booking_slots')
          .delete()
          .eq('booking_id', bookingId);

      // 2. Cập nhật trạng thái đơn đặt thành đã hủy
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      _loadBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Huỷ lịch đặt thành công!"),
            backgroundColor: Color(0xFF006D38),
          ),
        );
      }
    } catch (e) {
      debugPrint("Lỗi huỷ lịch: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi huỷ lịch: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelConfirmationDialog(BuildContext context, dynamic booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận huỷ"),
          content: const Text("Bạn có chắc chắn muốn huỷ lịch đặt này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Không", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking(booking);
              },
              child: const Text("Huỷ lịch", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context, String bookingId, String venueId) {
    double selectedRating = 5.0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Đánh giá buổi chơi",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF006D38),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Chất lượng trải nghiệm của bạn thế nào?",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1.0;
                        return GestureDetector(
                          onTap: isSubmitting
                              ? null
                              : () {
                                  setDialogState(() {
                                    selectedRating = starValue;
                                  });
                                },
                          child: Icon(
                            Icons.star,
                            size: 36,
                            color: starValue <= selectedRating
                                ? Colors.amber
                                : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: "Nhập nhận xét của bạn về chất lượng sân, dịch vụ...",
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF006D38)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final comment = commentController.text.trim();
                          if (comment.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Vui lòng nhập nội dung đánh giá!"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await context.read<SportsComplexProvider>().submitReview(
                                  bookingId: bookingId,
                                  venueId: venueId,
                                  rating: selectedRating,
                                  content: comment,
                                );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Gửi đánh giá thành công!"),
                                  backgroundColor: Color(0xFF006D38),
                                ),
                              );
                              _loadBookings(); // Reload local list to update Reviewed state
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Lỗi: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D38),
                    minimumSize: const Size(100, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Gửi",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: PopScope(
        canPop: widget.from != 'payment_success',
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.read<MainPageProvider>().showNavbar();
          context.go('/home');
        },
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: TabBarView(
          children: [
            _buildCourtBookingsTab(context),
            _buildEventBookingsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtBookingsTab(BuildContext context) {
    // Lọc theo ngày
    List<dynamic> displayedBookings = _bookings;
    if (_selectedFilterDate != null) {
      final formattedFilterDate =
          "${_selectedFilterDate!.year}-${_selectedFilterDate!.month.toString().padLeft(2, '0')}-${_selectedFilterDate!.day.toString().padLeft(2, '0')}";
      displayedBookings = _bookings.where((booking) {
        final slots = booking['booking_slots'] as List? ?? [];
        return slots.any((slot) => slot['booking_date'] == formattedFilterDate);
      }).toList();
    }

    return Column(
      children: [
        // Thanh lọc ngày ở đầu trang
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _selectFilterDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF006D38), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilterDate == null
                            ? "Xem tất cả"
                            : "Ngày ${_selectedFilterDate!.day.toString().padLeft(2, '0')}/${_selectedFilterDate!.month.toString().padLeft(2, '0')}/${_selectedFilterDate!.year}",
                        style: const TextStyle(
                          color: Color(0xFF006D38),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF006D38),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedFilterDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearFilter,
                  icon: const Icon(Icons.clear, color: Colors.redAccent),
                  tooltip: "Xoá bộ lọc",
                ),
              ]
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF006D38),
                  ),
                )
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : displayedBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFilterDate == null
                                    ? "Bạn chưa có lịch đặt nào"
                                    : "Không có lịch đặt cho ngày này",
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              if (_userId.isEmpty && _selectedFilterDate == null) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    context.push('/login');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF006D38),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text("Đăng nhập tài khoản"),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBookings,
                          color: const Color(0xFF006D38),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: displayedBookings.length,
                            itemBuilder: (context, index) {
                              final booking = displayedBookings[index];
                              return _buildBookingCard(booking);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildEventBookingsTab(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: _isEventLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF006D38),
                  ),
                )
              : _eventBookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            "Bạn chưa đăng ký vé sự kiện nào",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          if (_userId.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.push('/login');
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006D38),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Đăng nhập tài khoản"),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEventBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _eventBookings.length,
                        itemBuilder: (context, index) {
                          final booking = _eventBookings[index];
                          return _buildEventBookingCard(booking);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEventBookingCard(EventBookingEntity booking) {
    final event = booking.event;
    final title = event?.title ?? 'Sự kiện ghép sân';
    final courtName = event?.courtName ?? 'Sân 1';
    final startTime = event?.startTime ?? '15:00';
    final endTime = event?.endTime ?? '18:00';
    final dateStr = event != null ? _formatDate(event.eventDate) : _formatDate(booking.createdAt);
    
    String statusText = 'Chờ xác nhận';
    Color statusColor = const Color(0xFFE2A62C);
    
    if (booking.status == 'completed') {
      statusText = 'Đã thanh toán';
      statusColor = const Color(0xFF1EC391);
    } else if (booking.status == 'cancelled') {
      statusText = 'Đã huỷ';
      statusColor = Colors.redAccent;
    } else if (booking.status == 'used') {
      statusText = 'Đã sử dụng';
      statusColor = Colors.blueGrey;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE9FC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB313B2), width: 0.5),
                  ),
                  child: const Text(
                    "VÉ SỰ KIỆN",
                    style: TextStyle(
                      color: Color(0xFFB313B2),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Vị trí: $courtName",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              "Thời gian: $startTime - $endTime | Ngày: $dateStr",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              "Số lượng: ${booking.ticketCount} vé",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tổng thanh toán", style: TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      _formatVND(booking.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF006D38)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showQRTicketDialog(context, booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: Colors.white),
                  label: const Text("XEM VÉ QR", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQRTicketDialog(BuildContext context, EventBookingEntity booking) {
    final event = booking.event;
    final title = event?.title ?? 'Sự kiện ghép sân';
    final courtName = event?.courtName ?? 'Sân 1';
    final startTime = event?.startTime ?? '15:00';
    final endTime = event?.endTime ?? '18:00';
    final dateStr = event != null ? _formatDate(event.eventDate) : _formatDate(booking.createdAt);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String statusText = 'Chờ xác nhận';
            Color statusColor = const Color(0xFFE2A62C);
            if (booking.status == 'completed') {
              statusText = 'Đã thanh toán (Chưa sử dụng)';
              statusColor = const Color(0xFF1EC391);
            } else if (booking.status == 'cancelled') {
              statusText = 'Đã huỷ';
              statusColor = Colors.redAccent;
            } else if (booking.status == 'used') {
              statusText = 'Đã sử dụng (Đã check-in)';
              statusColor = Colors.grey;
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF005F31),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFEC88),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$courtName | $startTime - $endTime",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "Ngày diễn ra: $dateStr",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  
                  // QR Code image
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${booking.id}",
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 180,
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF006D38)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    "Trạng thái: $statusText",
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Mã đặt vé: ${booking.id.substring(0, 8).toUpperCase()}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Text(
                    "Khách hàng: ${booking.customerName} (${booking.customerPhone})",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    "Số lượng: ${booking.ticketCount} vé",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  
                  const Divider(color: Colors.white24, height: 24),
                  
                  if (booking.status == 'completed' || booking.status == 'pending') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close dialog
                          
                          final prefs = await SharedPreferences.getInstance();
                          final guestBookingIds = prefs.getStringList('guest_event_booking_ids') ?? [];
                          
                          await context.read<BookingProvider>().updateEventBookingStatus(
                            bookingId: booking.id,
                            status: 'used',
                            userId: _userId,
                            guestIds: guestBookingIds,
                          );
                          
                          _loadEventBookings();
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Mô phỏng quét vé check-in thành công!"),
                                backgroundColor: Color(0xFF1EC391),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text(
                          "MÔ PHỎNG XÉ VÉ (CHECK-IN)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ] else if (booking.status == 'used') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("VÉ ĐÃ ĐƯỢC SỬ DỤNG", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF006D38),
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          if (widget.from == 'payment_success') {
            context.read<MainPageProvider>().showNavbar();
            context.go('/home');
          } else {
            context.pop();
          }
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
        ),
      ),
      title: const Text(
        "Danh sách đặt lịch",
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      bottom: const TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(text: "LỊCH ĐẶT SÂN"),
          Tab(text: "VÉ SỰ KIỆN"),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final status = booking['status']?.toString() ?? 'pending';
    final slots = booking['booking_slots'] as List? ?? [];
    final double totalAmount = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;
    final String createdAtStr = booking['created_at']?.toString() ?? '';

    String venueName = 'Sân thể thao';
    String venueAddress = 'Chưa cập nhật địa chỉ';
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
          venueName = venue['name']?.toString() ?? 'Sân thể thao';
          venueAddress = venue['address']?.toString() ?? 'Chưa cập nhật địa chỉ';
          openTime = venue['open_time']?.toString() ?? '06:00';
          closeTime = venue['close_time']?.toString() ?? '22:00';
        }
      }
    }

    final bookingIdStr = booking['id']?.toString() ?? '';
    final shortCode = bookingIdStr.length >= 8 
        ? bookingIdStr.substring(0, 8).toUpperCase() 
        : bookingIdStr.toUpperCase();

    final timeRange = _getBookingTimeRange(slots, openTime, closeTime);
    final hasPassed = status != 'cancelled' && _isBookingPassed(slots, openTime, closeTime);
    final hasStarted = status != 'cancelled' && _isBookingStarted(slots, openTime, closeTime);

    // Trạng thái đơn đặt
    String statusText = 'Chờ xác nhận';
    Color statusTextColor = const Color(0xFFE26A2C);
    Color statusBgColor = const Color(0xFFFFF4EC);

    if (hasPassed) {
      statusText = 'Thành công';
      statusTextColor = const Color(0xFF006D38);
      statusBgColor = const Color(0xFFE8F5E9);
    } else if (status == 'completed') {
      statusText = 'Đã xác nhận';
      statusTextColor = const Color(0xFF006D38);
      statusBgColor = const Color(0xFFE8F5E9);
    } else if (status == 'cancelled') {
      statusText = 'Đã huỷ';
      statusTextColor = Colors.red;
      statusBgColor = const Color(0xFFFFEBEE);
    }

    final bookingMap = Map<String, dynamic>.from(booking);
    if (hasPassed) {
      bookingMap['status'] = 'completed';
    }

    final matchmakingList = booking['matchmaking_posts'] as List? ?? [];
    final activePosts = matchmakingList.where((p) => p['status'] != 'cancelled').toList();
    final hasMatchmaking = activePosts.isNotEmpty;

    // Check if reviewed and get venueId
    String venueId = '';
    if (slots.isNotEmpty) {
      final firstSlot = slots.first;
      final court = firstSlot['courts'];
      if (court != null) {
        venueId = court['venue_id']?.toString() ?? '';
      }
    }

    final rawReview = booking['venue_reviews'];
    final hasReviewed = rawReview != null && 
        (rawReview is List ? rawReview.isNotEmpty : true);
    
    final canReview = hasPassed && !hasReviewed && venueId.isNotEmpty;

    return InkWell(
      onTap: () {
        context.push("/BookedDetailPage", extra: bookingMap);
      },
      child: BookingCardWidget(
        venueName: venueName,
        shortCode: shortCode,
        bookingDateStr: bookingDateStr,
        timeRange: timeRange,
        statusText: statusText,
        statusTextColor: statusTextColor,
        statusBgColor: statusBgColor,
        totalAmount: totalAmount,
        createdAtFormatted: _formatCreatedAt(createdAtStr),
        isPending: status == 'pending' && !hasStarted,
        onCancel: () {
          _showCancelConfirmationDialog(context, booking);
        },
        onTapDetails: () {
          context.push("/BookedDetailPage", extra: bookingMap);
        },
        onOpenMatchmaking: (status == 'completed' && !hasPassed && !hasMatchmaking)
            ? () {
                final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                if (currentUserId == null || currentUserId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng đăng nhập để mở kèo ghép!')),
                  );
                  final mainPageProvider = context.read<MainPageProvider>();
                  mainPageProvider.hideNavbar();
                  context.push('/login').then((_) {
                    mainPageProvider.showNavbar();
                  });
                } else {
                  context.push("/CreateMatchmakingPage", extra: bookingIdStr).then((_) {
                    _loadBookings();
                  });
                }
              }
            : null,
        onViewMatchmaking: (hasMatchmaking && !hasPassed)
            ? () {
                final postJson = Map<String, dynamic>.from(activePosts.first);
                postJson['bookings'] = booking;
                final post = MatchmakingPostModel.fromJson(postJson);
                context.push("/MatchmakingDetailPage", extra: post);
              }
            : null,
        isReviewed: hasReviewed,
        onReview: canReview ? () => _showRatingDialog(context, bookingIdStr, venueId) : null,
      ),
    );
  }
}

class BookingCardWidget extends StatelessWidget {
  final String venueName;
  final String shortCode;
  final String bookingDateStr;
  final String timeRange;
  final String statusText;
  final Color statusTextColor;
  final Color statusBgColor;
  final double totalAmount;
  final String createdAtFormatted;
  final bool isPending;
  final VoidCallback onCancel;
  final VoidCallback onTapDetails;
  final VoidCallback? onOpenMatchmaking;
  final VoidCallback? onViewMatchmaking;
  final bool isReviewed;
  final VoidCallback? onReview;

  const BookingCardWidget({
    super.key,
    required this.venueName,
    required this.shortCode,
    required this.bookingDateStr,
    required this.timeRange,
    required this.statusText,
    required this.statusTextColor,
    required this.statusBgColor,
    required this.totalAmount,
    required this.createdAtFormatted,
    required this.isPending,
    required this.onCancel,
    required this.onTapDetails,
    this.onOpenMatchmaking,
    this.onViewMatchmaking,
    this.isReviewed = false,
    this.onReview,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Venue Name, ID, Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green vertical bar
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF006D38),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "ID: #$shortCode",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Date & Time Info
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF006D38),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                bookingDateStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(
                Icons.access_time,
                color: Color(0xFF006D38),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                timeRange,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(
            color: Colors.grey.withOpacity(0.15),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 12),

          // Row 3: Pricing & Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tổng tiền",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatVND(totalAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006D38),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isPending) ...[
                    OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        "Huỷ lịch",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onOpenMatchmaking != null) ...[
                    ElevatedButton(
                      onPressed: onOpenMatchmaking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D38),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        "Mở kèo ghép",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onViewMatchmaking != null) ...[
                    ElevatedButton(
                      onPressed: onViewMatchmaking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D38),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        "Chi tiết kèo ghép",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onReview != null) ...[
                    ElevatedButton(
                      onPressed: onReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2A62C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        "Đánh giá",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (isReviewed) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Đã đánh giá",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton(
                    onPressed: onTapDetails,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF006D38)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      "Chi tiết",
                      style: TextStyle(
                        color: Color(0xFF006D38),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (createdAtFormatted.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              createdAtFormatted,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
