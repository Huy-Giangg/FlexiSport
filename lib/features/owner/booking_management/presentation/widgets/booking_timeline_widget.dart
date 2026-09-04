import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/providers/owner_booking_provider.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/widgets/booking_detail_sheet.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/widgets/create_walkin_booking_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Model đại diện cho một mục hiển thị trên timeline (Đặt sân hoặc Khóa giờ)
class _ScheduleItem {
  final String id;
  final String courtId;
  final String courtName;
  final int startSlot;
  final int endSlot; // inclusive
  final String startTime;
  final String endTime;
  final String title;
  final String? subtitle;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled', 'locked'
  final String? customerPhone;
  final double? totalPrice;
  final String? bookingId;
  final String? blockId;

  _ScheduleItem({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.startSlot,
    required this.endSlot,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.subtitle,
    required this.status,
    this.customerPhone,
    this.totalPrice,
    this.bookingId,
    this.blockId,
  });

  String get timeRange => "$startTime - $endTime";
}

class BookingTimelineWidget extends StatefulWidget {
  const BookingTimelineWidget({super.key});

  @override
  State<BookingTimelineWidget> createState() => _BookingTimelineWidgetState();
}

class _BookingTimelineWidgetState extends State<BookingTimelineWidget> {
  late DateTime _selectedDate;
  String _selectedCourtFilter = 'all';
  String _selectedStatusFilter = 'all';

  bool _isLoading = false;
  List<_ScheduleItem> _scheduleItems = [];
  List<Map<String, dynamic>> _venueCourts = [];

  int get _startHour {
    final bookingProvider = context.read<OwnerBookingProvider>();
    final openTime = bookingProvider.selectedVenue?.openTime;
    if (openTime != null && openTime.isNotEmpty) {
      final parts = openTime.split(':');
      if (parts.isNotEmpty) {
        return int.tryParse(parts[0]) ?? 6;
      }
    }
    return 6;
  }

  int get _endHour {
    final bookingProvider = context.read<OwnerBookingProvider>();
    final closeTime = bookingProvider.selectedVenue?.closeTime;
    if (closeTime != null && closeTime.isNotEmpty) {
      final parts = closeTime.split(':');
      if (parts.isNotEmpty) {
        return int.tryParse(parts[0]) ?? 22;
      }
    }
    return 22;
  }

  static const double _hourWidth = 110.0;
  static const double _slotWidth = _hourWidth / 2; // 55px cho 30 phút
  static const double _courtColWidth = 125.0;
  static const double _headerHeight = 44.0;
  static const double _rowHeight = 78.0;

  List<String> _generateTimeLabels() {
    final List<String> labels = [];
    final start = _startHour;
    final end = _endHour;
    for (int h = start; h <= end; h++) {
      labels.add("${h.toString().padLeft(2, '0')}:00");
    }
    return labels;
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _slotToTime(int slotIndex) {
    final totalMinutes = _startHour * 60 + slotIndex * 30;
    final hour = totalMinutes ~/ 60;
    final min = totalMinutes % 60;
    return "${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}";
  }

  String? _lastVenueId;
  int? _lastRefreshCounter;
  RealtimeChannel? _timelineRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _subscribeTimelineRealtime();
  }

