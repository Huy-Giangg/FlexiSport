import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/court_slot_status_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum MaintenanceScope { customRange, allDay, indefinite }

class CourtMaintenanceSheet extends StatefulWidget {
  final OwnerCourtEntity court;
  final OwnerCourtProvider provider;

  const CourtMaintenanceSheet({
    super.key,
    required this.court,
    required this.provider,
  });

  static Future<bool?> show(
    BuildContext context, {
    required OwnerCourtEntity court,
    required OwnerCourtProvider provider,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourtMaintenanceSheet(court: court, provider: provider),
    );
  }

  @override
  State<CourtMaintenanceSheet> createState() => _CourtMaintenanceSheetState();
}

class _CourtMaintenanceSheetState extends State<CourtMaintenanceSheet> {
  late DateTime _selectedDate;
  MaintenanceScope _selectedScope = MaintenanceScope.customRange;

  // Danh sách các slotIndex được chọn để bảo trì
  final Set<int> _selectedSlotIndices = {};

  // Lý do bảo trì
  String _selectedReason = 'Bảo dưỡng mặt sân';
  late final TextEditingController _reasonController;

  // Lịch và trạng thái các slot của ngày đã chọn
  bool _isLoadingSlots = false;
  List<CourtSlotStatusEntity> _courtSlots = [];

