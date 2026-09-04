import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';

class VisualCourtSelectionResult {
  final String courtName;
  final String courtId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  VisualCourtSelectionResult({
    required this.courtName,
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}

class VisualCourtEventPickerSheet extends StatefulWidget {
  final String venueId;
  final String venueName;
  final List<OwnerCourtEntity> courts;
  final DateTime initialDate;
  final String? initialCourtName;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final String? editingEventId;

  const VisualCourtEventPickerSheet({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.courts,
    required this.initialDate,
    this.initialCourtName,
    this.initialStartTime,
    this.initialEndTime,
    this.editingEventId,
  });

  static Future<VisualCourtSelectionResult?> show(
    BuildContext context, {
    required String venueId,
    required String venueName,
    required List<OwnerCourtEntity> courts,
    required DateTime initialDate,
    String? initialCourtName,
    TimeOfDay? initialStartTime,
    TimeOfDay? initialEndTime,
    String? editingEventId,
  }) {
    return showModalBottomSheet<VisualCourtSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VisualCourtEventPickerSheet(
        venueId: venueId,
        venueName: venueName,
        courts: courts,
        initialDate: initialDate,
        initialCourtName: initialCourtName,
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
        editingEventId: editingEventId,
      ),
    );
  }

  @override
  State<VisualCourtEventPickerSheet> createState() => _VisualCourtEventPickerSheetState();
}

class _VisualCourtEventPickerSheetState extends State<VisualCourtEventPickerSheet> {
  late DateTime _selectedDate;
  String? _selectedCourtId;
  String? _selectedCourtName;
  int? _startSlotIndex;
  int? _endSlotIndex;

  bool _isLoading = true;

  // Map courtId -> Set of booked slot indices
  final Map<String, Set<int>> _bookedSlots = {};
  // Map courtId -> Set of maintenance slot indices
  final Map<String, Set<int>> _blockedSlots = {};
  // Map courtId -> Set of existing event slot indices
  final Map<String, Set<int>> _eventSlots = {};

  final int _openHour = 6; // 06:00
  final int _closeHour = 22; // 22:00
  final int _totalSlots = 32; // (22 - 6) * 2 = 32 slots of 30 mins

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;

    // Tìm court khởi tạo
    if (widget.courts.isNotEmpty) {
      final match = widget.courts.where((c) => c.name == widget.initialCourtName);
      if (match.isNotEmpty) {
        _selectedCourtId = match.first.id;
        _selectedCourtName = match.first.name;
      } else {
        _selectedCourtId = widget.courts.first.id;
        _selectedCourtName = widget.courts.first.name;
      }
    }

    if (widget.initialStartTime != null && widget.initialEndTime != null) {
      _startSlotIndex = _timeToSlot(widget.initialStartTime!);
      _endSlotIndex = _timeToSlot(widget.initialEndTime!) - 1;
      if (_endSlotIndex! < _startSlotIndex!) {
        _endSlotIndex = _startSlotIndex;
      }
    }

    _loadAvailability();
  }

  int _timeToSlot(TimeOfDay time) {
    final minutes = (time.hour * 60 + time.minute) - (_openHour * 60);
    final slot = minutes ~/ 30;
    return slot.clamp(0, _totalSlots - 1);
  }

