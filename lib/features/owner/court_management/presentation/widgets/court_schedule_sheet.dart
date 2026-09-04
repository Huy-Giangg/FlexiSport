import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/providers/owner_booking_provider.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/widgets/create_walkin_booking_sheet.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
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

class CourtScheduleSheet extends StatefulWidget {
  final OwnerCourtEntity court;

  const CourtScheduleSheet({super.key, required this.court});

  static Future<void> show(BuildContext context, OwnerCourtEntity court) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourtScheduleSheet(court: court),
    );
  }

  @override
  State<CourtScheduleSheet> createState() => _CourtScheduleSheetState();
}

class _CourtScheduleSheetState extends State<CourtScheduleSheet> {
  late DateTime _selectedDate;
  String _selectedCourtFilter = 'all'; // 'all' hoặc courtId
  String _selectedStatusFilter = 'all'; // 'all', 'pending', 'confirmed', 'completed', 'cancelled', 'locked'

  bool _isLoading = false;
  List<_ScheduleItem> _scheduleItems = [];

  // Danh sách các khung giờ (Đồng bộ theo giờ mở/đóng cửa của venue)
  int _startHour = 6;
  int _endHour = 22;

  List<String> _generateTimeLabels() {
    final List<String> labels = [];
    for (int h = _startHour; h <= _endHour; h++) {
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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedCourtFilter = widget.court.id.isNotEmpty ? widget.court.id : 'all';
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final dateStr = _formatDate(_selectedDate);

    try {
      final venueId = widget.court.venueId;
      if (venueId.isNotEmpty) {
        try {
          final venueResp = await supabase
              .from('venues')
              .select('open_time, close_time')
              .eq('id', venueId)
              .maybeSingle();
          if (venueResp != null) {
            final openStr = venueResp['open_time']?.toString() ?? '';
            final closeStr = venueResp['close_time']?.toString() ?? '';
            if (openStr.isNotEmpty) {
              final parts = openStr.split(':');
              if (parts.isNotEmpty) {
                _startHour = int.tryParse(parts[0]) ?? _startHour;
              }
            }
            if (closeStr.isNotEmpty) {
              final parts = closeStr.split(':');
              if (parts.isNotEmpty) {
                _endHour = int.tryParse(parts[0]) ?? _endHour;
              }
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      final provider = context.read<OwnerCourtProvider>();
      final courts = provider.courts.isNotEmpty ? provider.courts : [widget.court];
      final courtIds = courts.map((c) => c.id).where((id) => id.isNotEmpty).toList();

      if (courtIds.isEmpty) {
        if (mounted) {
          setState(() {
            _scheduleItems = [];
            _isLoading = false;
          });
        }
        return;
      }

      // 1. Lấy danh sách booking_slots cho ngày được chọn (với xử lý lỗi đa tầng)
      dynamic bookingSlotsResp;
      try {
        bookingSlotsResp = await supabase
            .from('booking_slots')
            .select('id, slot_index, booking_date, court_id, booking_id, bookings(*, profiles:user_id(name, phone))')
            .eq('booking_date', dateStr)
            .inFilter('court_id', courtIds);
      } catch (_) {
        try {
          bookingSlotsResp = await supabase
              .from('booking_slots')
              .select('id, slot_index, booking_date, court_id, booking_id, bookings(*)')
              .eq('booking_date', dateStr)
              .inFilter('court_id', courtIds);
        } catch (_) {
          bookingSlotsResp = [];
        }
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
        final court = courts.firstWhere((c) => c.id == courtId, orElse: () => widget.court);

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

        String statusLabel = 'Chờ xác nhận';
        if (status == 'confirmed') statusLabel = 'Đã xác nhận';
        if (status == 'completed') statusLabel = 'Hoàn thành';
        if (status == 'cancelled') return;

        items.add(_ScheduleItem(
          id: groupKey,
          courtId: courtId,
          courtName: court.name,
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

      // 2. Lấy danh sách court_blocks (khóa giờ / bảo trì)
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
        final court = courts.firstWhere((c) => c.id == courtId, orElse: () => widget.court);

        for (int i = 1; i < blocks.length; i++) {
          final sIdx = (blocks[i]['slot_index'] as num?)?.toInt() ?? 0;
          if (sIdx == curEnd + 1) {
            curEnd = sIdx;
          } else {
            items.add(_ScheduleItem(
              id: "block_${blkId}_$curStart",
              courtId: courtId,
              courtName: court.name,
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
          courtName: court.name,
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
          _scheduleItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi loadScheduleData: $e");
      if (mounted) {
        setState(() {
          _scheduleItems = [];
          _isLoading = false;
        });
      }
    }
  }

  // Chọn ngày từ DatePicker
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
      _loadScheduleData();
    }
  }

  // Kiểm tra khung giờ đã qua thời gian hiện tại chưa
  bool _isSlotPassed(int slotIndex) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selectedDay.isBefore(today)) return true;
    if (selectedDay.isAfter(today)) return false;

    final slotEndMinutes = _startHour * 60 + (slotIndex + 1) * 30;
    final nowMinutes = now.hour * 60 + now.minute;
    return slotEndMinutes <= nowMinutes;
  }

  // Mở tạo đơn đặt sân tại quầy cho khung giờ trống
  void _onEmptySlotTap(OwnerCourtEntity court, int slotIndex) {
    if (_isSlotPassed(slotIndex)) return;

    CreateWalkInBookingSheet.show(
      context,
      context.read<OwnerBookingProvider>(),
      initialCourtId: court.id,
      initialSlotIndex: slotIndex,
      initialDate: _selectedDate,
    );
  }

  // Mở dialog chi tiết của block đã khóa để mở khóa
  void _openLockedDetailDialog(_ScheduleItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFED6C02)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Khung giờ đã khóa",
                style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sân: ${item.courtName}", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Thời gian: ${item.timeRange}", style: GoogleFonts.lexend(fontSize: 13)),
            const SizedBox(height: 4),
            Text("Lý do: ${item.title}", style: GoogleFonts.lexend(fontSize: 13, color: Colors.orange.shade900)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Đóng", style: GoogleFonts.lexend(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Đã mở khóa khung giờ ${item.timeRange}", style: GoogleFonts.lexend()),
                      backgroundColor: const Color(0xFF016B34),
                    ),
                  );
                }
                _loadScheduleData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Mở khóa thất bại: $e", style: GoogleFonts.lexend()), backgroundColor: Colors.red),
                  );
                }
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

  // Mở dialog chi tiết đơn đặt sân
  void _openBookingDetailDialog(_ScheduleItem item) {
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
              color: item.status == 'confirmed'
                  ? const Color(0xFF2E7D32)
                  : (item.status == 'completed' ? const Color(0xFF7B1FA2) : const Color(0xFF1976D2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Chi tiết đặt sân",
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
            Text("Khung giờ: ${item.timeRange} (${_selectedDate.day}/${_selectedDate.month})", style: GoogleFonts.lexend(fontSize: 13)),
            const SizedBox(height: 4),
            Text("Trạng thái: ${item.subtitle}", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600)),
            if (item.totalPrice != null && item.totalPrice! > 0) ...[
              const SizedBox(height: 4),
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
                Navigator.of(ctx).pop();
                try {
                  await Supabase.instance.client.from('bookings').update({'status': 'confirmed'}).eq('id', item.bookingId!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đã xác nhận đơn đặt sân", style: GoogleFonts.lexend()), backgroundColor: const Color(0xFF2E7D32)),
                    );
                  }
                  _loadScheduleData();
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Xác nhận", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerCourtProvider>();
    final allCourts = provider.courts.isNotEmpty ? provider.courts : [widget.court];

    // Đảm bảo value của dropdown luôn tồn tại trong items
    final hasSelectedCourt = allCourts.any((c) => c.id == _selectedCourtFilter);
    final courtDropdownValue = hasSelectedCourt ? _selectedCourtFilter : 'all';

    // Lọc danh sách sân hiển thị theo dropdown
    final filteredCourts = courtDropdownValue == 'all'
        ? allCourts
        : allCourts.where((c) => c.id == courtDropdownValue).toList();

    final timeLabels = _generateTimeLabels();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. APPBAR XANH ĐẬM (Khớp 100% hình ảnh)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF016B34),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    "Lịch đặt sân",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                  tooltip: "Chọn ngày từ lịch",
                  onPressed: _pickCalendarDate,
                ),
              ],
            ),
          ),