  final List<String> _quickReasons = [
    'Bảo dưỡng mặt sân',
    'Sửa chữa đèn / lưới',
    'Vệ sinh định kỳ',
    'Tổ chức giải đấu',
    'Thời tiết xấu / Mưa',
    'Khác...',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _reasonController = TextEditingController(text: _selectedReason);
    _loadSlotsForDate(_selectedDate);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDateVN(DateTime date) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekdayStr = weekdays[date.weekday % 7];
    return "$weekdayStr, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // Tải trạng thái các slot của sân trong ngày được chọn
  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() => _isLoadingSlots = true);
    final dateStr = _formatDate(date);
    try {
      final venueId = widget.court.venueId.isNotEmpty
          ? widget.court.venueId
          : (widget.provider.selectedVenue?.id ?? '');

      final slots = await widget.provider.getCourtSlotsStatusUseCase(
        courtId: widget.court.id,
        venueId: venueId,
        date: dateStr,
      );

      if (mounted) {
        setState(() {
          _courtSlots = slots;
          _isLoadingSlots = false;
          // Mặc định chọn khung giờ phù hợp
          _initDefaultSelectedSlots();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _courtSlots = [];
          _isLoadingSlots = false;
        });
      }
    }
  }

  int _parseTimeMinutes(String timeStr, int defaultHour) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? defaultHour;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return defaultHour * 60;
  }

  void _initDefaultSelectedSlots() {
    _selectedSlotIndices.clear();
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final venue = widget.provider.selectedVenue;
    final baseMinutes = _parseTimeMinutes(venue?.openTime ?? '05:00', 5);

    if (isToday) {
      // Tìm slotIndex gần nhất sau giờ hiện tại
      final currentMinutes = now.hour * 60 + now.minute;
      int startIdx = 0;
      for (int i = 0; i < _courtSlots.length; i++) {
        final slotMinutes = baseMinutes + i * 30;
        if (slotMinutes >= currentMinutes) {
          startIdx = i;
          break;
        }
      }
      // Chọn 4 slot (2 tiếng)
      for (int i = startIdx; i < startIdx + 4 && i < _courtSlots.length; i++) {
        _selectedSlotIndices.add(i);
      }
    } else {
      // Mặc định chọn ca sáng (08:00 - 12:00)
      _applyPresetRange(8, 12);
    }
  }

  void _applyPresetRange(int startHour, int endHour) {
    _selectedSlotIndices.clear();
    final venue = widget.provider.selectedVenue;
    final baseMinutes = _parseTimeMinutes(venue?.openTime ?? '05:00', 5);

    for (int i = 0; i < _courtSlots.length; i++) {
      final slotMinutes = baseMinutes + i * 30;
      final slotHour = slotMinutes / 60.0;
      if (slotHour >= startHour && slotHour < endHour) {
        _selectedSlotIndices.add(i);
      }
    }
    setState(() {});
  }

  // Đếm số lượng slot đã có khách đặt bị trùng trong dải chọn
  int get _conflictBookingsCount {
    return _courtSlots
        .where((s) => _selectedSlotIndices.contains(s.slotIndex) && s.isBooked)
        .length;
  }

  // Thực hiện áp dụng thiết lập bảo trì
  Future<void> _submitMaintenance() async {
    final reason = _reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : _selectedReason;

    final dateStr = _formatDate(_selectedDate);
    final venueId = widget.court.venueId.isNotEmpty
        ? widget.court.venueId
        : (widget.provider.selectedVenue?.id ?? '');

    String mode = 'custom_range';
    List<int>? slotIndices;

    if (_selectedScope == MaintenanceScope.indefinite) {
      mode = 'indefinite';
    } else if (_selectedScope == MaintenanceScope.allDay) {
      mode = 'all_day';
      slotIndices = _courtSlots.map((s) => s.slotIndex).toList();
    } else {
      mode = 'custom_range';
      if (_selectedSlotIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Vui lòng chọn ít nhất 1 khung giờ bảo trì.", style: GoogleFonts.lexend()),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }
      slotIndices = _selectedSlotIndices.toList()..sort();
    }

    final success = await widget.provider.setCourtMaintenance(
      courtId: widget.court.id,
      venueId: venueId,
      date: dateStr,
      mode: mode,
      slotIndices: slotIndices,
      reason: reason,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedScope == MaintenanceScope.indefinite
                        ? "Đã chuyển sân sang trạng thái bảo trì vô thời hạn"
                        : "Đã thiết lập bảo trì thành công cho sân ${widget.court.name}",
                    style: GoogleFonts.lexend(),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Thiết lập bảo trì thất bại, vui lòng thử lại.", style: GoogleFonts.lexend()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mở lại hoạt động sân (Hủy bảo trì)
  Future<void> _releaseMaintenance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text("Mở lại sân hoạt động?", style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Tất cả các khung giờ bảo trì của ngày ${_formatDateVN(_selectedDate)} sẽ được gỡ bỏ và sân sẽ mở lại để khách hàng có thể đặt.",
          style: GoogleFonts.lexend(fontSize: 13, color: AppColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Hủy", style: GoogleFonts.lexend(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Mở lại sân", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dateStr = _formatDate(_selectedDate);
      final venueId = widget.court.venueId.isNotEmpty
          ? widget.court.venueId
          : (widget.provider.selectedVenue?.id ?? '');

      final success = await widget.provider.setCourtMaintenance(
        courtId: widget.court.id,
        venueId: venueId,
        date: dateStr,
        mode: 'release',
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã mở lại sân hoạt động bình thường", style: GoogleFonts.lexend()),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = widget.provider.isSaving;
    final totalSelectedHours = _selectedSlotIndices.length * 0.5;
    final isCurrentlyMaintenance = !widget.court.isActive;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                  ),
                  child: const Icon(Icons.build_circle_rounded, color: Color(0xFFE65100), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thiết lập bảo trì sân",
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.court.name,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF016B34),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrentlyMaintenance ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCurrentlyMaintenance ? "Đang bảo trì" : "Đang hoạt động",
                              style: GoogleFonts.lexend(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrentlyMaintenance ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Nội dung cuộn
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Chọn ngày áp dụng
                  _buildSectionTitle("1. Chọn ngày bảo trì", Icons.calendar_today_rounded),
                  const SizedBox(height: 10),
                  _buildDatePickerRow(),

                  const SizedBox(height: 20),

                  // 2. Chọn hình thức bảo trì
                  _buildSectionTitle("2. Hình thức bảo trì", Icons.tune_rounded),
                  const SizedBox(height: 10),
                  _buildScopeSelector(),

                  const SizedBox(height: 20),

                  // 3. Khung giờ bảo trì (nếu chọn theo giờ)
                  if (_selectedScope == MaintenanceScope.customRange) ...[
                    _buildSectionTitle("3. Chọn khung giờ linh hoạt", Icons.access_time_filled_rounded),
                    const SizedBox(height: 10),
                    _buildPresetTimeChips(),
                    const SizedBox(height: 14),
                    _buildInteractiveSlotsGrid(),
                    const SizedBox(height: 20),
                  ],

                  // Cảnh báo nếu có đơn đặt của khách bị trùng
                  if (_selectedScope != MaintenanceScope.indefinite && _conflictBookingsCount > 0)
                    _buildConflictWarningCard(),

                  // 4. Lý do bảo trì
                  _buildSectionTitle("4. Lý do bảo trì", Icons.edit_note_rounded),
                  const SizedBox(height: 10),
                  _buildReasonSelector(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          _buildBottomActionButtons(isSaving, totalSelectedHours, isCurrentlyMaintenance),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF016B34)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
      ],
    );
  }

  // Hàng chọn ngày (Hôm nay, Ngày mai, Ngày kia, Chọn ngày khác)
  Widget _buildDatePickerRow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final afterTomorrow = today.add(const Duration(days: 2));

    return Row(
      children: [
        _buildDateChip("Hôm nay", today),
        const SizedBox(width: 8),
        _buildDateChip("Ngày mai", tomorrow),
        const SizedBox(width: 8),
        _buildDateChip("Ngày kia", afterTomorrow),
        const SizedBox(width: 8),
        // Nút mở lịch chọn ngày tùy ý
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF016B34),
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              _loadSlotsForDate(picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF016B34)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(String label, DateTime date) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedDate = date);
          _loadSlotsForDate(date);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF016B34) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF016B34) : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF016B34).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}",
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chọn hình thức bảo trì (Theo giờ / Cả ngày / Vô thời hạn)
  Widget _buildScopeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildScopeOption(
            title: "Theo khung giờ",
            scope: MaintenanceScope.customRange,
            icon: Icons.timer_outlined,
          ),
          _buildScopeOption(
            title: "Cả ngày",
            scope: MaintenanceScope.allDay,
            icon: Icons.today_rounded,
          ),
          _buildScopeOption(
            title: "Tạm đóng sân",
            scope: MaintenanceScope.indefinite,
            icon: Icons.block_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildScopeOption({
    required String title,
    required MaintenanceScope scope,
    required IconData icon,
  }) {
    final isSelected = _selectedScope == scope;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedScope = scope),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFFE65100) : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFFE65100) : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Preset Chips (Ca sáng, Ca chiều, Ca tối, 1 tiếng tới, 2 tiếng tới)
  Widget _buildPresetTimeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPresetChip("🌅 Ca sáng (06:00 - 12:00)", () => _applyPresetRange(6, 12)),
          const SizedBox(width: 8),
          _buildPresetChip("☀️ Ca chiều (12:00 - 17:00)", () => _applyPresetRange(12, 17)),
          const SizedBox(width: 8),
          _buildPresetChip("🌙 Ca tối (17:00 - 22:00)", () => _applyPresetRange(17, 22)),
          const SizedBox(width: 8),
          _buildPresetChip("⏱️ Chọn tất cả", () {
            setState(() {
              _selectedSlotIndices.clear();
              for (int i = 0; i < _courtSlots.length; i++) {
                _selectedSlotIndices.add(i);
              }
            });
          }),
          const SizedBox(width: 8),
          _buildPresetChip("🔄 Bỏ chọn", () => setState(() => _selectedSlotIndices.clear())),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      label: Text(
        label,
        style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF016B34)),
      ),
      backgroundColor: const Color(0xFFE8F5E9),
      side: const BorderSide(color: Color(0xFFC8E6C9), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  // Lưới tương tác trực quan từng ô 30 phút
  Widget _buildInteractiveSlotsGrid() {
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF016B34)),
        ),
      );
    }

    if (_courtSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text("Không có dữ liệu khung giờ.", style: GoogleFonts.lexend(color: Colors.grey)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chạm vào các ô để chọn/bỏ chọn:",
                style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              Text(
                "Đã chọn: ${_selectedSlotIndices.length} ô (${_selectedSlotIndices.length * 0.5}h)",
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid các ô giờ
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _courtSlots.map((slot) {
              final isSelected = _selectedSlotIndices.contains(slot.slotIndex);
              final isBooked = slot.isBooked;
              final isAlreadyBlocked = slot.isBlocked;

              Color bgColor = Colors.white;
              Color textColor = Colors.black87;
              Border border = Border.all(color: Colors.grey.shade300, width: 1);
              Widget? icon;

              if (isSelected) {
                bgColor = const Color(0xFFFFE0B2); // Cam nhạt bảo trì
                textColor = const Color(0xFFE65100);
                border = Border.all(color: const Color(0xFFFF9800), width: 1.5);
                icon = const Icon(Icons.build_circle_rounded, size: 12, color: Color(0xFFE65100));
              } else if (isBooked) {
                bgColor = const Color(0xFFFFCDD2); // Đỏ có khách đặt
                textColor = Colors.red.shade900;
                border = Border.all(color: Colors.red.shade200, width: 1);
                icon = Icon(Icons.person, size: 12, color: Colors.red.shade700);
              } else if (isAlreadyBlocked) {
                bgColor = const Color(0xFFEEEEEE); // Xám đã bị khóa từ trước
                textColor = Colors.grey.shade700;
                border = Border.all(color: Colors.grey.shade400, width: 1);
                icon = const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF9E9E9E));
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSlotIndices.remove(slot.slotIndex);
                    } else {
                      _selectedSlotIndices.add(slot.slotIndex);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 76) / 4,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        icon,
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(
                          slot.timeLabel,
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Cảnh báo trùng lịch
  Widget _buildConflictWarningCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57F17), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Chú ý: Có $_conflictBookingsCount khung giờ trong khoảng chọn đang có lịch đặt của khách hàng. Đơn của khách vẫn được lưu trên hệ thống, bạn nên liên hệ khách nếu cần đổi sân.",
              style: GoogleFonts.lexend(fontSize: 11.5, color: const Color(0xFFE65100), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // Chọn lý do bảo trì
  Widget _buildReasonSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickReasons.map((reason) {
            final isSelected = _selectedReason == reason;
            return ChoiceChip(
              label: Text(
                reason,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFFE65100),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide(color: isSelected ? const Color(0xFFE65100) : Colors.grey.shade300),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedReason = reason;
                    if (reason != 'Khác...') {
                      _reasonController.text = reason;
                    } else {
                      _reasonController.text = '';
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _reasonController,
          style: GoogleFonts.lexend(fontSize: 13),
          decoration: InputDecoration(
            hintText: "Nhập ghi chú / lý do bảo trì cụ thể...",
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            prefixIcon: const Icon(Icons.notes_rounded, size: 18, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // Footer Action Buttons
  Widget _buildBottomActionButtons(
    bool isSaving,
    double totalSelectedHours,
    bool isCurrentlyMaintenance,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Nút Mở lại sân (nếu sân đang bảo trì hoặc có block)
            if (isCurrentlyMaintenance || _courtSlots.any((s) => s.isBlocked)) ...[
              OutlinedButton.icon(
                onPressed: isSaving ? null : _releaseMaintenance,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18, color: Color(0xFF2E7D32)),
                label: Text(
                  "Mở lại sân",
                  style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: const BorderSide(color: Color(0xFF2E7D32), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Nút Xác nhận khóa bảo trì
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _submitMaintenance,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_clock_rounded, size: 18),
                label: Text(
                  isSaving
                      ? "Đang lưu..."
                      : (_selectedScope == MaintenanceScope.indefinite
                          ? "Tạm đóng sân vô thời hạn"
                          : (_selectedScope == MaintenanceScope.allDay
                              ? "Khóa bảo trì cả ngày"
                              : "Khóa bảo trì ($totalSelectedHours giờ)")),
                  style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