  TimeOfDay _slotToStartTime(int slot) {
    final totalMinutes = (_openHour * 60) + (slot * 30);
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  TimeOfDay _slotToEndTime(int slot) {
    final totalMinutes = (_openHour * 60) + ((slot + 1) * 30);
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  String get _formattedDateStr {
    return "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    _bookedSlots.clear();
    _blockedSlots.clear();
    _eventSlots.clear();

    final client = Supabase.instance.client;
    final dateStr = _formattedDateStr;

    try {
      // 1. Lấy đơn đặt sân (booking_slots)
      final bookingResp = await client
          .from('booking_slots')
          .select('court_id, slot_index')
          .eq('booking_date', dateStr);

      for (final item in (bookingResp as List<dynamic>)) {
        final cId = item['court_id']?.toString() ?? '';
        final slot = item['slot_index'] as int? ?? -1;
        if (cId.isNotEmpty && slot >= 0) {
          _bookedSlots.putIfAbsent(cId, () => <int>{}).add(slot);
        }
      }

      // 2. Lấy ô bảo trì (court_blocks)
      try {
        final blockResp = await client
            .from('court_blocks')
            .select('court_id, slot_index')
            .eq('block_date', dateStr);

        for (final item in (blockResp as List<dynamic>)) {
          final cId = item['court_id']?.toString() ?? '';
          final slot = item['slot_index'] as int? ?? -1;
          if (cId.isNotEmpty && slot >= 0) {
            _blockedSlots.putIfAbsent(cId, () => <int>{}).add(slot);
          }
        }
      } catch (_) {}

      // 3. Lấy sự kiện khác (event_slots)
      try {
        var eventQuery = client
            .from('event_slots')
            .select('court_id, slot_index, event_id')
            .eq('event_date', dateStr);

        final eventResp = await eventQuery;

        for (final item in (eventResp as List<dynamic>)) {
          final cId = item['court_id']?.toString() ?? '';
          final slot = item['slot_index'] as int? ?? -1;
          final evId = item['event_id']?.toString() ?? '';

          // Bỏ qua chính sự kiện đang được chỉnh sửa
          if (widget.editingEventId != null && evId == widget.editingEventId) {
            continue;
          }

          if (cId.isNotEmpty && slot >= 0) {
            _eventSlots.putIfAbsent(cId, () => <int>{}).add(slot);
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint("Lỗi tải thông tin lịch sân trống: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSlotTapped(String courtId, String courtName, int slotIndex) {
    // Kiểm tra ô có bị chiếm không
    final isBooked = _bookedSlots[courtId]?.contains(slotIndex) ?? false;
    final isBlocked = _blockedSlots[courtId]?.contains(slotIndex) ?? false;
    final isEvent = _eventSlots[courtId]?.contains(slotIndex) ?? false;

    if (isBooked) {
      _showWarningSnackBar("Ô giờ này đã có khách hàng đặt trước!");
      return;
    }
    if (isBlocked) {
      _showWarningSnackBar("Ô giờ này đang trong lịch bảo trì của sân!");
      return;
    }
    if (isEvent) {
      _showWarningSnackBar("Ô giờ này đã có sự kiện/giải đấu khác diễn ra!");
      return;
    }

    setState(() {
      if (_selectedCourtId != courtId) {
        // Đổi sang sân khác -> Chọn lại từ đầu
        _selectedCourtId = courtId;
        _selectedCourtName = courtName;
        _startSlotIndex = slotIndex;
        _endSlotIndex = slotIndex;
      } else {
        // Cùng sân
        if (_startSlotIndex == null || (_startSlotIndex != null && _endSlotIndex != null && _startSlotIndex != _endSlotIndex)) {
          // Bắt đầu chọn điểm đầu mới
          _startSlotIndex = slotIndex;
          _endSlotIndex = slotIndex;
        } else if (_startSlotIndex == slotIndex) {
          // Bỏ chọn
          _startSlotIndex = null;
          _endSlotIndex = null;
        } else {
          // Chọn điểm kết thúc dải giờ
          final first = _startSlotIndex! < slotIndex ? _startSlotIndex! : slotIndex;
          final last = _startSlotIndex! < slotIndex ? slotIndex : _startSlotIndex!;

          // Kiểm tra xem trong dải từ first -> last có ô nào bị vướng không
          bool hasConflict = false;
          for (int i = first; i <= last; i++) {
            if ((_bookedSlots[courtId]?.contains(i) ?? false) ||
                (_blockedSlots[courtId]?.contains(i) ?? false) ||
                (_eventSlots[courtId]?.contains(i) ?? false)) {
              hasConflict = true;
              break;
            }
          }

          if (hasConflict) {
            _showWarningSnackBar("Dải giờ bạn chọn có chứa ô đã bị trùng lịch!");
            _startSlotIndex = slotIndex;
            _endSlotIndex = slotIndex;
          } else {
            _startSlotIndex = first;
            _endSlotIndex = last;
          }
        }
      }
    });
  }

  void _showWarningSnackBar(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: GoogleFonts.lexend(fontSize: 12))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedCourtId == null || _selectedCourtName == null || _startSlotIndex == null || _endSlotIndex == null) {
      _showWarningSnackBar("Vui lòng chọn sân và ít nhất một khung giờ trống!");
      return;
    }

    final startTime = _slotToStartTime(_startSlotIndex!);
    final endTime = _slotToEndTime(_endSlotIndex!);

    Navigator.of(context).pop(
      VisualCourtSelectionResult(
        courtName: _selectedCourtName!,
        courtId: _selectedCourtId!,
        date: _selectedDate,
        startTime: startTime,
        endTime: endTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.grid_view_rounded, color: Color(0xFF2E7D32), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lịch sân & Chọn giờ trống",
                              style: GoogleFonts.lexend(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                            ),
                            Text(
                              widget.venueName,
                              style: GoogleFonts.lexend(fontSize: 12, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date Picker Strip
                _buildDateSelector(),
                const SizedBox(height: 10),

                // Legend (Chú thích)
                _buildLegend(),
              ],
            ),
          ),

          // Main Timeline Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : widget.courts.isEmpty
                    ? Center(
                        child: Text(
                          "Cơ sở chưa có sân nào.",
                          style: GoogleFonts.lexend(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.courts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (ctx, index) {
                          final court = widget.courts[index];
                          return _buildCourtTimelineCard(court);
                        },
                      ),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final d = dates[index];
          final isSelected = d.year == _selectedDate.year &&
              d.month == _selectedDate.month &&
              d.day == _selectedDate.day;

          String dayLabel = "${d.day}/${d.month}";
          if (index == 0) dayLabel = "Hôm nay ($dayLabel)";
          if (index == 1) dayLabel = "Ngày mai ($dayLabel)";

          return InkWell(
            onTap: () {
              setState(() {
                _selectedDate = d;
              });
              _loadAvailability();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  dayLabel,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.onBackground,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _legendItem(const Color(0xFFE8F5E9), const Color(0xFF2E7D32), "Ô trống"),
          const SizedBox(width: 12),
          _legendItem(AppColors.primary, Colors.white, "Đang chọn"),
          const SizedBox(width: 12),
          _legendItem(const Color(0xFFFFEBEE), const Color(0xFFC62828), "Khách đã đặt"),
          const SizedBox(width: 12),
          _legendItem(const Color(0xFFF3E5F5), const Color(0xFF7B1FA2), "Sự kiện"),
          const SizedBox(width: 12),
          _legendItem(const Color(0xFFECEFF1), const Color(0xFF546E7A), "Bảo trì"),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color fg, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: fg.withOpacity(0.4)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildCourtTimelineCard(OwnerCourtEntity court) {
    final isCurrentCourtSelected = _selectedCourtId == court.id;
    final courtBooked = _bookedSlots[court.id] ?? <int>{};
    final courtBlocked = _blockedSlots[court.id] ?? <int>{};
    final courtEvent = _eventSlots[court.id] ?? <int>{};

    final freeSlotsCount = _totalSlots - (courtBooked.length + courtBlocked.length + courtEvent.length);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentCourtSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isCurrentCourtSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stadium_rounded,
                      color: isCurrentCourtSelected ? AppColors.primary : Colors.grey.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      court.name,
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isCurrentCourtSelected ? AppColors.primary : AppColors.onBackground,
                      ),
                    ),
                    if (court.sportType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          court.sportType!,
                          style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  "Còn $freeSlotsCount / $_totalSlots ô trống",
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: freeSlotsCount > 0 ? const Color(0xFF2E7D32) : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Slot Strip
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              physics: const BouncingScrollPhysics(),
              itemCount: _totalSlots,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, slotIdx) {
                final isBooked = courtBooked.contains(slotIdx);
                final isBlocked = courtBlocked.contains(slotIdx);
                final isEvent = courtEvent.contains(slotIdx);

                final isSelected = isCurrentCourtSelected &&
                    _startSlotIndex != null &&
                    _endSlotIndex != null &&
                    slotIdx >= _startSlotIndex! &&
                    slotIdx <= _endSlotIndex!;

                final startT = _slotToStartTime(slotIdx);
                final endT = _slotToEndTime(slotIdx);
                final timeLabel = "${_formatTime(startT)} - ${_formatTime(endT)}";

                Color cardBg = const Color(0xFFF8FAFC);
                Color borderC = const Color(0xFFE2E8F0);
                Color textC = AppColors.onBackground;
                String subText = "Trống";

                if (isSelected) {
                  cardBg = AppColors.primary;
                  borderC = AppColors.primary;
                  textC = Colors.white;
                  subText = "Đang chọn";
                } else if (isBooked) {
                  cardBg = const Color(0xFFFFEBEE);
                  borderC = const Color(0xFFFFCDD2);
                  textC = const Color(0xFFC62828);
                  subText = "Đã đặt";
                } else if (isEvent) {
                  cardBg = const Color(0xFFF3E5F5);
                  borderC = const Color(0xFFE1BEE7);
                  textC = const Color(0xFF7B1FA2);
                  subText = "Sự kiện";
                } else if (isBlocked) {
                  cardBg = const Color(0xFFECEFF1);
                  borderC = const Color(0xFFCFD8DC);
                  textC = const Color(0xFF546E7A);
                  subText = "Bảo trì";
                }

                return InkWell(
                  onTap: () => _onSlotTapped(court.id, court.name, slotIdx),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderC),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeLabel,
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textC,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subText,
                          style: GoogleFonts.lexend(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white.withOpacity(0.9) : textC.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final hasSelection = _selectedCourtId != null && _startSlotIndex != null && _endSlotIndex != null;

    String summaryText = "Chưa chọn sân và khung giờ";
    if (hasSelection) {
      final start = _formatTime(_slotToStartTime(_startSlotIndex!));
      final end = _formatTime(_slotToEndTime(_endSlotIndex!));
      final count = (_endSlotIndex! - _startSlotIndex! + 1);
      final hours = (count * 0.5);
      summaryText = "$_selectedCourtName: $start - $end ($hours tiếng)";
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Khung giờ đã chọn:",
                  style: GoogleFonts.lexend(fontSize: 11, color: AppColors.secondary),
                ),
                Text(
                  summaryText,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: hasSelection ? AppColors.primary : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: hasSelection ? _confirmSelection : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Áp dụng",
              style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