  void _subscribeTimelineRealtime() {
    _timelineRealtimeChannel?.unsubscribe();
    try {
      _timelineRealtimeChannel = Supabase.instance.client
          .channel('public:timeline_grid_${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'booking_slots',
            callback: (_) {
              if (mounted) _loadTimelineData();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            callback: (_) {
              if (mounted) _loadTimelineData();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'court_blocks',
            callback: (_) {
              if (mounted) _loadTimelineData();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint("Lỗi đăng ký realtime timeline: $e");
    }
  }

  @override
  void dispose() {
    _timelineRealtimeChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookingProvider = context.watch<OwnerBookingProvider>();
    final currentVenueId = bookingProvider.selectedVenue?.id;
    final currentRefreshCounter = bookingProvider.refreshCounter;

    if ((currentVenueId != null && currentVenueId != _lastVenueId) ||
        (currentRefreshCounter != _lastRefreshCounter)) {
      _lastVenueId = currentVenueId;
      _lastRefreshCounter = currentRefreshCounter;
      _loadTimelineData();
    }
  }

  Future<void> _loadTimelineData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final dateStr = _formatDate(_selectedDate);

    try {
      final bookingProvider = context.read<OwnerBookingProvider>();
      final venueId = bookingProvider.selectedVenue?.id;

      if (venueId == null || venueId.isEmpty) {
        if (mounted) {
          setState(() {
            _scheduleItems = [];
            _venueCourts = [];
            _isLoading = false;
          });
        }
        return;
      }

      // 1. Lấy danh sách sân con của cơ sở này
      dynamic courtsResp;
      try {
        courtsResp = await supabase
            .from('courts')
            .select('id, name, venue_id, is_active, status')
            .eq('venue_id', venueId);
      } catch (e) {
        try {
          courtsResp = await supabase
              .from('courts')
              .select('id, name, venue_id')
              .eq('venue_id', venueId);
        } catch (_) {
          courtsResp = [];
        }
      }

      List<Map<String, dynamic>> courtsList = [];
      if (courtsResp is List) {
        courtsList = courtsResp.map((c) => Map<String, dynamic>.from(c as Map)).toList();
      }

      // Nếu cơ sở này chưa có sân con nào trong database, tạo 3 sân mặc định để chủ sân có lưới trực quan thao tác
      if (courtsList.isEmpty) {
        courtsList = [
          {'id': '${venueId}_c1', 'name': 'Sân 1', 'venue_id': venueId, 'is_active': true, 'status': 'active'},
          {'id': '${venueId}_c2', 'name': 'Sân 2', 'venue_id': venueId, 'is_active': true, 'status': 'active'},
          {'id': '${venueId}_c3', 'name': 'Sân 3', 'venue_id': venueId, 'is_active': true, 'status': 'active'},
        ];
      }

      final courtIds = courtsList
          .map((c) => c['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // 2. Lấy booking_slots của ngày được chọn
      dynamic bookingSlotsResp;
      try {
        bookingSlotsResp = await supabase
            .from('booking_slots')
            .select('id, slot_index, booking_date, court_id, booking_id, bookings(*)')
            .eq('booking_date', dateStr)
            .inFilter('court_id', courtIds);
      } catch (_) {
        bookingSlotsResp = [];
      }

      final Map<String, List<Map<String, dynamic>>> bookingGroups = {};
      if (bookingSlotsResp is List) {
        for (final slot in bookingSlotsResp) {
          if (slot is Map<String, dynamic>) {
            final bId = slot['booking_id']?.toString() ?? slot['id'].toString();
            final cId = slot['court_id']?.toString() ?? '';
            final groupKey = "${bId}_$cId";
            bookingGroups.putIfAbsent(groupKey, () => []).add(slot);
          }
        }
      }

      final List<_ScheduleItem> items = [];

      bookingGroups.forEach((groupKey, slots) {
        if (slots.isEmpty) return;
        slots.sort((a, b) => ((a['slot_index'] as num?) ?? 0).compareTo((b['slot_index'] as num?) ?? 0));

        final firstSlot = slots.first;
        final lastSlot = slots.last;
        final startIdx = (firstSlot['slot_index'] as num?)?.toInt() ?? 0;
        final endIdx = (lastSlot['slot_index'] as num?)?.toInt() ?? startIdx;

        final courtId = firstSlot['court_id']?.toString() ?? '';
        final courtMap = courtsList.firstWhere(
          (c) => c['id']?.toString() == courtId,
          orElse: () => {'name': 'Sân'},
        );
        final courtName = courtMap['name']?.toString() ?? 'Sân';

        final bookingData = firstSlot['bookings'];
        String name = 'Khách đặt sân';
        String phone = '';
        String status = 'pending';
        double price = 0;
        String? bId;

        if (bookingData is Map) {
          bId = bookingData['id']?.toString();
          status = bookingData['booking_status']?.toString().toLowerCase() ?? 
                   bookingData['status']?.toString().toLowerCase() ?? 'pending';
          price = ((bookingData['total_price'] as num?) ?? (bookingData['total_amount'] as num?) ?? 0).toDouble();
          phone = bookingData['customer_phone']?.toString() ?? '';

          if (bookingData['customer_name'] != null && bookingData['customer_name'].toString().isNotEmpty) {
            name = bookingData['customer_name'].toString();
          } else if (bookingData['profiles'] is Map && bookingData['profiles']['name'] != null) {
            name = bookingData['profiles']['name'].toString();
          }
        }

        // Kiểm tra xem khung giờ này đã qua chưa
        final slotEndTime = _slotToTime(endIdx + 1);
        bool hasSlotPassed = false;
        try {
          final parts = dateStr.split('-');
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final tParts = slotEndTime.split(':');
          final endH = int.parse(tParts[0]);
          final endM = int.parse(tParts[1]);
          final endDateTime = DateTime(year, month, day, endH, endM);
          hasSlotPassed = DateTime.now().isAfter(endDateTime);
        } catch (_) {}

        if (status != 'cancelled' && hasSlotPassed) {
          status = 'completed';
        }

        String statusLabel = 'Chờ xác nhận';
        if (status == 'confirmed') statusLabel = 'Đã xác nhận';
        if (status == 'completed') statusLabel = 'Hoàn thành';
        if (status == 'cancelled') return;

        items.add(_ScheduleItem(
          id: groupKey,
          courtId: courtId,
          courtName: courtName,
          startSlot: startIdx,
          endSlot: endIdx,
          startTime: _slotToTime(startIdx),
          endTime: _slotToTime(endIdx + 1),
          title: name,
          subtitle: statusLabel,
          status: status,
          customerPhone: phone,
          totalPrice: price,
          bookingId: bId,
        ));
      });

      // 3. Lấy court_blocks (khóa giờ / bảo trì)
      dynamic blocksResp;
      try {
        blocksResp = await supabase
            .from('court_blocks')
            .select('id, court_id, block_date, slot_index, reason')
            .eq('block_date', dateStr)
            .inFilter('court_id', courtIds);
      } catch (_) {
        blocksResp = [];
      }

      final Map<String, List<Map<String, dynamic>>> blockGroups = {};
      if (blocksResp is List) {
        for (final blk in blocksResp) {
          if (blk is Map<String, dynamic>) {
            final cId = blk['court_id']?.toString() ?? '';
            final reason = blk['reason']?.toString() ?? 'Bảo trì';
            final groupKey = "${cId}_$reason";
            blockGroups.putIfAbsent(groupKey, () => []).add(blk);
          }
        }
      }

      blockGroups.forEach((groupKey, blocks) {
        if (blocks.isEmpty) return;
        blocks.sort((a, b) => ((a['slot_index'] as num?) ?? 0).compareTo((b['slot_index'] as num?) ?? 0));

        int curStart = (blocks.first['slot_index'] as num?)?.toInt() ?? 0;
        int curEnd = curStart;
        String blkId = blocks.first['id']?.toString() ?? '';
        String reason = blocks.first['reason']?.toString() ?? 'Bảo trì sân';
        final courtId = blocks.first['court_id']?.toString() ?? '';
        final courtMap = courtsList.firstWhere(
          (c) => c['id']?.toString() == courtId,
          orElse: () => {'name': 'Sân'},
        );
        final courtName = courtMap['name']?.toString() ?? 'Sân';

        for (int i = 1; i < blocks.length; i++) {
          final sIdx = (blocks[i]['slot_index'] as num?)?.toInt() ?? 0;
          if (sIdx == curEnd + 1) {
            curEnd = sIdx;
          } else {
            items.add(_ScheduleItem(
              id: "block_${blkId}_$curStart",
              courtId: courtId,
              courtName: courtName,
              startSlot: curStart,
              endSlot: curEnd,
              startTime: _slotToTime(curStart),
              endTime: _slotToTime(curEnd + 1),
              title: reason,
              subtitle: 'Đã khóa',
              status: 'locked',
              blockId: blkId,
            ));
            curStart = sIdx;
            curEnd = sIdx;
            blkId = blocks[i]['id']?.toString() ?? '';
            reason = blocks[i]['reason']?.toString() ?? 'Bảo trì sân';
          }
        }

        items.add(_ScheduleItem(
          id: "block_${blkId}_$curStart",
          courtId: courtId,
          courtName: courtName,
          startSlot: curStart,
          endSlot: curEnd,
          startTime: _slotToTime(curStart),
          endTime: _slotToTime(curEnd + 1),
          title: reason,
          subtitle: 'Đã khóa',
          status: 'locked',
          blockId: blkId,
        ));
      });

      if (mounted) {
        setState(() {
          _venueCourts = courtsList;
          _scheduleItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi loadTimelineData: $e");
      if (mounted) {
        setState(() {
          _scheduleItems = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF016B34),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadTimelineData();
    }
  }

  // --- KIỂM TRA KHUNG GIỜ ĐÃ QUA THỜI GIAN HIỆN TẠI HAY CHƯA ---
  bool _isSlotPassed(int slotIndex) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selectedDay.isBefore(today)) {
      return true; // Ngày trong quá khứ -> toàn bộ slot đã qua
    }
    if (selectedDay.isAfter(today)) {
      return false; // Ngày trong tương lai -> chưa qua
    }

    // Nếu là ngày hôm nay: tính theo giờ kết thúc của slot
    final slotEndMinutes = _startHour * 60 + (slotIndex + 1) * 30;
    final nowMinutes = now.hour * 60 + now.minute;
    return slotEndMinutes <= nowMinutes;
  }

  // --- POPUP TÙY CHỌN KHI BẤM VÀO SÂN TRỐNG (CHỈ ĐẶT SÂN TẠI QUẦY CHO KHÁCH) ---
  void _onEmptySlotTap(Map<String, dynamic> court, int slotIndex) {
    if (_isSlotPassed(slotIndex)) return;

    final courtId = court['id']?.toString() ?? '';
    final courtName = court['name']?.toString() ?? 'Sân';
    final startTimeStr = _slotToTime(slotIndex);
    final endTimeStr = _slotToTime(slotIndex + 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_available_rounded, color: Color(0xFF016B34), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courtName,
                        style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Khung giờ: $startTimeStr - $endTimeStr (${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year})",
                        style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Duy nhất 1 Lựa chọn: Đặt sân tại quầy cho khách
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_task_rounded, color: Color(0xFF016B34)),
              ),
              title: Text(
                "Đặt sân tại quầy cho khách",
                style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF016B34)),
              ),
              subtitle: Text(
                "Tạo đơn đặt trực tiếp cho khách vãng lai hoặc đặt trước qua hotline",
                style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              onTap: () {
                Navigator.of(ctx).pop();
                CreateWalkInBookingSheet.show(
                  context,
                  context.read<OwnerBookingProvider>(),
                  initialCourtId: courtId,
                  initialSlotIndex: slotIndex,
                  initialDate: _selectedDate,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG XEM CHI TIẾT Ô BẢO TRÌ & MỞ KHÓA ---
  void _openLockedDetailDialog(_ScheduleItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.build_circle_rounded, color: Color(0xFFED6C02)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Khung giờ bảo trì",
                style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sân: ${item.courtName}", style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 6),
            Text("Thời gian: ${item.timeRange} (${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year})", style: GoogleFonts.lexend(fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Lý do: ${item.title}",
                      style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Đóng", style: GoogleFonts.lexend(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              final dateStr = _formatDate(_selectedDate);
              try {
                for (int s = item.startSlot; s <= item.endSlot; s++) {
                  await Supabase.instance.client
                      .from('court_blocks')
                      .delete()
                      .eq('court_id', item.courtId)
                      .eq('block_date', dateStr)
                      .eq('slot_index', s);
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("Đã mở khóa khung giờ ${item.timeRange} cho ${item.courtName}", style: GoogleFonts.lexend()),
                    backgroundColor: const Color(0xFF016B34),
                  ),
                );
                _loadTimelineData();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text("Mở khóa thất bại: $e", style: GoogleFonts.lexend()), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF016B34),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Mở khóa giờ này", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- XỬ LÝ BẤM VÀO THẺ ĐẶT SÂN: XEM CHI TIẾT ĐƠN ---
  void _onBookingCardTap(_ScheduleItem item) {
    final provider = context.read<OwnerBookingProvider>();

    // Nếu tìm thấy OwnerBookingEntity tương ứng trong cache của Provider -> Mở BookingDetailSheet đầy đủ
    if (item.bookingId != null) {
      final found = provider.allBookings.where((b) => b.id == item.bookingId).toList();
      if (found.isNotEmpty) {
        BookingDetailSheet.show(context, found.first, provider);
        return;
      }
    }

    // Fallback: Mở dialog chi tiết đơn đặt sân
    _openBookingDetailFallbackDialog(item, provider);
  }

  void _openBookingDetailFallbackDialog(_ScheduleItem item, OwnerBookingProvider provider) {
    Color headerColor = const Color(0xFF1976D2);
    if (item.status == 'confirmed') headerColor = const Color(0xFF2E7D32);
    if (item.status == 'completed') headerColor = const Color(0xFF7B1FA2);
    if (item.status == 'cancelled') headerColor = const Color(0xFFD32F2F);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              item.status == 'confirmed'
                  ? Icons.check_circle_rounded
                  : (item.status == 'completed' ? Icons.task_alt_rounded : Icons.pending_actions_rounded),
              color: headerColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Chi tiết đơn đặt sân",
                style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Khách hàng: ${item.title}", style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold)),
            if (item.customerPhone != null && item.customerPhone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text("SĐT: ${item.customerPhone}", style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 6),
            Text("Sân: ${item.courtName}", style: GoogleFonts.lexend(fontSize: 13)),
            const SizedBox(height: 4),
            Text("Khung giờ: ${item.timeRange} (${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year})", style: GoogleFonts.lexend(fontSize: 13)),
            const SizedBox(height: 4),
            Text("Trạng thái: ${item.subtitle}", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: headerColor)),
            if (item.totalPrice != null && item.totalPrice! > 0) ...[
              const SizedBox(height: 6),
              Text(
                "Tổng tiền: ${item.totalPrice!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ",
                style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFED6C02)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Đóng", style: GoogleFonts.lexend(color: Colors.grey.shade600)),
          ),
          if (item.status == 'pending' && item.bookingId != null)
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                try {
                  await Supabase.instance.client
                      .from('bookings')
                      .update({'status': 'confirmed'})
                      .eq('id', item.bookingId!);
                  messenger.showSnackBar(
                    SnackBar(content: Text("Đã xác nhận đơn đặt sân", style: GoogleFonts.lexend()), backgroundColor: const Color(0xFF2E7D32)),
                  );
                  _loadTimelineData();
                  provider.refreshBookings();
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Xác nhận duyệt", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedCourt = _venueCourts.any((c) => c['id']?.toString() == _selectedCourtFilter);
    final courtDropdownValue = hasSelectedCourt ? _selectedCourtFilter : 'all';

    final filteredCourts = courtDropdownValue == 'all'
        ? _venueCourts
        : _venueCourts.where((c) => c['id']?.toString() == courtDropdownValue).toList();

    final timeLabels = _generateTimeLabels();

    return Column(
      children: [
        // 1. THANH DẢI 7 NGÀY TRONG TUẦN
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: _build7DaysStrip(),
        ),

        // 2. HÀNG BỘ LỌC
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              // Dropdown Chọn sân
              Expanded(
                flex: 5,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: courtDropdownValue,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF016B34)),
                      style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF016B34), fontWeight: FontWeight.bold),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text("Tất cả sân (${_venueCourts.length})", style: GoogleFonts.lexend(fontSize: 12)),
                        ),
                        ..._venueCourts.map((c) => DropdownMenuItem(
                              value: c['id']?.toString() ?? '',
                              child: Text(c['name']?.toString() ?? '', style: GoogleFonts.lexend(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCourtFilter = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Dropdown Lọc trạng thái
              Expanded(
                flex: 5,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF016B34)),
                      style: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF016B34), fontWeight: FontWeight.bold),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text("Tất cả trạng thái", style: GoogleFonts.lexend(fontSize: 12))),
                        DropdownMenuItem(value: 'confirmed', child: Text("Đã xác nhận", style: GoogleFonts.lexend(fontSize: 12))),
                        DropdownMenuItem(value: 'completed', child: Text("Hoàn thành", style: GoogleFonts.lexend(fontSize: 12))),
                        DropdownMenuItem(value: 'cancelled', child: Text("Đã hủy", style: GoogleFonts.lexend(fontSize: 12))),
                        DropdownMenuItem(value: 'locked', child: Text("Khóa bảo trì", style: GoogleFonts.lexend(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatusFilter = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút Hôm nay
              InkWell(
                onTap: () {
                  final today = DateTime.now();
                  if (_selectedDate.year != today.year || _selectedDate.month != today.month || _selectedDate.day != today.day) {
                    setState(() => _selectedDate = today);
                    _loadTimelineData();
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Hôm nay",
                    style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // 3. VÙNG LƯỚI TIMELINE (Tự co giãn chiều cao linh động theo số lượng sân)
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF016B34))),
          )
        else if (filteredCourts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "Không tìm thấy sân nào thuộc cơ sở này.",
                style: GoogleFonts.lexend(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: _buildTimelineGrid(filteredCourts, timeLabels),
          ),

        // 4. CHÚ THÍCH DƯỚI CÙNG (Nằm sát ngay dưới bảng)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendDot("Đã xác nhận", const Color(0xFF2E7D32)),
              _buildLegendDot("Hoàn thành", const Color(0xFF7B1FA2)),
              _buildLegendDot("Đã hủy", const Color(0xFFD32F2F)),
              _buildLegendDot("Bảo trì", const Color(0xFFED6C02)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build7DaysStrip() {
    final monday = _selectedDate.subtract(Duration(days: (_selectedDate.weekday - 1)));
    final daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (idx) {
              final d = monday.add(Duration(days: idx));
              final isSelected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
              final dayLabel = daysOfWeek[idx];
              final dateLabel = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}";

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = d);
                  _loadTimelineData();
                },
                child: Container(
                  width: 42,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF016B34) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayLabel,
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF016B34), size: 22),
          tooltip: "Chọn ngày",
          onPressed: _pickCalendarDate,
        ),
      ],
    );
  }

  // --- LƯỚI TIMELINE: CỘT DỌC LÀ SÂN, HÀNG NGANG LÀ GIỜ ---
  Widget _buildTimelineGrid(List<Map<String, dynamic>> courts, List<String> timeLabels) {
    final int totalHours = timeLabels.length;
    final double totalGridWidth = totalHours * _hourWidth;

    final displayItems = _scheduleItems.where((item) {
      if (_selectedStatusFilter == 'all') return true;
      return item.status == _selectedStatusFilter;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CỘT CỐ ĐỊNH BÊN TRÁI: DANH SÁCH CÁC SÂN
          Column(
            children: [
              // Ô góc trên bên trái (Giao giữa Header Sân & Giờ)
              Container(
                width: _courtColWidth,
                height: _headerHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1.2),
                    right: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stadium_rounded, size: 16, color: Color(0xFF016B34)),
                    const SizedBox(width: 4),
                    Text(
                      "Sân",
                      style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),

              // Danh sách từng hàng Tên Sân
              ...courts.map((court) {
                final courtName = court['name']?.toString() ?? 'Sân';
                final isInactive = court['is_active'] == false || court['status'] == 'maintenance';

                return Container(
                  width: _courtColWidth,
                  height: _rowHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isInactive ? const Color(0xFFFFF8E1) : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                      right: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courtName,
                        style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isInactive ? Colors.grey.shade700 : AppColors.onBackground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isInactive) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
                          ),
                          child: Text(
                            "Bảo trì",
                            style: GoogleFonts.lexend(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),

          // 2. VÙNG CUỘN NGANG: DẢI GIỜ PHÍA TRÊN VÀ CÁC THẺ ĐẶT SÂN
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng Header Dải Giờ (05:00, 06:00, 07:00, ... 23:00)
                  Row(
                    children: List.generate(totalHours, (hIdx) {
                      return Container(
                        width: _hourWidth,
                        height: _headerHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1.2),
                            right: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          timeLabels[hIdx],
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      );
                    }),
                  ),

                  // Các Hàng Tương Ứng Từng Sân
                  ...courts.map((court) {
                    final courtId = court['id']?.toString() ?? '';
                    final courtItems = displayItems.where((it) => it.courtId == courtId).toList();
                    final int totalSlots = totalHours * 2; // Mỗi giờ = 2 slot 30 phút

                    return SizedBox(
                      width: totalGridWidth,
                      height: _rowHeight,
                      child: Stack(
                        children: [
                          // Các ô lưới nền (Mỗi ô 30 phút, các ô đã qua thời gian có màu xám và không bấm được)
                          Row(
                            children: List.generate(totalSlots, (sIdx) {
                              final isHourStart = sIdx % 2 == 0;
                              final isPassed = _isSlotPassed(sIdx);

                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: isPassed ? null : () => _onEmptySlotTap(court, sIdx),
                                child: Container(
                                  width: _slotWidth,
                                  height: _rowHeight,
                                  decoration: BoxDecoration(
                                    color: isPassed ? const Color(0xFFF1F5F9) : Colors.white,
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
                                      right: BorderSide(
                                        color: isHourStart ? Colors.grey.shade200 : Colors.grey.shade100,
                                        width: isHourStart ? 1 : 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          // Các Thẻ Đơn Đặt Sân / Khóa Giờ (Positioned theo startSlot & endSlot)
                          ...courtItems.map((item) {
                            final double left = item.startSlot * _slotWidth + 2;
                            final int durationSlots = item.endSlot - item.startSlot + 1;
                            final double width = (durationSlots * _slotWidth) - 4;

                            return Positioned(
                              left: left,
                              width: width > 24 ? width : 24,
                              top: 3,
                              bottom: 3,
                              child: GestureDetector(
                                onTap: () {
                                  if (item.status == 'locked') {
                                    _openLockedDetailDialog(item);
                                  } else {
                                    _onBookingCardTap(item);
                                  }
                                },
                                child: _buildBookingCard(item),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THIẾT KẾ THẺ ĐẶT SÂN (CARD VIEW THEO ĐÚNG MẪU ẢNH) ---
  Widget _buildBookingCard(_ScheduleItem item) {
    Color bgColor = const Color(0xFFE8F1FE); // Xanh dương pastel (Chờ xác nhận)
    Color borderColor = const Color(0xFF1976D2);
    Color textColor = const Color(0xFF1565C0);

    if (item.status == 'confirmed') {
      bgColor = const Color(0xFFE6F4EA); // Xanh lá pastel (Đã xác nhận)
      borderColor = const Color(0xFF2E7D32);
      textColor = const Color(0xFF137333);
    } else if (item.status == 'completed') {
      bgColor = const Color(0xFFF3E8FD); // Tím pastel (Hoàn thành)
      borderColor = const Color(0xFF7B1FA2);
      textColor = const Color(0xFF6A1B9A);
    } else if (item.status == 'cancelled') {
      bgColor = const Color(0xFFFCE8E6); // Đỏ pastel (Đã hủy)
      borderColor = const Color(0xFFD32F2F);
      textColor = const Color(0xFFC5221F);
    } else if (item.status == 'locked') {
      bgColor = const Color(0xFFFFF3E0); // Cam/vàng pastel (Khóa bảo trì)
      borderColor = const Color(0xFFED6C02);
      textColor = const Color(0xFFE65100);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
          top: BorderSide(color: borderColor.withValues(alpha: 0.35), width: 0.8),
          right: BorderSide(color: borderColor.withValues(alpha: 0.35), width: 0.8),
          bottom: BorderSide(color: borderColor.withValues(alpha: 0.35), width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tên khách hàng / Lý do khóa
          Text(
            item.title,
            style: GoogleFonts.lexend(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1.5),

          // Khung giờ
          Text(
            item.timeRange,
            style: GoogleFonts.lexend(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Trạng thái (Chờ xác nhận, Đã xác nhận, Hoàn thành, Đã hủy, Đã khóa)
          if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              item.subtitle!,
              style: GoogleFonts.lexend(
                fontSize: 9.5,
                color: textColor.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.lexend(fontSize: 11.5, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
