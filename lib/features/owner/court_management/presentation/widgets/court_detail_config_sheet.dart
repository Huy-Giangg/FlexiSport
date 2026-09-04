import 'package:flexisport_app/core/services/court_pricing_service.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/court_maintenance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourtDetailConfigSheet extends StatefulWidget {
  final OwnerCourtEntity court;
  final OwnerCourtProvider provider;

  const CourtDetailConfigSheet({
    super.key,
    required this.court,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    required OwnerCourtEntity court,
    required OwnerCourtProvider provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourtDetailConfigSheet(
        court: court,
        provider: provider,
      ),
    );
  }

  @override
  State<CourtDetailConfigSheet> createState() => _CourtDetailConfigSheetState();
}

class _CourtDetailConfigSheetState extends State<CourtDetailConfigSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late String _selectedSportType;
  late bool _isActive;

  late TextEditingController _normalPriceController;
  late TextEditingController _peakPriceController;
  late TextEditingController _weekendSurchargeController;
  bool _applyPeakPricing = true;
  bool _applyWeekendPricing = true;
  bool _isSaving = false;

  final List<String> _sportTypes = [
    'Pickleball',
    'Cầu lông',
    'Bóng đá',
    'Tennis',
    'Bóng rổ',
    'Bóng chuyền',
  ];

  @override
  void initState() {
    super.initState();
    _isActive = widget.court.isActive;

    _nameController = TextEditingController(text: widget.court.name);

    final rawSport = (widget.court.sportType != null && widget.court.sportType!.trim().isNotEmpty)
        ? widget.court.sportType!.trim()
        : (widget.provider.selectedVenue?.sportsType ?? 'Pickleball');
    _selectedSportType = rawSport;
    if (!_sportTypes.contains(_selectedSportType)) {
      _sportTypes.insert(0, _selectedSportType);
    }

    final pricing = CourtPricingService.instance.getPricingSync(
      widget.court.id,
      fallbackBasePrice: widget.court.pricePerHour,
    );

    _applyPeakPricing = pricing.applyPeak;
    _applyWeekendPricing = pricing.applyWeekend;

    _normalPriceController = TextEditingController(text: _formatRawPrice(pricing.normalPrice));
    _peakPriceController = TextEditingController(text: _formatRawPrice(pricing.peakPrice));
    _weekendSurchargeController = TextEditingController(text: _formatRawPrice(pricing.weekendSurcharge));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _normalPriceController.dispose();
    _peakPriceController.dispose();
    _weekendSurchargeController.dispose();
    super.dispose();
  }

  String _formatRawPrice(double amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  double _parseInputPrice(String text, double fallback) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? fallback;
  }

  // Mở sheet thiết lập bảo trì sân linh hoạt
  Future<void> _toggleMaintenance() async {
    final result = await CourtMaintenanceSheet.show(
      context,
      court: widget.court,
      provider: widget.provider,
    );
    if (result == true && mounted) {
      final updated = widget.provider.courts.firstWhere(
        (c) => c.id == widget.court.id,
        orElse: () => widget.court,
      );
      setState(() {
        _isActive = updated.isActive;
      });
    }
  }

  // Lưu toàn bộ thông tin & cấu hình sân (Tên, Môn thể thao, Giá)
  Future<void> _saveAllChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final normalPrice = _parseInputPrice(_normalPriceController.text, widget.court.pricePerHour);
    final peakPrice = _parseInputPrice(_peakPriceController.text, normalPrice * 1.3);
    final weekendSurcharge = _parseInputPrice(_weekendSurchargeController.text, 20000.0);

    // Lưu cấu hình biểu giá linh hoạt vào CourtPricingService
    await CourtPricingService.instance.savePricing(CourtPricingModel(
      courtId: widget.court.id,
      normalPrice: normalPrice,
      peakPrice: peakPrice,
      applyPeak: _applyPeakPricing,
      weekendSurcharge: weekendSurcharge,
      applyWeekend: _applyWeekendPricing,
    ));

    final success = await widget.provider.updateCourt(
      courtId: widget.court.id,
      name: name,
      pricePerHour: normalPrice,
      peakPrice: peakPrice,
      applyPeak: _applyPeakPricing,
      weekendSurcharge: weekendSurcharge,
      applyWeekend: _applyWeekendPricing,
      sportType: _selectedSportType,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Đã lưu tất cả thay đổi sân thành công!" : "Lưu thay đổi thất bại",
            style: GoogleFonts.lexend(),
          ),
          backgroundColor: success ? const Color(0xFF016B34) : Colors.red,
        ),
      );
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  // Xóa sân con
  Future<void> _confirmDeleteCourt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Xóa sân con này?",
                style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc muốn xóa vĩnh viễn \"${widget.court.name}\"? Tất cả các khung giờ và lịch liên quan sẽ bị xóa.",
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Xóa sân", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final success = await widget.provider.deleteCourt(widget.court.id);
      if (mounted) {
        nav.pop(); // Đóng modal chi tiết
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              success ? "Đã xóa sân \"${widget.court.name}\"" : "Xóa sân thất bại",
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: success ? AppColors.primary : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final court = widget.provider.courts.firstWhere(
      (c) => c.id == widget.court.id,
      orElse: () => widget.court,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // 1. Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Chi tiết & Cấu hình sân",
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onBackground,
                            ),
                          ),
                          Text(
                            "Chỉnh sửa trực tiếp và thiết lập hoạt động",
                            style: GoogleFonts.lexend(fontSize: 11, color: AppColors.secondary),
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
            ),

            // 2. Nội dung cuộn
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. THÔNG TIN CƠ BẢN (CHỈNH SỬA TRỰC TIẾP TÊN & MÔN THỂ THAO)
                    _buildBasicInfoSection(),

                    const SizedBox(height: 16),

                    // B. TRẠNG THÁI HOẠT ĐỘNG & NÚT BẢO TRÌ TRỰC TIẾP
                    _buildMaintenanceSection(),

                    const SizedBox(height: 16),

                    // C. THIẾT LẬP BIỂU GIÁ THEO KHUNG GIỜ
                    _buildHourlyPricingSection(),

                    const SizedBox(height: 16),

                    // D. THỐNG KÊ HIỆU SUẤT HOẠT ĐỘNG
                    _buildPerformanceStatsSection(court),

                    const SizedBox(height: 24),

                    // E. NÚT LƯU THAY ĐỔI & NÚT XÓA SÂN
                    _buildBottomButtons(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A. Mục thông tin cơ bản: Tên sân & Môn thể thao (Editable)
  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Thông tin cơ bản",
                style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tên sân
          Text(
            "Tên sân *",
            style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onBackground),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Nhập tên sân (VD: Sân Pickleball 1)",
              prefixIcon: const Icon(Icons.stadium_outlined, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return "Vui lòng nhập tên sân";
              }
              return null;
            },
          ),

          const SizedBox(height: 14),

          // Môn thể thao
          Text(
            "Môn thể thao *",
            style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onBackground),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedSportType,
            style: GoogleFonts.lexend(fontSize: 13, color: AppColors.onBackground),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.sports_tennis_outlined, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            items: _sportTypes.toSet().map((sport) {
              return DropdownMenuItem(
                value: sport,
                child: Text(sport, style: GoogleFonts.lexend(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedSportType = val);
              }
            },
          ),
        ],
      ),
    );
  }

  // B. Mục trạng thái & Nút Bảo trì trực tiếp
  Widget _buildMaintenanceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isActive ? Icons.check_circle_outline_rounded : Icons.build_circle_outlined,
                    size: 20,
                    color: _isActive ? const Color(0xFF2E7D32) : const Color(0xFFED6C02),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Trạng thái hoạt động",
                    style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isActive ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _isActive ? "Đang mở nhận khách" : "Đang bảo trì",
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thẻ hành động Bảo trì
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isActive ? const Color(0xFFF9FAFB) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isActive ? Colors.grey.shade200 : Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isActive ? "Sân đang hoạt động bình thường" : "Sân đang tạm khóa bảo trì",
                        style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isActive
                            ? "Khách hàng có thể tìm thấy và đặt sân trên app"
                            : "Khách hàng không thể đặt sân này khi đang bảo trì",
                        style: GoogleFonts.lexend(fontSize: 11, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _toggleMaintenance,
                  icon: Icon(
                    _isActive ? Icons.build_circle_outlined : Icons.play_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _isActive ? "Bảo trì" : "Mở lại",
                    style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isActive ? const Color(0xFFED6C02) : const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // C. Biểu giá theo khung giờ (Hourly Pricing)
  Widget _buildHourlyPricingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.price_change_outlined, size: 20, color: Color(0xFF016B34)),
              const SizedBox(width: 8),
              Text(
                "Biểu giá theo khung giờ",
                style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Tự động áp dụng giá theo giờ thường, giờ cao điểm và ngày cuối tuần",
            style: GoogleFonts.lexend(fontSize: 11, color: AppColors.secondary),
          ),
          const SizedBox(height: 14),

          // 1. Giờ thường
          _buildPricingRow(
            icon: Icons.wb_sunny_outlined,
            iconColor: Colors.amber.shade700,
            title: "Khung giờ thường (06:00 - 16:00)",
            subtitle: "Áp dụng các ngày từ T2 đến T6",
            controller: _normalPriceController,
          ),

          const SizedBox(height: 12),

          // 2. Giờ vàng / Cao điểm
          _buildPricingRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.deepOrange,
            title: "Giờ cao điểm / Giờ vàng (16:00 - 22:00)",
            subtitle: "Khung giờ đông khách buổi tối",
            controller: _peakPriceController,
            hasSwitch: true,
            switchValue: _applyPeakPricing,
            onSwitchChanged: (val) => setState(() => _applyPeakPricing = val),
          ),

          const SizedBox(height: 12),

          // 3. Phụ thu cuối tuần
          _buildPricingRow(
            icon: Icons.weekend_outlined,
            iconColor: Colors.indigo,
            title: "Phụ thu cuối tuần (T7, Chủ Nhật)",
            subtitle: "Cộng thêm vào đơn đặt cuối tuần",
            controller: _weekendSurchargeController,
            hasSwitch: true,
            switchValue: _applyWeekendPricing,
            onSwitchChanged: (val) => setState(() => _applyWeekendPricing = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    bool hasSwitch = false,
    bool switchValue = true,
    ValueChanged<bool>? onSwitchChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (hasSwitch)
                Switch.adaptive(
                  value: switchValue,
                  activeThumbColor: AppColors.primary,
                  onChanged: onSwitchChanged,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.lexend(fontSize: 11, color: AppColors.secondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: InputBorder.none,
                      suffixText: "đ/h",
                      suffixStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // D. Thống kê hiệu suất
  Widget _buildPerformanceStatsSection(OwnerCourtEntity court) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 20, color: Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Text(
                "Hiệu suất hoạt động",
                style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: "Đã đặt hôm nay",
                  value: "${court.todayBookingsCount} khung giờ",
                  color: const Color(0xFF1976D2),
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  label: "Tỷ lệ lấp đầy",
                  value: "${(court.todayBookingsCount * 100 / 16).clamp(0, 100).toInt()}%",
                  color: const Color(0xFF2E7D32),
                  icon: Icons.pie_chart_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.lexend(fontSize: 11, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // E. Nút Lưu thay đổi & Nút Xóa sân
  Widget _buildBottomButtons() {
    return Column(
      children: [
        // Nút Lưu tất cả thay đổi
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAllChanges,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              _isSaving ? "Đang lưu thay đổi..." : "Lưu tất cả thay đổi",
              style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF016B34),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Nút Xóa sân con này
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _confirmDeleteCourt,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            label: Text(
              "Xóa sân con này",
              style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
              backgroundColor: Colors.red.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
