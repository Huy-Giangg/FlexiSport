import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/core/utils/location_helper.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_images_widget.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_info_widget.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_reviews_widget.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_rules_widget.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_services_widget.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/edit_venue_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerVenueDetailSheet extends StatefulWidget {
  final OwnerVenueEntity venue;
  final OwnerCourtProvider provider;
  final VoidCallback? onEdit;
  final VoidCallback? onAddCourt;

  const OwnerVenueDetailSheet({
    super.key,
    required this.venue,
    required this.provider,
    this.onEdit,
    this.onAddCourt,
  });

  static Future<void> show(
    BuildContext context, {
    required OwnerVenueEntity venue,
    required OwnerCourtProvider provider,
    required VoidCallback onEdit,
    required VoidCallback onAddCourt,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OwnerVenueDetailSheet(
        venue: venue,
        provider: provider,
        onEdit: onEdit,
        onAddCourt: onAddCourt,
      ),
    );
  }

  @override
  State<OwnerVenueDetailSheet> createState() => _OwnerVenueDetailSheetState();
}

class _OwnerVenueDetailSheetState extends State<OwnerVenueDetailSheet> {
  // Mở form chỉnh sửa thông tin cơ sở ngay tại trang chi tiết không bị thoát màn hình
  Future<void> _openEditSheet() async {
    final currentVenue = widget.provider.selectedVenue ?? widget.venue;
    final messenger = ScaffoldMessenger.of(context);

    await EditVenueSheet.show(
      context,
      venue: currentVenue,
      onSave: ({
        required name,
        required address,
        required openTime,
        required closeTime,
        sportsType,
      }) async {
        final success = await widget.provider.updateVenueInfo(
          name: name,
          address: address,
          openTime: openTime,
          closeTime: closeTime,
          sportsType: sportsType,
        );
        if (mounted) {
          setState(() {});
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                success ? "Đã cập nhật thông tin cơ sở" : "Cập nhật thất bại",
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: success ? AppColors.primary : Colors.red,
            ),
          );
        }
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  bool _isOpenNow(String openTime, String closeTime) {
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');

      final openMin = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMin = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

      return currentMinutes >= openMin && currentMinutes <= closeMin;
    } catch (_) {
      return true;
    }
  }

