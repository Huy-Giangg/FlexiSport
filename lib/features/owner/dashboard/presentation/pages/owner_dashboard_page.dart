import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/providers/owner_booking_provider.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/widgets/booking_detail_sheet.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/dashboard/presentation/widgets/owner_notifications_bottom_sheet.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider = context.read<OwnerBookingProvider>();
      if (bookingProvider.venues.isEmpty || bookingProvider.allBookings.isEmpty) {
        bookingProvider.initialize();
      }
      final courtProvider = context.read<OwnerCourtProvider>();
      if (courtProvider.venues.isEmpty || courtProvider.courts.isEmpty) {
        courtProvider.loadData();
      }
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];
    final weekday = weekdays[now.weekday % 7];
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    return "$weekday, $day/$month/$year";
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<OwnerBookingProvider>();
    final courtProvider = context.watch<OwnerCourtProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await bookingProvider.refreshBookings();
          await courtProvider.refreshCourts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, bookingProvider, courtProvider),
              const SizedBox(height: 80),
              _buildStatsOverview(bookingProvider, courtProvider),
              const SizedBox(height: 24),
              _buildCourtStatusSection(context, courtProvider, bookingProvider),
              const SizedBox(height: 24),
              _buildRecentBookingsSection(context, bookingProvider),
              const SizedBox(height: 100), // Khoảng trống cho NavigationBar
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL CHỌN CƠ SỞ / ĐỔI SÂN ---
  void _showVenueSelector(
    BuildContext context,
    OwnerBookingProvider bookingProvider,
    OwnerCourtProvider courtProvider,
  ) {
    final venues = bookingProvider.venues.isNotEmpty
        ? bookingProvider.venues
        : courtProvider.venues;

    if (venues.isEmpty) return;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Chọn cơ sở quản lý",
                  style: GoogleFonts.lexend(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: venues.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final venue = venues[index];
                  final isSelected = venue.id == bookingProvider.selectedVenue?.id;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLightBg : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.stadium_rounded,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        venue.name,
                        style: GoogleFonts.lexend(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.onBackground,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          venue.address,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        bookingProvider.selectVenue(venue);
                        courtProvider.selectVenue(venue);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER & VENUE CARD ---
  Widget _buildHeader(
    BuildContext context,
    OwnerBookingProvider bookingProvider,
    OwnerCourtProvider courtProvider,
  ) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        'Chủ sân';
    final initialLetter = displayName.isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'C';

    final double topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Background banner với hình nền lá xanh đặc trưng (như hình 2 của người dùng)
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.png"),
              fit: BoxFit.cover,
            ),
          ),
          padding: EdgeInsets.only(
            top: topPadding + 14,
            left: 16,
            right: 16,
            bottom: 80, // Khoảng trống rộng rãi để card sân không bị đè lên avatar/tên
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            
            children: [
              // Thông tin người dùng: Avatar tím + Ngày tháng + Tên vàng
              Expanded(
                child: Row(
                  
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initialLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFormattedDate(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Icons: Ngôi sao đỏ + Chuông thông báo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, color: Colors.yellow, size: 16),
                  ),
                  const SizedBox(width: 6),
                  const OwnerNotificationIcon(),
                ],
              ),
            ],
          ),
        ),

        // 2. Thẻ Venue Card nổi và ở giữa 2 màu appbar và body
        Positioned(
          bottom: -55,
          left: 16,
          right: 16,
          child: _buildVenueCard(context, bookingProvider, courtProvider),
        ),
      ],
    );
  }

  Widget _buildVenueCard(
    BuildContext context,
    OwnerBookingProvider bookingProvider,
    OwnerCourtProvider courtProvider,
  ) {
    final venue = bookingProvider.selectedVenue ?? courtProvider.selectedVenue;
    final venueName = venue?.name ?? "Cơ sở thể thao";
    final venueAddress = venue?.address ?? "Chưa cập nhật địa chỉ";
    final rating = venue?.rating ?? 5.0;
    final sportsType = venue?.sportsType ?? "Thể thao";
    final hasMultipleVenues = bookingProvider.venues.length > 1 || courtProvider.venues.length > 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showVenueSelector(context, bookingProvider, courtProvider),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  "assets/images/img_venues/bong1.png",
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 76,
                    height: 76,
                    color: AppColors.primaryLightBg,
                    child: const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 32),
                  ),
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
                            venueName,
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Đang mở cửa",
                            style: GoogleFonts.lexend(
                              color: AppColors.primaryContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
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
                            venueAddress,
                            style: GoogleFonts.lexend(
                              color: AppColors.secondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 15,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.lexend(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLightBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sportsType,
                            style: GoogleFonts.lexend(
                              color: AppColors.primaryContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (hasMultipleVenues)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Đổi sân",
                                    style: GoogleFonts.lexend(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  // --- THỐNG KÊ TRONG NGÀY ---
  Widget _buildStatsOverview(
    OwnerBookingProvider bookingProvider,
    OwnerCourtProvider courtProvider,
  ) {
    final revenue = bookingProvider.todayTotalRevenue;
    final totalBookings = bookingProvider.todayBookingsCount;
    final confirmedCount = bookingProvider.todayConfirmedCount;
    final venue = bookingProvider.selectedVenue ?? courtProvider.selectedVenue;

    // Tính toán tỷ lệ lấp đầy thực tế
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayBookings = bookingProvider.allBookings
        .where((b) => b.bookingDate == todayStr && !b.isCancelled)
        .toList();

    final courtsCount = courtProvider.courts.isNotEmpty
        ? courtProvider.courts.length
        : (venue?.totalCourts ?? 1);
    
    // Mỗi sân có khoảng 28-30 slot hoạt động trong ngày (từ 06:00 - 22:00)
    final totalAvailableSlots = (courtsCount * 28).clamp(1, 1000);
    final todaySlotsBooked = todayBookings.fold<int>(
      0,
      (sum, b) => sum + (b.slotIndexes.isNotEmpty ? b.slotIndexes.length : (b.slotsCount > 0 ? b.slotsCount : 2)),
    );
    final occupancyPercent = ((todaySlotsBooked / totalAvailableSlots) * 100).clamp(0, 100).toInt();

    final ratingVal = venue?.rating ?? 5.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thống kê hôm nay",
            style: GoogleFonts.lexend(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _buildStatCard(
                title: "Doanh thu",
                value: _formatCurrency(revenue),
                subText: "Tổng thu hôm nay",
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
              ),
              _buildStatCard(
                title: "Lượt đặt sân",
                value: "$totalBookings lượt",
                subText: "$confirmedCount đã duyệt",
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF0288D1),
                bgColor: const Color(0xFFE1F5FE),
              ),
              _buildStatCard(
                title: "Tỷ lệ lấp đầy",
                value: "$occupancyPercent%",
                subText: todaySlotsBooked > 0 ? "$todaySlotsBooked slot đã đặt" : "$courtsCount sân đang mở",
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFFED6C02),
                bgColor: const Color(0xFFFFF4E5),
              ),
              _buildStatCard(
                title: "Đánh giá sân",
                value: "${ratingVal.toStringAsFixed(1)} ★",
                subText: "Chất lượng dịch vụ",
                icon: Icons.star_rounded,
                iconColor: const Color(0xFF9C27B0),
                bgColor: const Color(0xFFF3E5F5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subText,
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TRỢ GIÚP TÍNH THỜI GIAN ĐẶT SÂN ---
  DateTime? _getBookingStartTime(OwnerBookingEntity booking, DateTime date) {
    if (booking.timeRangeText.contains('-')) {
      final startPart = booking.timeRangeText.split('-')[0].trim();
      final parts = startPart.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 6;
        final m = int.tryParse(parts[1]) ?? 0;
        return DateTime(date.year, date.month, date.day, h, m);
      }
    }
    if (booking.slotIndexes.isNotEmpty) {
      final firstSlot = booking.slotIndexes.reduce((a, b) => a < b ? a : b);
      final totalMinutes = 6 * 60 + firstSlot * 30;
      return DateTime(date.year, date.month, date.day, totalMinutes ~/ 60, totalMinutes % 60);
    }
    return null;
  }

  DateTime? _getBookingEndTime(OwnerBookingEntity booking, DateTime date) {
    if (booking.timeRangeText.contains('-')) {
      final endPart = booking.timeRangeText.split('-')[1].trim().split(' ')[0];
      final parts = endPart.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 22;
        final m = int.tryParse(parts[1]) ?? 0;
        return DateTime(date.year, date.month, date.day, h, m);
      }
    }
    if (booking.slotIndexes.isNotEmpty) {
      final lastSlot = booking.slotIndexes.reduce((a, b) => a > b ? a : b);
      final totalMinutes = 6 * 60 + (lastSlot + 1) * 30;
      return DateTime(date.year, date.month, date.day, totalMinutes ~/ 60, totalMinutes % 60);
    }
    return null;
  }

  // --- TRẠNG THÁI SÂN HIỆN TẠI (THEO THỜI GIAN THỰC) ---
  Widget _buildCourtStatusSection(
    BuildContext context,
    OwnerCourtProvider courtProvider,
    OwnerBookingProvider bookingProvider,
  ) {
    final courts = courtProvider.courts;
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayBookings = bookingProvider.allBookings
        .where((b) => b.bookingDate == todayStr && !b.isCancelled)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Trạng thái sân hiện tại",
                style: GoogleFonts.lexend(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/owner/courts'),
                child: Text(
                  "Xem tất cả (${courts.length})",
                  style: GoogleFonts.lexend(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (courtProvider.isLoading && courts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (courts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "Chưa có danh sách sân con cho cơ sở này",
                  style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            )
          else
            SizedBox(
              height: 115,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: courts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final court = courts[index];

                  String status = "Đang trống";
                  String timeText = "Hiện tại";
                  bool isBusy = false;
                  bool isPending = false;
                  bool isMaintenance = !court.isActive;

                  if (isMaintenance) {
                    status = "Bảo trì";
                    timeText = "Tạm ngưng";
                  } else {
                    final courtBookings = todayBookings.where((b) => b.courtId == court.id).toList();

                    OwnerBookingEntity? activeBooking;
                    OwnerBookingEntity? nextUpcomingBooking;

                    for (final b in courtBookings) {
                      final start = _getBookingStartTime(b, now);
                      final end = _getBookingEndTime(b, now);
                      if (start != null && end != null) {
                        if (now.isAfter(start) && now.isBefore(end)) {
                          activeBooking = b;
                          break;
                        } else if (start.isAfter(now)) {
                          if (nextUpcomingBooking == null) {
                            nextUpcomingBooking = b;
                          } else {
                            final prevStart = _getBookingStartTime(nextUpcomingBooking, now);
                            if (prevStart != null && start.isBefore(prevStart)) {
                              nextUpcomingBooking = b;
                            }
                          }
                        }
                      }
                    }

                    if (activeBooking != null) {
                      isBusy = true;
                      status = "Đang chơi";
                      timeText = activeBooking.timeRangeText.isNotEmpty
                          ? activeBooking.timeRangeText
                          : "Đang có trận";
                    } else if (nextUpcomingBooking != null) {
                      isPending = true;
                      status = "Sắp có trận";
                      timeText = nextUpcomingBooking.timeRangeText.isNotEmpty
                          ? nextUpcomingBooking.timeRangeText
                          : "Sắp diễn ra";
                    } else {
                      status = "Đang trống";
                      timeText = "Sẵn sàng nhận khách";
                    }
                  }

                  Color badgeBg = Colors.grey.shade100;
                  Color badgeText = Colors.grey.shade700;
                  Color borderColor = Colors.grey.shade200;

                  if (isBusy) {
                    badgeBg = Colors.green.shade50;
                    badgeText = Colors.green.shade700;
                    borderColor = Colors.green.shade200;
                  } else if (isPending) {
                    badgeBg = Colors.orange.shade50;
                    badgeText = Colors.orange.shade800;
                    borderColor = Colors.orange.shade200;
                  } else if (isMaintenance) {
                    badgeBg = Colors.red.shade50;
                    badgeText = Colors.red.shade700;
                    borderColor = Colors.red.shade200;
                  }

                  return Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                court.name,
                                style: GoogleFonts.lexend(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.onBackground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (court.sportType != null && court.sportType!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLightBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  court.sportType!,
                                  style: GoogleFonts.lexend(
                                    fontSize: 9,
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.lexend(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: badgeText,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              isBusy
                                  ? Icons.sports_tennis_rounded
                                  : (isPending
                                      ? Icons.access_time_rounded
                                      : (isMaintenance ? Icons.build_rounded : Icons.check_circle_outline_rounded)),
                              size: 13,
                              color: isBusy
                                  ? Colors.green.shade700
                                  : (isPending
                                      ? Colors.orange.shade700
                                      : (isMaintenance ? Colors.red.shade700 : Colors.grey.shade500)),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                timeText,
                                style: GoogleFonts.lexend(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- ĐƠN ĐẶT SÂN GẦN ĐÂY ---
  Widget _buildRecentBookingsSection(BuildContext context, OwnerBookingProvider provider) {
    final allBookings = provider.allBookings;
    final recentBookings = allBookings.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Đơn đặt sân mới",
                style: GoogleFonts.lexend(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              TextButton(
                onPressed: () => _showTodayBookingsSheet(context, provider),
                child: Text(
                  "Xem tất cả",
                  style: GoogleFonts.lexend(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (provider.isLoading && allBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (recentBookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.event_note_rounded, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    "Chưa có đơn đặt sân mới nào",
                    style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentBookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final booking = recentBookings[index];
                return _buildBookingCardItem(context, booking, provider);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCardItem(
    BuildContext context,
    OwnerBookingEntity booking,
    OwnerBookingProvider provider,
  ) {
    final statusColor = _getStatusColor(booking);
    final statusLabel = _getStatusLabel(booking);
    final initial = booking.customerName.trim().isNotEmpty
        ? booking.customerName.trim()[0].toUpperCase()
        : 'K';

    return InkWell(
      onTap: () => BookingDetailSheet.show(context, booking, provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLightBg,
              backgroundImage: (booking.customerAvatarUrl != null && booking.customerAvatarUrl!.isNotEmpty)
                  ? NetworkImage(booking.customerAvatarUrl!)
                  : null,
              child: (booking.customerAvatarUrl == null || booking.customerAvatarUrl!.isEmpty)
                  ? Text(
                      initial,
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.customerName.isNotEmpty ? booking.customerName : 'Khách vãng lai',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${booking.courtName.isNotEmpty ? booking.courtName : 'Sân thi đấu'} • ${booking.timeRangeText} (${_formatDateTag(booking.bookingDate)})",
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(booking.totalPrice),
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- MODAL HIỂN THỊ DANH SÁCH ĐƠN TRONG NGÀY (XEM TẤT CẢ) ---
  void _showTodayBookingsSheet(BuildContext context, OwnerBookingProvider provider) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayBookings = provider.allBookings.where((b) => b.bookingDate == todayStr).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Sheet
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2E7D32), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Đặt sân hôm nay (${now.day}/${now.month}/${now.year})",
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onBackground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Có ${todayBookings.length} lượt đặt sân trong ngày",
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Danh sách đơn trong ngày
              Flexible(
                child: todayBookings.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy_rounded, size: 54, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                "Hôm nay chưa có lượt đặt sân nào",
                                style: GoogleFonts.lexend(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Khách đặt sân mới sẽ xuất hiện tại đây theo thời gian thực.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: todayBookings.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 10),
                        itemBuilder: (c, i) {
                          final booking = todayBookings[i];
                          return _buildBookingCardItem(context, booking, provider);
                        },
                      ),
              ),

              // Footer: Nút chuyển tới tab Quản lý đặt sân
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.go('/owner/bookings');
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        "Đi đến Quản lý đặt sân",
                        style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPERS ---
  Color _getStatusColor(OwnerBookingEntity booking) {
    if (booking.isCancelled) return Colors.red;
    if (booking.isCompleted) return Colors.blueGrey;
    if (booking.isPaid) return const Color(0xFF0288D1);
    if (booking.isDepositPaid) return const Color(0xFF2E7D32);
    if (booking.isConfirmed) return const Color(0xFF2E7D32);
    return Colors.orange.shade800;
  }

  String _getStatusLabel(OwnerBookingEntity booking) {
    if (booking.isCancelled) return "Đã hủy";
    if (booking.isCompleted) return "Hoàn thành";
    if (booking.isPaid) return "Đã thanh toán";
    if (booking.isDepositPaid) return "Đã cọc";
    if (booking.isConfirmed) return "Đã xác nhận";
    return "Chờ duyệt";
  }

  String _formatDateTag(String dateStr) {
    if (dateStr.isEmpty) return '';
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    if (dateStr == todayStr) return "Hôm nay";
    if (dateStr == tomorrowStr) return "Ngày mai";

    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}";
      }
    } catch (_) {}
    return dateStr;
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
}

class OwnerNotificationIcon extends StatefulWidget {
  const OwnerNotificationIcon({super.key});

  @override
  State<OwnerNotificationIcon> createState() => _OwnerNotificationIconState();
}

class _OwnerNotificationIconState extends State<OwnerNotificationIcon> {
  int _unreadCount = 0;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_subscription != null) {
      Supabase.instance.client.removeChannel(_subscription!);
    }
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final notifsResp = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _unreadCount = (notifsResp as List).length;
        });
      }
    } catch (_) {}
  }

  void _subscribeRealtime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _subscription = Supabase.instance.client
        .channel('public:owner_bell_unread_count_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            _fetchUnreadCount();
          },
        )
        .subscribe();
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const OwnerNotificationsBottomSheet(),
    ).then((_) {
      _fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _openNotifications,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}