          // 2. THANH CAROUSEL 7 NGÀY TRONG TUẦN (Khớp 100% hình ảnh)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: _build7DaysStrip(),
          ),

          // 3. HÀNG BỘ LỌC (Tất cả sân | Tất cả trạng thái | Hôm nay)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // Dropdown Tất cả sân (An toàn không bao giờ văng lỗi Assertion)
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
                            child: Text("Tất cả sân", style: GoogleFonts.lexend(fontSize: 12)),
                          ),
                          ...allCourts.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name, style: GoogleFonts.lexend(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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

                // Dropdown Tất cả trạng thái
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
                          DropdownMenuItem(value: 'locked', child: Text("Đã khóa", style: GoogleFonts.lexend(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatusFilter = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Nút "Hôm nay"
                InkWell(
                  onTap: () {
                    final today = DateTime.now();
                    if (_selectedDate.year != today.year || _selectedDate.month != today.month || _selectedDate.day != today.day) {
                      setState(() => _selectedDate = today);
                      _loadScheduleData();
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

          // 4. BẢNG TIMELINE LƯỚI ĐẶT SÂN
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF016B34)))
                : filteredCourts.isEmpty
                    ? Center(
                        child: Text(
                          "Chưa có sân nào trong cụm sân này.",
                          style: GoogleFonts.lexend(color: Colors.grey.shade600),
                        ),
                      )
                    : _buildTimelineGrid(filteredCourts, timeLabels),
          ),

          // 5. CHÚ THÍCH DƯỚI CÙNG (Legend Row khớp 100% hình ảnh)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendDot("Đã xác nhận", const Color(0xFF2E7D32)),
                _buildLegendDot("Hoàn thành", const Color(0xFF7B1FA2)),
                _buildLegendDot("Đã hủy", const Color(0xFFD32F2F)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dải 7 ngày trong tuần
  Widget _build7DaysStrip() {
    final monday = _selectedDate.subtract(Duration(days: (_selectedDate.weekday - 1)));
    final daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (idx) {
        final d = monday.add(Duration(days: idx));
        final isSelected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
        final dayLabel = daysOfWeek[idx];
        final dateLabel = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}";

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDate = d);
            _loadScheduleData();
          },
          child: Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF016B34) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 4),
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
    );
  }

  // Bảng Timeline tương tác
  Widget _buildTimelineGrid(List<OwnerCourtEntity> courts, List<String> timeLabels) {
    const double hourHeight = 64.0;
    const double timeColWidth = 54.0;
    const double courtColWidth = 140.0;
    final totalHours = timeLabels.length;

    // Lọc items theo status filter
    final displayItems = _scheduleItems.where((item) {
      if (_selectedStatusFilter == 'all') return true;
      return item.status == _selectedStatusFilter;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột "Giờ" cố định bên trái
          Column(
            children: [
              // Header Giờ
              Container(
                width: timeColWidth,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    right: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Text(
                  "Giờ",
                  style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              // Các nhãn giờ (05:00, 06:00, ...)
              ...timeLabels.map((t) => Container(
                    width: timeColWidth,
                    height: hourHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200, width: 0.8),
                        right: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      t,
                      style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                  )),
            ],
          ),

          // Vùng cuộn ngang các Cột Sân
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: courts.map((court) {
                  final courtItems = displayItems.where((it) => it.courtId == court.id).toList();

                  return SizedBox(
                    width: courts.length == 1 ? (MediaQuery.of(context).size.width - timeColWidth) : courtColWidth,
                    child: Column(
                      children: [
                        // Header Tên Sân
                        Container(
                          height: 40,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                              right: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          child: Text(
                            court.name,
                            style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Thân Timeline dạng Stack để render các booking card nổi
                        SizedBox(
                          height: totalHours * hourHeight,
                          child: Stack(
                            children: [
                              // 1. Các ô giờ nền & cho phép bấm để đặt sân tại quầy
                              Column(
                                children: List.generate(totalHours, (hIdx) {
                                  final slotIndex = hIdx * 2;
                                  final isPassed = _isSlotPassed(slotIndex);

                                  return GestureDetector(
                                    onTap: isPassed
                                        ? null
                                        : () {
                                            _onEmptySlotTap(court, slotIndex);
                                          },
                                    child: Container(
                                      height: hourHeight,
                                      decoration: BoxDecoration(
                                        color: isPassed ? const Color(0xFFF1F5F9) : Colors.white,
                                        border: Border(
                                          top: BorderSide(color: Colors.grey.shade200, width: 0.8),
                                          right: BorderSide(color: Colors.grey.shade200, width: 1),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              // 2. Các thẻ Appointment Blocks (Khớp 100% thiết kế trong ảnh)
                              ...courtItems.map((item) {
                                final top = (item.startSlot * 30 / 60) * hourHeight;
                                final durationSlots = (item.endSlot - item.startSlot + 1);
                                final height = (durationSlots * 30 / 60) * hourHeight - 2;

                                return Positioned(
                                  top: top + 1,
                                  left: 2,
                                  right: 2,
                                  height: height > 20 ? height : 20,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (item.status == 'locked') {
                                        _openLockedDetailDialog(item);
                                      } else {
                                        _openBookingDetailDialog(item);
                                      }
                                    },
                                    child: _buildBookingCard(item),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card hiển thị từng đơn đặt / khóa giờ chuẩn thiết kế trong ảnh
  Widget _buildBookingCard(_ScheduleItem item) {
    Color bgColor = const Color(0xFFE3F2FD);
    Color borderColor = const Color(0xFF1976D2);
    Color textColor = const Color(0xFF1565C0);

    if (item.status == 'confirmed') {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF2E7D32);
      textColor = const Color(0xFF1B5E20);
    } else if (item.status == 'completed') {
      bgColor = const Color(0xFFF3E5F5);
      borderColor = const Color(0xFF7B1FA2);
      textColor = const Color(0xFF4A148C);
    } else if (item.status == 'cancelled') {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFD32F2F);
      textColor = const Color(0xFFB71C1C);
    } else if (item.status == 'locked') {
      bgColor = const Color(0xFFFFF3E0);
      borderColor = const Color(0xFFE65100);
      textColor = const Color(0xFFE65100);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: borderColor, width: 3.5),
          top: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 0.8),
          right: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 0.8),
          bottom: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.title,
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.timeRange,
            style: GoogleFonts.lexend(
              fontSize: 10,
              color: textColor.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              item.subtitle!,
              style: GoogleFonts.lexend(
                fontSize: 9,
                color: textColor.withValues(alpha: 0.8),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.lexend(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