  // Chuyển toàn bộ sân sang bảo trì hoặc mở lại
  Future<void> _setAllCourtsMaintenance(bool setToActive) async {
    final actionText = setToActive ? "Mở hoạt động toàn bộ sân" : "Bảo trì toàn bộ sân";
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              setToActive ? Icons.check_circle_outline_rounded : Icons.build_circle_outlined,
              color: setToActive ? const Color(0xFF2E7D32) : const Color(0xFFED6C02),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "$actionText?",
                style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          setToActive
              ? "Tất cả các sân con trong cụm sân \"${widget.venue.name}\" sẽ được mở lại hoạt động."
              : "Tất cả các sân con trong cụm sân \"${widget.venue.name}\" sẽ chuyển sang trạng thái bảo trì.",
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
              backgroundColor: setToActive ? const Color(0xFF2E7D32) : const Color(0xFFED6C02),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Xác nhận", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.provider.setAllCourtsStatus(setToActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (setToActive ? "Đã mở hoạt động toàn bộ sân" : "Đã chuyển toàn bộ sân sang bảo trì")
                  : "Thao tác thất bại",
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: success ? AppColors.primary : Colors.red,
          ),
        );
      }
    }
  }

  // Xác nhận xóa toàn bộ cụm sân venue
  Future<void> _confirmDeleteVenue() async {
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
                "Xóa cụm sân này?",
                style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Hành động này sẽ xóa vĩnh viễn cụm sân \"${widget.venue.name}\" cùng toàn bộ dữ liệu liên quan trong cơ sở dữ liệu.",
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
            child: Text("Xóa cụm sân", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      final success = await widget.provider.deleteVenue(widget.venue.id);
      if (mounted) {
        nav.pop(); // Đóng sheet chi tiết
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              success ? "Đã xóa cụm sân \"${widget.venue.name}\"" : "Xóa cụm sân thất bại",
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
    final venue = widget.provider.selectedVenue ?? widget.venue;
    final provider = widget.provider;
    final isOpen = _isOpenNow(venue.openTime, venue.closeTime);
    final courts = provider.courts;
    final allMaintenance = courts.isNotEmpty && courts.every((c) => !c.isActive);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Banner & Overlay (Chỉ giữ nút Đóng để tối ưu, bỏ nút sửa & 3 chấm)
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner Image lấy trực tiếp từ venue.logoUrl
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.primaryLightBg,
                  child: _buildBannerImage(venue.logoUrl),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Bar: Chỉ giữ lại nút Đóng (Tối ưu giao diện, không trùng lặp)
              Positioned(
                top: 12,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.onBackground),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),

          // Scrollable Content with Venue Floating Info Card and 5 Detailed Tabs
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // THẺ THÔNG TIN CƠ SỞ CHÍNH (Venue Overview Card giống người dùng)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        // Hàng 1: Logo từ logo_url, Tên, Rating, Môn thể thao, Trạng thái
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLightBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _buildVenueLogo(venue.logoUrl),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          venue.name,
                                          style: GoogleFonts.lexend(
                                            color: AppColors.onBackground,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 14),
                                            const SizedBox(width: 2),
                                            Text(
                                              "${venue.rating}",
                                              style: GoogleFonts.lexend(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildSportTag(venue.sportsType),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isOpen ? "Đang mở cửa" : "Đã đóng cửa",
                                          style: GoogleFonts.lexend(
                                            fontSize: 11,
                                            color: isOpen ? const Color(0xFF2E7D32) : Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade200, height: 1),
                        const SizedBox(height: 12),

                        // Hàng 2: Địa chỉ & Khoảng cách
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venue.address,
                                    style: GoogleFonts.lexend(
                                      fontSize: 13,
                                      color: AppColors.onBackground,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Khoảng cách: ${LocationHelper.formatDistance(LocationHelper.calculateDistanceFromDefault(21.0285, 105.8542))}",
                                    style: GoogleFonts.lexend(
                                      fontSize: 11,
                                      color: const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Hàng 3: Khung giờ hoạt động
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${venue.openTime} - ${venue.closeTime} (Mở cửa hàng ngày)",
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: AppColors.onBackground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Hàng 4: Hotline liên hệ
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF0288D1)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "0354676200 (Hotline quản lý sân)",
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: AppColors.onBackground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Hàng 5: Bộ 3 nút điều khiển (Bảo trì | Chỉnh sửa | Xóa sân) cạnh nhau
                        Row(
                          children: [
                            // 1. Nút Bảo trì / Mở lại toàn bộ sân
                            Expanded(
                              flex: 4,
                              child: ElevatedButton.icon(
                                onPressed: () => _setAllCourtsMaintenance(allMaintenance),
                                icon: Icon(
                                  allMaintenance ? Icons.play_arrow_rounded : Icons.build_circle_outlined,
                                  size: 15,
                                ),
                                label: Text(
                                  allMaintenance ? "Mở tất cả" : "Bảo trì",
                                  style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: allMaintenance ? const Color(0xFF2E7D32) : const Color(0xFFED6C02),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 2. Nút Chỉnh sửa thông tin cơ sở
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                onPressed: _openEditSheet,
                                icon: const Icon(Icons.edit_outlined, size: 15),
                                label: Text(
                                  "Sửa",
                                  style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 3. Nút Xóa cụm sân (nằm cạnh nút sửa & bảo trì)
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                onPressed: _confirmDeleteVenue,
                                icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.red),
                                label: Text(
                                  "Xóa",
                                  style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                                  backgroundColor: Colors.red.withValues(alpha: 0.04),
                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 5 TABS CHI TIẾT (Giống hệt giao diện người dùng xem sân)
                  SizedBox(
                    height: 520,
                    child: DefaultTabController(
                      length: 5,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: AppColors.onBackground,
                            labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13),
                            unselectedLabelColor: Colors.grey.shade600,
                            unselectedLabelStyle: GoogleFonts.lexend(fontWeight: FontWeight.normal, fontSize: 13),
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: const [
                              Tab(text: "Thông tin"),
                              Tab(text: "Dịch vụ"),
                              Tab(text: "Hình ảnh"),
                              Tab(text: "Điều khoản & quy định"),
                              Tab(text: "Đánh giá"),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                const TabInfoWidget(),
                                const TabServicesWidget(),
                                TabImagesWidget(stadiumId: venue.id),
                                const TabRulesWidget(),
                                TabReviewsWidget(venueId: venue.id),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  // Hiển thị Banner từ trường logo_url của venues
  Widget _buildBannerImage(String? logoUrl) {
    if (logoUrl == null || logoUrl.trim().isEmpty) {
      return _buildPlaceholder();
    }
    final url = logoUrl.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 180,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  // Hiển thị Logo vuông từ trường logo_url của venues
  Widget _buildVenueLogo(String? logoUrl) {
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      final url = logoUrl.trim();
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.startsWith('http')
            ? Image.network(
                url,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.stadium_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              )
            : Image.asset(
                url,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.stadium_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
      );
    }
    return const Icon(
      Icons.stadium_rounded,
      color: AppColors.primary,
      size: 32,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLightBg,
      width: double.infinity,
      height: 180,
      child: const Center(
        child: Icon(Icons.stadium_rounded, size: 54, color: AppColors.primary),
      ),
    );
  }

  Widget _buildSportTag(String? sportsType) {
    final type = sportsType?.trim() ?? 'Thể thao';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1, color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_tennis_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            type,
            style: GoogleFonts.lexend(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
