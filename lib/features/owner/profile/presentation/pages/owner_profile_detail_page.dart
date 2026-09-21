import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/widgets/edit_venue_sheet.dart';
import 'package:flexisport_app/features/owner/profile/presentation/widgets/bank_settings_dialog.dart';
import 'package:flexisport_app/features/owner/profile/presentation/widgets/edit_owner_profile_dialog.dart';

class OwnerProfileDetailPage extends StatefulWidget {
  const OwnerProfileDetailPage({super.key});

  @override
  State<OwnerProfileDetailPage> createState() => _OwnerProfileDetailPageState();
}

class _OwnerProfileDetailPageState extends State<OwnerProfileDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profileData = data;
        });
      }
    } catch (_) {}
  }

  void _openEditProfile() {
    EditOwnerProfileDialog.show(
      context,
      initialData: _profileData,
      onSaved: () async {
        await _loadProfile();
      },
    );
  }


  void _openEditVenue(BuildContext context, OwnerVenueEntity venue, OwnerCourtProvider courtProvider) {
    EditVenueSheet.show(
      context,
      venue: venue,
      onSave: ({
        required String name,
        required String address,
        required String openTime,
        required String closeTime,
        String? sportsType,
      }) async {
        await courtProvider.selectVenue(venue);
        final success = await courtProvider.updateVenueInfo(
          name: name,
          address: address,
          openTime: openTime,
          closeTime: closeTime,
          sportsType: sportsType,
          bankName: venue.bankName,
          accountNumber: venue.accountNumber,
        );
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? "Đã cập nhật thông tin cụm sân!" : "Cập nhật thất bại",
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: success ? const Color(0xFF006D38) : Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final courtProvider = context.watch<OwnerCourtProvider>();
    final venues = courtProvider.venues;

    final ownerDisplayName =
        _profileData?['name']?.toString().isNotEmpty == true
            ? _profileData!['name'].toString()
            : (user?.userMetadata?['full_name'] as String? ??
                user?.userMetadata?['name'] as String? ??
                'Chủ cơ sở');

    final ownerPhone = _profileData?['phone']?.toString().isNotEmpty == true
        ? _profileData!['phone'].toString()
        : (user?.userMetadata?['phone'] as String? ?? 'Chưa cập nhật SĐT');

    final ownerEmail = user?.email ??
        _profileData?['email']?.toString() ??
        'Chưa cập nhật email';

    final initialLetter = ownerDisplayName.isNotEmpty
        ? ownerDisplayName.trim()[0].toUpperCase()
        : 'C';

    final totalCourts = venues.fold<int>(0, (sum, v) => sum + v.totalCourts);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Header màu xanh với nút Back & Tiêu đề "Hồ sơ chủ sân"
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryContainer,
                  AppColors.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/owner/profile');
                          }
                        },
                      ),
                    ),
                    Text(
                      "Hồ sơ chủ sân",
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Nội dung cuộn
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadProfile();
                await courtProvider.loadData();
              },
              color: const Color(0xFF006D38),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Card Header Thông tin cá nhân chủ sân
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar chủ sân với ký tự viết hoa
                              Stack(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF006D38),
                                          Color(0xFF059669),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF006D38).withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initialLetter,
                                      style: GoogleFonts.lexend(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE2A62C),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),

                              // Thông tin chủ sân
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ownerDisplayName,
                                      style: GoogleFonts.lexend(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1B1C19),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),

                                    // Badge Đối tác VIP
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2A62C).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.workspace_premium_rounded,
                                            size: 13,
                                            color: Color(0xFFB45309),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Đối tác Chủ sân VIP",
                                            style: GoogleFonts.lexend(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFB45309),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Số điện thoại
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            ownerPhone,
                                            style: GoogleFonts.lexend(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),

                                    // Email
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.mail_outline_rounded,
                                          size: 13,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            ownerEmail,
                                            style: GoogleFonts.lexend(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Nút sửa nhanh thông tin cá nhân
                              IconButton(
                                onPressed: _openEditProfile,
                                icon: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF006D38).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF006D38),
                                    size: 18,
                                  ),
                                ),
                                tooltip: "Chỉnh sửa thông tin cá nhân",
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),

                          // Thẻ thống kê nhanh: Cụm sân - Sân con - Trạng thái
                          Row(
                            children: [
                              _buildStatItem(
                                icon: Icons.stadium_rounded,
                                label: "Cụm cơ sở",
                                value: "${venues.length} cụm sân",
                                color: const Color(0xFF006D38),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.grey.shade200,
                              ),
                              _buildStatItem(
                                icon: Icons.sports_soccer_rounded,
                                label: "Tổng sân con",
                                value: "$totalCourts sân",
                                color: const Color(0xFF0284C7),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.grey.shade200,
                              ),
                              _buildStatItem(
                                icon: Icons.verified_user_rounded,
                                label: "Xác thực KYC",
                                value: "Đã xác thực",
                                color: const Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3. Tab Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF006D38),
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        indicatorColor: const Color(0xFF006D38),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 3,
                        tabs: [
                          const Tab(text: "Thông tin cá nhân"),
                          Tab(text: "Cụm sân (${venues.length})"),
                          const Tab(text: "Tài khoản NH"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. TabBar Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: [
                        // TAB 0: Thông tin cá nhân chủ sân
                        _buildOwnerPersonalInfoTab(
                          displayName: ownerDisplayName,
                          phone: ownerPhone,
                          email: ownerEmail,
                          userId: user?.id ?? '',
                        ),

                        // TAB 1: Danh sách các cụm sân sở hữu
                        _buildOwnerVenuesListTab(
                          venues: venues,
                          courtProvider: courtProvider,
                        ),

                        // TAB 2: Tài khoản ngân hàng nhận doanh thu
                        _buildBankTab(
                          venues.isNotEmpty ? (courtProvider.selectedVenue ?? venues.first) : null,
                          courtProvider,
                        ),
                      ][_tabController.index],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // 5. Nút bấm tương ứng theo Tab ở đáy màn hình (Ẩn khi ở tab Cụm sân)
          // if (_tabController.index != 1)
          //   Container(
          //     padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withValues(alpha: 0.05),
          //           blurRadius: 10,
          //           offset: const Offset(0, -3),
          //         ),
          //       ],
          //     ),
          //     child: SizedBox(
          //       width: double.infinity,
          //       height: 48,
          //       child: _buildBottomActionButton(courtProvider, venues),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.lexend(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B1C19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 10.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 0: Thông tin cá nhân chủ sân
  Widget _buildOwnerPersonalInfoTab({
    required String displayName,
    required String phone,
    required String email,
    required String userId,
  }) {
    final partnerCode = userId.length >= 6
        ? "FS-OWNER-${userId.substring(0, 6).toUpperCase()}"
        : "FS-OWNER-001";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.badge_outlined,
            iconColor: const Color(0xFF006D38),
            label: "Họ và tên chủ sân",
            value: displayName,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            iconColor: const Color(0xFF16A34A),
            label: "Số điện thoại liên hệ",
            value: phone,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.mail_outline_rounded,
            iconColor: const Color(0xFF0D9488),
            label: "Email tài khoản",
            value: email,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.admin_panel_settings_outlined,
            iconColor: const Color(0xFF0284C7),
            label: "Vai trò",
            value: "Chủ cơ sở thể thao",
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.qr_code_rounded,
            iconColor: const Color(0xFF8B5CF6),
            label: "Mã đối tác",
            value: partnerCode,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF10B981),
            label: "Trạng thái định danh",
            value: "Đã xác thực hợp lệ",
          ),
        ],
      ),
    );
  }

  // TAB 1: Danh sách các cụm sân sở hữu
  Widget _buildOwnerVenuesListTab({
    required List<OwnerVenueEntity> venues,
    required OwnerCourtProvider courtProvider,
  }) {
    if (venues.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF006D38).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stadium_outlined,
                color: Color(0xFF006D38),
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Chưa có cụm sân thể thao nào",
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B1C19),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Danh sách các cụm sân thể thao bạn sở hữu sẽ hiển thị tại đây.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            "Cụm cơ sở đang sở hữu (${venues.length})",
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B1C19),
            ),
          ),
        ),

        // Danh sách các thẻ cụm sân
        ...venues.map((venue) => _buildVenueItemCard(venue, courtProvider)),
      ],
    );
  }

  Widget _buildVenueItemCard(OwnerVenueEntity venue, OwnerCourtProvider courtProvider) {
    final sportsType = venue.sportsType ?? "Khu liên hợp thể thao";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon sân
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D38).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.stadium_rounded,
                  color: Color(0xFF006D38),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Thông tin cơ sở
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C19),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Badge loại hình thể thao & số sân
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2A62C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sportsType,
                            style: GoogleFonts.lexend(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${venue.totalCourts} sân con",
                            style: GoogleFonts.lexend(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
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
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // Địa chỉ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  venue.address,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Giờ hoạt động
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                "Giờ mở cửa: ${venue.openTime} - ${venue.closeTime}",
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Nút chỉnh sửa cụm sân này
          // Row(
          //   children: [
          //     Expanded(
          //       child: OutlinedButton.icon(
          //         onPressed: () => _openEditVenue(context, venue, courtProvider),
          //         icon: const Icon(Icons.edit_note_rounded, size: 16),
          //         label: Text(
          //           "Chỉnh sửa cụm sân",
          //           style: GoogleFonts.lexend(
          //             fontSize: 12.5,
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //         style: OutlinedButton.styleFrom(
          //           side: const BorderSide(color: Color(0xFF006D38)),
          //           foregroundColor: const Color(0xFF006D38),
          //           padding: const EdgeInsets.symmetric(vertical: 8),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(10),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  // TAB 2: Tài khoản ngân hàng
  Widget _buildBankTab(OwnerVenueEntity? venue, OwnerCourtProvider courtProvider) {
    final bankName = venue?.bankName?.isNotEmpty == true
        ? venue!.bankName!
        : "Chưa cấu hình ngân hàng";
    final accountNumber = venue?.accountNumber?.isNotEmpty == true
        ? venue!.accountNumber!
        : "Chưa có số tài khoản";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D38).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF006D38),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tài khoản nhận thanh toán",
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C19),
                      ),
                    ),
                    Text(
                      "Nhận tiền trực tiếp từ khách hàng đặt lịch trên FlexiSport",
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildDetailKeyValue("Ngân hàng nhận tiền:", bankName),
          _buildDetailKeyValue("Số tài khoản:", accountNumber),
          _buildDetailKeyValue(
            "Chủ tài khoản:",
            _profileData?['name']?.toString().toUpperCase() ?? "CHỦ CƠ SỞ",
          ),
          _buildDetailKeyValue(
            "Trạng thái liên kết:",
            venue?.accountNumber?.isNotEmpty == true ? "Sẵn sàng nhận thanh toán" : "Cần cấu hình tài khoản",
            valueColor: venue?.accountNumber?.isNotEmpty == true
                ? const Color(0xFF006D38)
                : Colors.orange.shade800,
          ),
          const SizedBox(height: 14),

          if (venue != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  BankSettingsDialog.show(context, venue, courtProvider);
                },
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(
                  "Cấu hình tài khoản ngân hàng",
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF006D38)),
                  foregroundColor: const Color(0xFF006D38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Nút hành động chính ở thanh cố định phía dưới
  Widget _buildBottomActionButton(OwnerCourtProvider courtProvider, List<OwnerVenueEntity> venues) {
    if (_tabController.index == 2) {
      // Tab ngân hàng
      final venue = venues.isNotEmpty ? (courtProvider.selectedVenue ?? venues.first) : null;
      return ElevatedButton.icon(
        onPressed: venue != null
            ? () => BankSettingsDialog.show(context, venue, courtProvider)
            : null,
        icon: const Icon(Icons.account_balance_rounded, size: 20),
        label: Text(
          "Cập nhật tài khoản ngân hàng",
          style: GoogleFonts.lexend(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006D38),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      );
    }

    // Mặc định Tab 0: Thông tin cá nhân chủ sân
    return ElevatedButton.icon(
      onPressed: _openEditProfile,
      icon: const Icon(Icons.edit_note_rounded, size: 20),
      label: Text(
        "Chỉnh sửa thông tin cá nhân",
        style: GoogleFonts.lexend(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006D38),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildDetailKeyValue(String key, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              key,
              style: GoogleFonts.lexend(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lexend(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1B1C19),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B1C19),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 48, color: Color(0xFFF3F4F6));
  }
}
