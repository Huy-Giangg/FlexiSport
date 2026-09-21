import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/providers/owner_booking_provider.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/event_management/domain/entities/owner_event_entity.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/providers/owner_event_provider.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/widgets/visual_court_event_picker_sheet.dart';
import 'package:provider/provider.dart';

class AddEditEventSheet extends StatefulWidget {
  final OwnerEventEntity? event;
  final String venueId;
  final List<OwnerCourtEntity> courts;
  final OwnerEventProvider provider;

  const AddEditEventSheet({
    super.key,
    this.event,
    required this.venueId,
    required this.courts,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    OwnerEventEntity? event,
    required String venueId,
    required List<OwnerCourtEntity> courts,
    required OwnerEventProvider provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditEventSheet(
        event: event,
        venueId: venueId,
        courts: courts,
        provider: provider,
      ),
    );
  }

  @override
  State<AddEditEventSheet> createState() => _AddEditEventSheetState();
}

class _AddEditEventSheetState extends State<AddEditEventSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _maxTicketsController;
  late TextEditingController _minTicketsController;
  late TextEditingController _bannerUrlController;

  String _selectedSport = 'Pickleball';
  String _selectedLevel = 'Mọi trình độ';
  String _selectedCourtName = '';
  String? _selectedCourtId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _startTime = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _sportsList = [
    'Pickleball',
    'Cầu lông',
    'Bóng đá',
    'Tennis',
    'Bóng rổ',
    'Bóng bàn',
    'Bơi lội',
    'Khác',
  ];

  final List<String> _levelsList = [
    'Mọi trình độ',
    'Người mới (Cơ bản)',
    'Trung bình (Phong trào)',
    'Nâng cao / Bán chuyên',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _priceController = TextEditingController(
      text: e != null ? e.ticketPrice.toStringAsFixed(0) : '50000',
    );
    _maxTicketsController = TextEditingController(
      text: e != null ? e.maxTickets.toString() : '16',
    );
    _minTicketsController = TextEditingController(
      text: e != null ? e.minTickets.toString() : '4',
    );
    _bannerUrlController = TextEditingController(text: e?.bannerUrl ?? '');

    if (e != null) {
      _selectedSport = e.sportType.isNotEmpty ? e.sportType : 'Pickleball';
      _selectedLevel = e.level.isNotEmpty ? e.level : 'Mọi trình độ';
      _selectedCourtName = e.courtName;

      if (e.eventDate.isNotEmpty) {
        try {
          final parts = e.eventDate.split('-');
          if (parts.length == 3) {
            _selectedDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        } catch (_) {}
      }

      _startTime = _parseTime(e.startTime, defaultHour: 15);
      _endTime = _parseTime(e.endTime, defaultHour: 18);
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 2));
      if (widget.courts.isNotEmpty) {
        _selectedCourtName = widget.courts.first.name;
        _selectedCourtId = widget.courts.first.id;
      } else {
        _selectedCourtName = 'Sân 1';
      }
    }
  }

  TimeOfDay _parseTime(String timeStr, {required int defaultHour}) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return TimeOfDay(hour: defaultHour, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _maxTicketsController.dispose();
    _minTicketsController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Không thể truy cập ảnh: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Tải ảnh sự kiện lên",
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Chọn phương thức để cập nhật hình ảnh sự kiện",
                style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: Text(
                  "Chọn từ Thư viện",
                  style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Mở đầy đủ ảnh từ thư viện thiết bị để chọn",
                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0288D1)),
                ),
                title: Text(
                  "Chụp ảnh mới",
                  style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Sử dụng máy ảnh để chụp ảnh sự kiện ngay lập tức",
                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null || (widget.event?.bannerUrl != null && widget.event!.bannerUrl!.isNotEmpty)) ...[
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.red.shade50.withValues(alpha: 0.5),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: Text(
                    "Xóa ảnh hiện tại",
                    style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                  subtitle: Text(
                    "Gỡ bỏ ảnh bìa sự kiện đã chọn",
                    style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _selectedImage = null;
                      _bannerUrlController.clear();
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _openVisualCourtPicker() async {
    final effectiveVenueId = widget.venueId.isNotEmpty
        ? widget.venueId
        : (widget.provider.selectedVenue?.id ?? '');

    final effectiveVenueName = widget.provider.selectedVenue?.name ?? 'Cơ sở thể thao';

    final result = await VisualCourtEventPickerSheet.show(
      context,
      venueId: effectiveVenueId,
      venueName: effectiveVenueName,
      courts: widget.courts,
      initialDate: _selectedDate,
      initialCourtName: _selectedCourtName,
      initialStartTime: _startTime,
      initialEndTime: _endTime,
      editingEventId: widget.event?.id,
    );

    if (result != null) {
      setState(() {
        _selectedCourtId = result.courtId;
        _selectedCourtName = result.courtName;
        _selectedDate = result.date;
        _startTime = result.startTime;
        _endTime = result.endTime;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final startStr = _formatTimeOfDay(_startTime);
    final endStr = _formatTimeOfDay(_endTime);

    final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final int maxTickets = int.tryParse(_maxTicketsController.text.trim()) ?? 10;
    final int minTickets = int.tryParse(_minTicketsController.text.trim()) ?? 2;

    final minDate = DateTime.now().add(const Duration(days: 2));
    final minDateMidnight = DateTime(minDate.year, minDate.month, minDate.day);
    final selectedDateMidnight = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (selectedDateMidnight.isBefore(minDateMidnight)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thời gian tổ chức sự kiện phải bắt đầu từ ít nhất 2 ngày sau hiện tại."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (price < 50000 || price > 300000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Giá vé tham gia phải nằm trong khoảng từ 50.000đ đến 300.000đ/người."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (minTickets < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Số vé tối thiểu phải từ 1 người trở lên."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (minTickets > maxTickets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Số vé tối thiểu không được lớn hơn số vé tối đa."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String venueId = widget.venueId;
    if (venueId.isEmpty) {
      venueId = widget.provider.selectedVenue?.id ?? '';
    }
    if (venueId.isEmpty) {
      try {
        final bookingProv = context.read<OwnerBookingProvider>();
        if (bookingProv.selectedVenue != null) {
          venueId = bookingProv.selectedVenue!.id;
        } else if (bookingProv.venues.isNotEmpty) {
          venueId = bookingProv.venues.first.id;
        }
      } catch (_) {}
    }
    if (venueId.isEmpty) {
      try {
        final courtProv = context.read<OwnerCourtProvider>();
        if (courtProv.selectedVenue != null) {
          venueId = courtProv.selectedVenue!.id;
        } else if (courtProv.venues.isNotEmpty) {
          venueId = courtProv.venues.first.id;
        }
      } catch (_) {}
    }

    String? courtId = _selectedCourtId;
    if (courtId == null || courtId.isEmpty) {
      final match = widget.courts.where((c) => c.name == _selectedCourtName);
      if (match.isNotEmpty) {
        courtId = match.first.id;
      }
    }

    final eventData = {
      if (venueId.isNotEmpty) 'venue_id': venueId,
      if (courtId != null && courtId.isNotEmpty) 'court_id': courtId,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'sport_type': _selectedSport,
      'level': _selectedLevel,
      'court_name': _selectedCourtName,
      'event_date': dateStr,
      'start_time': startStr,
      'end_time': endStr,
      'ticket_price': price,
      'max_tickets': maxTickets,
      'min_tickets': minTickets,
      'is_active': true,
      if (_bannerUrlController.text.trim().isNotEmpty)
        'banner_url': _bannerUrlController.text.trim(),
    };

    bool success = false;
    if (widget.event != null) {
      success = await widget.provider.updateEvent(
        widget.event!.id,
        eventData,
        imageFile: _selectedImage,
      );
    } else {
      success = await widget.provider.createEvent(
        eventData,
        imageFile: _selectedImage,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event != null
                  ? "Cập nhật sự kiện thành công! 🎉"
                  : "Tạo sự kiện mới thành công! 🏸",
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      } else {
        final err = widget.provider.lastError ?? "Có lỗi xảy ra, vui lòng thử lại.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi tạo sự kiện: $err"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing ? "Chỉnh sửa sự kiện" : "Tạo sự kiện mới",
                    style: GoogleFonts.lexend(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Body Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image Picker
                    _buildImagePicker(),
                    const SizedBox(height: 18),

                    // Tên sự kiện
                    _buildLabel("Tên sự kiện *"),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.lexend(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: "VD: Giải Pickleball Giao Hữu Mở Rộng 2026",
                        prefixIcon: Icons.title_rounded,
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? "Vui lòng nhập tên sự kiện" : null,
                    ),
                    const SizedBox(height: 16),

                    // Môn thể thao & Trình độ
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Môn thể thao *"),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedSport,
                                decoration: _inputDecoration(prefixIcon: Icons.sports_tennis_rounded),
                                items: _sportsList.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: GoogleFonts.lexend(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSport = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Trình độ yêu cầu"),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedLevel,
                                decoration: _inputDecoration(prefixIcon: Icons.military_tech_rounded),
                                items: _levelsList.map((l) {
                                  return DropdownMenuItem(
                                    value: l,
                                    child: Text(
                                      l,
                                      style: GoogleFonts.lexend(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedLevel = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16,),
                    // LỊCH SÂN & GIỜ TRỰC QUAN
                    _buildLabel("Lịch sân & Khung giờ tổ chức *"),
                    const SizedBox(height: 8,),
                    InkWell(
                      onTap: _openVisualCourtPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0288D1).withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0288D1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Xem lịch & Chọn giờ trống",
                                        style: GoogleFonts.lexend(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.onBackground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Bắt đầu từ 2 ngày sau • Lưới 30 phút",
                                        style: GoogleFonts.lexend(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0288D1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Chọn lịch",
                                        style: GoogleFonts.lexend(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.stadium_rounded, size: 15, color: Color(0xFF0288D1)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _selectedCourtName.isNotEmpty ? _selectedCourtName : "Chưa chọn sân",
                                            style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 16, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 4)),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0288D1)),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                          style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 16, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 4)),
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0288D1)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            "${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}",
                                            style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0288D1)),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
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
                    const SizedBox(height: 16),

                    // Chọn sân tổ chức
                    // _buildLabel("Sân tổ chức"),
                    // if (widget.courts.isNotEmpty)
                    //   DropdownButtonFormField<String>(
                    //     isExpanded: true,
                    //     value: widget.courts.any((c) => c.name == _selectedCourtName)
                    //         ? _selectedCourtName
                    //         : widget.courts.first.name,
                    //     decoration: _inputDecoration(prefixIcon: Icons.stadium_rounded),
                    //     items: widget.courts.map((c) {
                    //       return DropdownMenuItem(
                    //         value: c.name,
                    //         child: Text(
                    //           c.name,
                    //           style: GoogleFonts.lexend(fontSize: 13),
                    //           overflow: TextOverflow.ellipsis,
                    //           maxLines: 1,
                    //         ),
                    //       );
                    //     }).toList(),
                    //     onChanged: (val) {
                    //       if (val != null) setState(() => _selectedCourtName = val);
                    //     },
                    //   )
                    // else
                    //   TextFormField(
                    //     initialValue: _selectedCourtName,
                    //     decoration: _inputDecoration(
                    //       hint: "VD: Sân 1, Sân A",
                    //       prefixIcon: Icons.stadium_rounded,
                    //     ),
                    //     onChanged: (v) => _selectedCourtName = v,
                    //   ),
                    // const SizedBox(height: 16),

                    // Giá vé
                    _buildLabel("Giá vé tham gia (VNĐ/người) *"),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                      style: GoogleFonts.lexend(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: "50000",
                        prefixIcon: Icons.payments_rounded,
                        suffixText: "đ/người",
                        helperText: "Giá vé quy định từ 50.000đ đến 300.000đ / người",
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Vui lòng nhập giá vé";
                        }
                        final num = int.tryParse(val.trim());
                        if (num == null) return "Giá vé không hợp lệ";
                        if (num < 50000) return "Giá vé tối thiểu là 50.000đ";
                        if (num > 300000) return "Giá vé tối đa là 300.000đ";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Số vé tối thiểu & Số vé tối đa
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Vé tối thiểu *"),
                              TextFormField(
                                controller: _minTicketsController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.lexend(fontSize: 14),
                                decoration: _inputDecoration(
                                  hint: "2",
                                  prefixIcon: Icons.people_outline_rounded,
                                ),
                                validator: (val) => (val == null || val.trim().isEmpty)
                                    ? "Nhập vé tối thiểu"
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Vé tối đa *"),
                              TextFormField(
                                controller: _maxTicketsController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.lexend(fontSize: 14),
                                decoration: _inputDecoration(
                                  hint: "16",
                                  prefixIcon: Icons.confirmation_number_rounded,
                                ),
                                validator: (val) => (val == null || val.trim().isEmpty)
                                    ? "Nhập vé tối đa"
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Hộp thông tin tự động hủy trước 2 tiếng
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFF57F17)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Quy tắc tự động: Trước 2 tiếng khi sự kiện bắt đầu, nếu chưa đủ số vé tối thiểu thì hệ thống sẽ tự động hủy sự kiện, giải phóng sân và hoàn tiền cho khách.",
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: const Color(0xFF795548),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mô tả chi tiết
                    _buildLabel("Mô tả chi tiết sự kiện"),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      style: GoogleFonts.lexend(fontSize: 13),
                      decoration: _inputDecoration(
                        hint: "Mô tả thể lệ, giải thưởng, lịch trình hoặc lưu ý cho người tham gia...",
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Footer Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.provider.isSaving ? null : _submit,
                  icon: widget.provider.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    isEditing ? "Lưu thay đổi" : "Hoàn tất tạo sự kiện",
                    style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.lexend(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final existingBanner = widget.event?.bannerUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Ảnh Banner sự kiện"),
        InkWell(
          onTap: _showImagePickerModal,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (_selectedImage != null || (existingBanner != null && existingBanner.isNotEmpty))
                    ? AppColors.primary
                    : const Color(0xFFCBD5E1),
                width: (_selectedImage != null || (existingBanner != null && existingBanner.isNotEmpty)) ? 1.5 : 1,
              ),
            ),
            child: _selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text("Đổi ảnh", style: GoogleFonts.lexend(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : (existingBanner != null && existingBanner.isNotEmpty)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              existingBanner,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text("Đổi ảnh", style: GoogleFonts.lexend(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          "Tải lên ảnh bìa cho sự kiện",
          style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
        Text(
          "Định dạng JPG, PNG (Khuyến nghị tỷ lệ 16:9)",
          style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
    String? suffixText,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lexend(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      suffixText: suffixText,
      suffixStyle: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
      helperText: helperText,
      helperStyle: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
