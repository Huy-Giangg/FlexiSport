import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/providers/owner_booking_provider.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/court_slot_status_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';

class CreateWalkInBookingSheet extends StatefulWidget {
  final OwnerBookingProvider bookingProvider;
  final String? initialCourtId;
  final int? initialSlotIndex;
  final DateTime? initialDate;

  const CreateWalkInBookingSheet({
    super.key,
    required this.bookingProvider,
    this.initialCourtId,
    this.initialSlotIndex,
    this.initialDate,
  });

  static void show(
    BuildContext context,
    OwnerBookingProvider bookingProvider, {
    String? initialCourtId,
    int? initialSlotIndex,
    DateTime? initialDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateWalkInBookingSheet(
        bookingProvider: bookingProvider,
        initialCourtId: initialCourtId,
        initialSlotIndex: initialSlotIndex,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<CreateWalkInBookingSheet> createState() => _CreateWalkInBookingSheetState();
}

class _CreateWalkInBookingSheetState extends State<CreateWalkInBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _depositController = TextEditingController();
  final _notesController = TextEditingController();

  OwnerCourtEntity? _selectedCourt;
  DateTime _selectedDate = DateTime.now();
  List<CourtSlotStatusEntity> _slots = [];
  final Set<int> _selectedSlotIndexes = {};
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialSlotIndex != null) {
      _selectedSlotIndexes.add(widget.initialSlotIndex!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courtProvider = context.read<OwnerCourtProvider>();
      if (courtProvider.courts.isNotEmpty) {
        OwnerCourtEntity? matchedCourt;
        if (widget.initialCourtId != null) {
          try {
            matchedCourt = courtProvider.courts.firstWhere((c) => c.id == widget.initialCourtId);
          } catch (_) {}
        }
        setState(() {
          _selectedCourt = matchedCourt ?? courtProvider.courts.first;
        });
        _loadSlots(preserveSelection: true);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }

  double get _totalPrice {
    if (_selectedCourt == null || _selectedSlotIndexes.isEmpty) return 0.0;
    // Mỗi slot 30 phút = 0.5 giờ
    return _selectedCourt!.pricePerHour * _selectedSlotIndexes.length * 0.5;
  }

  bool _isSlotPassed(CourtSlotStatusEntity slot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selectedDay.isBefore(today)) return true;
    if (selectedDay.isAfter(today)) return false;

    final parts = slot.timeLabel.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final slotEndMinutes = h * 60 + m + 30;
      final nowMinutes = now.hour * 60 + now.minute;
      return slotEndMinutes <= nowMinutes;
    }
    return false;
  }

  String _getFormattedSelectedTimeRanges() {
    if (_selectedSlotIndexes.isEmpty) return "Chưa chọn khung giờ";

    final sorted = _selectedSlotIndexes.toList()..sort();
    final List<String> ranges = [];

    int rangeStart = sorted.first;
    int rangeEnd = sorted.first;

    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == rangeEnd + 1) {
        rangeEnd = sorted[i];
      } else {
        final startSlot = _slots.firstWhere(
          (s) => s.slotIndex == rangeStart,
          orElse: () => CourtSlotStatusEntity(slotIndex: rangeStart, timeLabel: ''),
        );
        final endSlot = _slots.firstWhere(
          (s) => s.slotIndex == rangeEnd,
          orElse: () => CourtSlotStatusEntity(slotIndex: rangeEnd, timeLabel: ''),
        );
        final startLabel = startSlot.timeLabel.isNotEmpty ? startSlot.timeLabel : '${rangeStart ~/ 2}:${(rangeStart % 2 * 30).toString().padLeft(2, '0')}';
        final endLabel = endSlot.endTime;
        ranges.add("$startLabel - $endLabel");
        rangeStart = sorted[i];
        rangeEnd = sorted[i];
      }
    }

    final startSlot = _slots.firstWhere(
      (s) => s.slotIndex == rangeStart,
      orElse: () => CourtSlotStatusEntity(slotIndex: rangeStart, timeLabel: ''),
    );
    final endSlot = _slots.firstWhere(
      (s) => s.slotIndex == rangeEnd,
      orElse: () => CourtSlotStatusEntity(slotIndex: rangeEnd, timeLabel: ''),
    );
    final startLabel = startSlot.timeLabel.isNotEmpty ? startSlot.timeLabel : '${rangeStart ~/ 2}:${(rangeStart % 2 * 30).toString().padLeft(2, '0')}';
    final endLabel = endSlot.endTime;
    ranges.add("$startLabel - $endLabel");

    final totalHours = (sorted.length * 30 / 60);
    final hoursStr = totalHours == totalHours.toInt()
        ? "${totalHours.toInt()} tiếng"
        : "${totalHours.toStringAsFixed(1)} tiếng";

