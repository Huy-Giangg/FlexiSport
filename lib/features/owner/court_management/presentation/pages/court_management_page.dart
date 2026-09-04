import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/add_edit_court_dialog.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/add_venue_sheet.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/court_card_widget.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/court_detail_config_sheet.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/court_maintenance_sheet.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/edit_venue_sheet.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/owner_venue_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CourtManagementPage extends StatefulWidget {
  const CourtManagementPage({super.key});

  @override
  State<CourtManagementPage> createState() => _CourtManagementPageState();
}

class _CourtManagementPageState extends State<CourtManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCourt(BuildContext context, OwnerCourtProvider provider) {
    final messenger = ScaffoldMessenger.of(context);
    final defaultSport = provider.selectedVenue?.sportsType ?? 'Pickleball';
    AddEditCourtDialog.show(
      context,
      defaultSportType: defaultSport,
      onSave: ({required name, required pricePerHour, sportType}) async {
        final success = await provider.addCourt(
          name: name,
          pricePerHour: pricePerHour,
          sportType: sportType,
        );
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                success ? "Đã thêm sân mới thành công" : "Thêm sân thất bại",
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: success ? AppColors.primary : Colors.red,
            ),
          );
        }
      },
    );
  }

  void _showEditCourt(
    BuildContext context,
    OwnerCourtProvider provider,
    OwnerCourtEntity court,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    AddEditCourtDialog.show(
      context,
      court: court,
      defaultSportType: court.sportType ?? 'Pickleball',
      onSave: ({required name, required pricePerHour, sportType}) async {
        final success = await provider.updateCourt(
          courtId: court.id,
          name: name,
          pricePerHour: pricePerHour,
          sportType: sportType,
        );
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                success ? "Đã cập nhật sân thành công" : "Cập nhật thất bại",
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: success ? AppColors.primary : Colors.red,
            ),
          );
        }
      },
    );
  }

  void _confirmDeleteCourt(
    BuildContext context,
    OwnerCourtProvider provider,
    OwnerCourtEntity court,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              "Xóa sân con",
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa sân \"${court.name}\"? Hành động này không thể hoàn tác.",
          style: GoogleFonts.lexend(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Hủy", style: GoogleFonts.lexend(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await provider.deleteCourt(court.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Đã xóa sân \"${court.name}\""
                          : "Xóa sân thất bại",
                      style: GoogleFonts.lexend(),
                    ),
                    backgroundColor: success ? AppColors.primary : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Xóa sân",
              style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmToggleStatus(
    BuildContext context,
    OwnerCourtProvider provider,
    OwnerCourtEntity court,
  ) {
    CourtMaintenanceSheet.show(
      context,
      court: court,
      provider: provider,
    );
  }

  void _showVenueDetail(BuildContext context, OwnerCourtProvider provider) {
    if (provider.selectedVenue == null) return;
    OwnerVenueDetailSheet.show(
      context,
      venue: provider.selectedVenue!,
      provider: provider,
      onEdit: () => _showEditVenue(context, provider),
      onAddCourt: () => _showAddCourt(context, provider),
    );
  }

  void _showAddVenue(BuildContext context, OwnerCourtProvider provider) {
    final messenger = ScaffoldMessenger.of(context);
    AddVenueSheet.show(
      context,
      onSave: ({
        required name,
        required address,
        required openTime,
        required closeTime,
        sportsType,
        imageFile,
      }) async {
        final success = await provider.addVenue(
          name: name,
          address: address,
          openTime: openTime,
          closeTime: closeTime,
          sportsType: sportsType,
          imageFile: imageFile,
        );
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? "Đã thêm cụm sân \"$name\" thành công"
                    : "Thêm cụm sân thất bại",
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: success ? AppColors.primary : Colors.red,
            ),
          );
        }
        return success;
      },
    );
  }

  void _showEditVenue(BuildContext context, OwnerCourtProvider provider) {
    if (provider.selectedVenue == null) return;
    final messenger = ScaffoldMessenger.of(context);
    EditVenueSheet.show(
      context,
      venue: provider.selectedVenue!,
      onSave:
          ({
            required name,
            required address,
            required openTime,
            required closeTime,
            sportsType,
          }) async {
            final success = await provider.updateVenueInfo(
              name: name,
              address: address,
              openTime: openTime,
              closeTime: closeTime,
              sportsType: sportsType,
            );
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? "Đã cập nhật thông tin cơ sở"
                        : "Cập nhật thất bại",
                    style: GoogleFonts.lexend(),
                  ),
                  backgroundColor: success ? AppColors.primary : Colors.red,
                ),
              );
            }
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerCourtProvider>();
    final venue = provider.selectedVenue;
    final courts = provider.filteredCourts;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quản lý sân",
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
        actions: [
          // Nút đổi cơ sở (nếu có nhiều hơn 1)
          if (provider.venues.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primary,
              ),
              tooltip: "Đổi cụm sân",
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (id) {
                final selected = provider.venues.firstWhere((v) => v.id == id);
                provider.selectVenue(selected);
              },
              itemBuilder: (context) => provider.venues.map((v) {
                final isSelected = v.id == venue?.id;
                return PopupMenuItem<String>(
                  value: v.id,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppColors.primary : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          v.name,
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          // Nút thêm cụm sân mới (+)
          IconButton(
            onPressed: () => _showAddVenue(context, provider),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: "Thêm cụm sân mới",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshCourts(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thẻ thông tin cơ sở & Thống kê
              if (venue != null)
                _buildVenueOverviewCard(context, venue, provider),

              const SizedBox(height: 16),

              // 2. Thanh tìm kiếm & Bộ lọc
              _buildFilterToolbar(context, provider),

              const SizedBox(height: 16),

              // 3. Danh sách các sân con & Nút Thêm sân mới
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Danh sách sân con (${courts.length})",
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                        if (provider.statusFilter != 'all' ||
                            provider.searchQuery.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                              provider.setStatusFilter('all');
                              provider.setSportFilter(null);
                            },
                            child: Text(
                              "(Đặt lại lọc)",
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Nút Thêm sân mới bên cạnh tiêu đề
                    InkWell(
                      onTap: () => _showAddCourt(context, provider),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Thêm sân mới",
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Danh sách
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (courts.isEmpty)
                _buildEmptyState(provider)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: courts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    return CourtCardWidget(
                      court: court,
                      onEdit: () => _showEditCourt(context, provider, court),
                      onDelete: () =>
                          _confirmDeleteCourt(context, provider, court),
                      onToggleStatus: () =>
                          _confirmToggleStatus(context, provider, court),
                      onViewDetail: () =>
                          CourtDetailConfigSheet.show(context, court: court, provider: provider),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET THẺ TỔNG QUAN CƠ SỞ & THỐNG KÊ NHANH ---
  Widget _buildVenueOverviewCard(
    BuildContext context,
    dynamic venue,
    OwnerCourtProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVenueDetail(context, provider),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin cơ sở
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.stadium_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onBackground,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Chi tiết",
                                      style: GoogleFonts.lexend(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  venue.address,
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    color: AppColors.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${venue.openTime} - ${venue.closeTime}",
                                style: GoogleFonts.lexend(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (venue.sportsType != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  "•",
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  venue.sportsType!,
                                  style: GoogleFonts.lexend(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 14),

                // Lưới 4 ô thống kê nhanh
                Row(
                  children: [
                    _buildMiniStat(
                      label: "Tổng sân",
                      value: "${provider.totalCourtsCount}",
                      icon: Icons.grid_view_rounded,
                      color: AppColors.primary,
                      bgColor: AppColors.primaryLightBg,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStat(
                      label: "Hoạt động",
                      value: "${provider.activeCourtsCount}",
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFE8F5E9),
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStat(
                      label: "Bảo trì",
                      value: "${provider.maintenanceCourtsCount}",
                      icon: Icons.build_circle_outlined,
                      color: const Color(0xFFED6C02),
                      bgColor: const Color(0xFFFFF4E5),
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStat(
                      label: "Đặt hôm nay",
                      value: "${provider.todayTotalBookings}",
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFF0288D1),
                      bgColor: const Color(0xFFE1F5FE),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET THANH TÌM KIẾM VÀ FILTER CHIPS ---
  Widget _buildFilterToolbar(
    BuildContext context,
    OwnerCourtProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => provider.setSearchQuery(val),
              style: GoogleFonts.lexend(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Tìm kiếm theo tên sân hoặc môn thể thao...",
                hintStyle: GoogleFonts.lexend(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                  label: "Tất cả (${provider.totalCourtsCount})",
                  isSelected: provider.statusFilter == 'all',
                  onTap: () => provider.setStatusFilter('all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: "Đang hoạt động (${provider.activeCourtsCount})",
                  isSelected: provider.statusFilter == 'active',
                  onTap: () => provider.setStatusFilter('active'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: "Đang bảo trì (${provider.maintenanceCourtsCount})",
                  isSelected: provider.statusFilter == 'maintenance',
                  onTap: () => provider.setStatusFilter('maintenance'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.secondary,
          ),
        ),
      ),
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState(OwnerCourtProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLightBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stadium_outlined,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Chưa có sân nào phù hợp",
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Hãy thêm sân mới hoặc thay đổi từ khóa tìm kiếm",
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddCourt(context, provider),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                "Thêm sân đầu tiên",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
