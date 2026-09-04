import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/providers/owner_booking_provider.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/widgets/booking_detail_sheet.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/widgets/booking_timeline_widget.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/widgets/owner_booking_card_widget.dart';
import 'package:flexisport_app/features/owner/dashboard/presentation/widgets/owner_notifications_bottom_sheet.dart';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});

  @override
  State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  final _searchController = TextEditingController();
  String _viewMode = 'list'; // 'list' (Danh sách đơn) hoặc 'timeline' (Lịch trực quan)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OwnerBookingProvider>();
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _pickDate(BuildContext context, OwnerBookingProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now.add(const Duration(days: 90)),
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

    if (picked != null) {
      provider.setDateFilter(picked);
    }
  }

  void _showVenueSelector(BuildContext context, OwnerBookingProvider provider) {
    if (provider.venues.length <= 1) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chọn cơ sở quản lý",
              style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...provider.venues.map((venue) {
              final isSelected = venue.id == provider.selectedVenue?.id;
              return ListTile(
                leading: Icon(
                  Icons.stadium_rounded,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
                title: Text(
                  venue.name,
                  style: GoogleFonts.lexend(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.onBackground,
                  ),
                ),
                subtitle: Text(
                  venue.address,
                  style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  provider.selectVenue(venue);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerBookingProvider>();
    final bookings = provider.filteredBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, provider),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshBookings(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Switcher Chế độ xem (Danh sách đơn | Lịch trực quan Timeline)
              _buildViewModeSwitcher(),

              if (_viewMode == 'timeline')
                const BookingTimelineWidget()
              else ...[
                // 1. Thẻ thống kê doanh thu & đơn đặt hôm nay
                _buildStatsSection(provider),

                // 2. Thanh tìm kiếm
                _buildSearchBar(provider),

                // 3. Thanh dải lọc ngày & Trạng thái
                _buildFilterChips(context, provider),
                const SizedBox(height: 12),

                // 4. Danh sách đơn đặt sân
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (bookings.isEmpty)
                  _buildEmptyState(provider)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bookings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return OwnerBookingCardWidget(
                        booking: booking,
                        onTap: () => BookingDetailSheet.show(context, booking, provider),
                        onConfirm: () => _confirmAction(context, provider, booking),
                        onMarkPaid: () => _markPaidAction(context, provider, booking),
                        onComplete: () => _completeAction(context, provider, booking),
                        onCancel: () => _cancelAction(context, provider, booking),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, OwnerBookingProvider provider) {
    final venueName = provider.selectedVenue?.name ?? 'Quản lý đặt sân';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: InkWell(
        onTap: () => _showVenueSelector(context, provider),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  venueName,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (provider.venues.length > 1) ...[
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (ctx) => const OwnerNotificationsBottomSheet(),
            );
          },
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.onBackground),
          tooltip: "Thông báo",
        ),
        IconButton(
          onPressed: provider.isLoading
              ? null
              : () async {
                  await provider.refreshBookings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Đã tải lại dữ liệu mới nhất",
                              style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF016B34),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
          icon: provider.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.refresh_rounded, color: AppColors.onBackground),
          tooltip: "Tải lại",
        ),
      ],
    );
  }

  Widget _buildViewModeSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = 'list'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _viewMode == 'list' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _viewMode == 'list'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 16,
                      color: _viewMode == 'list' ? AppColors.primary : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Danh sách đơn",
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: _viewMode == 'list' ? FontWeight.bold : FontWeight.normal,
                        color: _viewMode == 'list' ? AppColors.primary : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = 'timeline'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _viewMode == 'timeline' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _viewMode == 'timeline'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_view_week_rounded,
                      size: 16,
                      color: _viewMode == 'timeline' ? const Color(0xFF016B34) : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Lịch trực quan",
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: _viewMode == 'timeline' ? FontWeight.bold : FontWeight.normal,
                        color: _viewMode == 'timeline' ? const Color(0xFF016B34) : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(OwnerBookingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: "Doanh thu hôm nay",
                  value: _formatCurrency(provider.todayTotalRevenue),
                  subtitle: "Cọc: ${_formatCurrency(provider.todayDepositRevenue)}",
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: "Đơn hôm nay",
                  value: "${provider.todayBookingsCount} đơn",
                  subtitle: "${provider.todayPendingCount} chờ duyệt",
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lexend(fontSize: 9, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(OwnerBookingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: provider.setSearchQuery,
          style: GoogleFonts.lexend(fontSize: 13),
          decoration: InputDecoration(
            hintText: "Tìm theo tên khách, SĐT hoặc mã đơn...",
            hintStyle: GoogleFonts.lexend(fontSize: 12.5, color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
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
    );
  }

  Widget _buildFilterChips(BuildContext context, OwnerBookingProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final isAllDate = provider.selectedDate == null;
    final isToday = provider.selectedDate != null &&
        provider.selectedDate!.year == today.year &&
        provider.selectedDate!.month == today.month &&
        provider.selectedDate!.day == today.day;
    final isTomorrow = provider.selectedDate != null &&
        provider.selectedDate!.year == tomorrow.year &&
        provider.selectedDate!.month == tomorrow.month &&
        provider.selectedDate!.day == tomorrow.day;
    final isCustomDate = provider.selectedDate != null && !isToday && !isTomorrow;

    final allCount = provider.allBookings.length;
    final pendingCount = provider.allBookings.where((b) => b.isPending).length;
    final confirmedCount = provider.allBookings.where((b) => b.isConfirmed).length;
    final completedCount = provider.allBookings.where((b) => b.isCompleted).length;
    final cancelledCount = provider.allBookings.where((b) => b.isCancelled).length;

    const activePillColor = Color(0xFF386618);

    return Column(
      children: [
        // 1. THANH DẢI LỌC NGÀY (Pill Segment Container)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F3),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                // Tất cả
                Expanded(
                  child: GestureDetector(
                    onTap: () => provider.setDateFilter(null),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAllDate ? activePillColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Tất cả",
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: isAllDate ? FontWeight.bold : FontWeight.w500,
                          color: isAllDate ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                // Hôm nay
                Expanded(
                  child: GestureDetector(
                    onTap: () => provider.setDateFilter(today),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday ? activePillColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Hôm nay",
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                // Ngày mai
                Expanded(
                  child: GestureDetector(
                    onTap: () => provider.setDateFilter(tomorrow),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isTomorrow ? activePillColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Ngày mai",
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: isTomorrow ? FontWeight.bold : FontWeight.w500,
                          color: isTomorrow ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                // Chọn ngày
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(context, provider),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCustomDate ? activePillColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 15,
                            color: isCustomDate ? Colors.white : activePillColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCustomDate
                                ? "${provider.selectedDate!.day}/${provider.selectedDate!.month}"
                                : "Chọn ngày",
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: isCustomDate ? FontWeight.bold : FontWeight.w500,
                              color: isCustomDate ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. HÀNG LỌC TRẠNG THÁI (Trạng thái --- Dropdown Button)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Trạng thái",
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              // Dropdown Trạng thái bo tròn
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: provider.selectedStatus,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.black87),
                    style: GoogleFonts.lexend(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text("Trạng thái: Tất cả ($allCount)"),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text("Chờ duyệt ($pendingCount)"),
                      ),
                      DropdownMenuItem(
                        value: 'confirmed',
                        child: Text("Đã xác nhận ($confirmedCount)"),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text("Hoàn thành ($completedCount)"),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text("Đã hủy ($cancelledCount)"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        provider.setStatusFilter(val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(OwnerBookingProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              "Không tìm thấy đơn đặt sân nào",
              style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground),
            ),
            const SizedBox(height: 6),
            Text(
              "Thử đổi bộ lọc ngày, trạng thái hoặc từ khóa tìm kiếm.",
              style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => provider.clearFilters(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Xóa bộ lọc", style: GoogleFonts.lexend(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS ---

  void _confirmAction(BuildContext context, OwnerBookingProvider provider, OwnerBookingEntity booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.confirmBooking(booking.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? "Đã duyệt đơn của khách ${booking.customerName}" : "Duyệt đơn thất bại", style: GoogleFonts.lexend()),
        backgroundColor: success ? AppColors.primary : Colors.red,
      ),
    );
  }

  void _markPaidAction(BuildContext context, OwnerBookingProvider provider, OwnerBookingEntity booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.markAsPaid(booking.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? "Đã cập nhật: Đã thu đủ tiền 100%" : "Cập nhật thất bại", style: GoogleFonts.lexend()),
        backgroundColor: success ? const Color(0xFF059669) : Colors.red,
      ),
    );
  }

  void _completeAction(BuildContext context, OwnerBookingProvider provider, OwnerBookingEntity booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.completeBooking(booking.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? "Đã check-in hoàn thành đơn" : "Cập nhật thất bại", style: GoogleFonts.lexend()),
        backgroundColor: success ? const Color(0xFF3B82F6) : Colors.red,
      ),
    );
  }

  void _cancelAction(BuildContext context, OwnerBookingProvider provider, OwnerBookingEntity booking) {
    BookingDetailSheet.show(context, booking, provider);
  }
}