    return "${ranges.join(', ')} ($hoursStr / ${sorted.length} ca)";
  }

  Future<void> _loadSlots({bool preserveSelection = false}) async {
    if (_selectedCourt == null) return;
    setState(() {
      _isLoadingSlots = true;
      if (!preserveSelection) {
        _selectedSlotIndexes.clear();
      }
    });

    final courtProvider = context.read<OwnerCourtProvider>();
    final dateStr = _formatDate(_selectedDate);

    try {
      final slots = await courtProvider.getCourtSlotsStatusUseCase(
        courtId: _selectedCourt!.id,
        venueId: _selectedCourt!.venueId.isNotEmpty
            ? _selectedCourt!.venueId
            : (courtProvider.selectedVenue?.id ?? ''),
        date: dateStr,
      );
      if (mounted) {
        setState(() {
          _slots = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _slots = [];
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSlots();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn sân thi đấu")),
      );
      return;
    }
    if (_selectedSlotIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất 1 khung giờ")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final depositText = _depositController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final depositAmount = double.tryParse(depositText) ?? _totalPrice;

    final sortedSlots = _selectedSlotIndexes.toList()..sort();
    final dateStr = _formatDate(_selectedDate);

    final success = await widget.bookingProvider.createWalkInBooking(
      courtId: _selectedCourt!.id,
      bookingDate: dateStr,
      slotIndexes: sortedSlots,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      totalPrice: _totalPrice,
      depositAmount: depositAmount,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Đã tạo đơn đặt sân thành công!",
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Tạo đơn thất bại. Khung giờ có thể đã có người đặt hoặc thông tin không hợp lệ.",
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courtProvider = context.watch<OwnerCourtProvider>();
    final courts = courtProvider.courts;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
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
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Đặt sân trực tiếp tại quầy",
                    style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Chọn sân & Ngày
              Row(
                children: [
                  // Dropdown chọn sân
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Chọn sân", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<OwnerCourtEntity>(
                          initialValue: _selectedCourt ?? (courts.isNotEmpty ? courts.first : null),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: courts.map((c) {
                            return DropdownMenuItem<OwnerCourtEntity>(
                              value: c,
                              child: Text(c.name, style: GoogleFonts.lexend(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (court) {
                            setState(() {
                              _selectedCourt = court;
                            });
                            _loadSlots();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Nút chọn ngày
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ngày đặt", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "${_selectedDate.day}/${_selectedDate.month}",
                                    style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Lưới chọn khung giờ trống
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chọn khung giờ (${_selectedSlotIndexes.length} ca đã chọn)",
                    style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (_selectedSlotIndexes.isNotEmpty)
                    InkWell(
                      onTap: () => setState(() => _selectedSlotIndexes.clear()),
                      child: Text(
                        "Bỏ chọn tất cả",
                        style: GoogleFonts.lexend(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Banner tóm tắt khung giờ đã chọn (Ví dụ: 19:30 - 20:30 (1 tiếng))
              if (_selectedSlotIndexes.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF81C784), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Khung giờ đặt sân:",
                              style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getFormattedSelectedTimeRanges(),
                              style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isLoadingSlots)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_slots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Chưa có dữ liệu khung giờ",
                      style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) {
                    final isSelected = _selectedSlotIndexes.contains(slot.slotIndex);
                    final isPassed = _isSlotPassed(slot);
                    final isUnavailable = slot.isBooked || slot.isBlocked || isPassed;

                    Color bgColor = const Color(0xFFF3F4F6);
                    Color textColor = Colors.black87;
                    BorderSide border = BorderSide(color: Colors.grey.shade300);

                    if (isUnavailable) {
                      bgColor = isPassed ? const Color(0xFFF1F5F9) : Colors.red.shade50;
                      textColor = isPassed ? Colors.grey.shade400 : Colors.red.shade400;
                      border = BorderSide(color: isPassed ? Colors.grey.shade300 : Colors.red.shade200);
                    } else if (isSelected) {
                      bgColor = AppColors.primary;
                      textColor = Colors.white;
                      border = const BorderSide(color: AppColors.primary);
                    }

                    return InkWell(
                      onTap: isUnavailable
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  _selectedSlotIndexes.remove(slot.slotIndex);
                                } else {
                                  _selectedSlotIndexes.add(slot.slotIndex);
                                }
                              });
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.fromBorderSide(border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : (isUnavailable ? (isPassed ? Icons.history_rounded : Icons.block_rounded) : Icons.schedule_rounded),
                              size: 13,
                              color: textColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              slot.timeRange,
                              style: GoogleFonts.lexend(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: textColor,
                                decoration: (isUnavailable && !isPassed) ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 16),

              // 3. Thông tin khách hàng & Tiền
              Text("Thông tin khách hàng", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  labelText: "Tên khách hàng *",
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Vui lòng nhập tên khách" : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  labelText: "Số điện thoại *",
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Vui lòng nhập SĐT" : null,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Tổng tiền sân:", style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(_totalPrice),
                            style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _depositController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.lexend(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Tiền đã thu",
                        hintText: "Mặc định thu đủ",
                        prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _notesController,
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  labelText: "Ghi chú (tùy chọn)",
                  prefixIcon: const Icon(Icons.notes_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Nút Tạo đơn
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Xác nhận tạo đơn đặt sân",
                          style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
