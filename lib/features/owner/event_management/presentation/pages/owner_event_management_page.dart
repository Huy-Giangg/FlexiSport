import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/providers/owner_booking_provider.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/dashboard/presentation/pages/owner_dashboard_page.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/providers/owner_event_provider.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/widgets/add_edit_event_sheet.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/widgets/owner_event_card_widget.dart';

class OwnerEventManagementPage extends StatefulWidget {
  const OwnerEventManagementPage({super.key});

  @override
  State<OwnerEventManagementPage> createState() => _OwnerEventManagementPageState();
}

class _OwnerEventManagementPageState extends State<OwnerEventManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final bookingProvider = context.read<OwnerBookingProvider>();
    final courtProvider = context.read<OwnerCourtProvider>();
    final eventProvider = context.read<OwnerEventProvider>();

    if (bookingProvider.venues.isEmpty) {
      await bookingProvider.initialize();
    }
    if (courtProvider.venues.isEmpty) {
      await courtProvider.loadData();
    }

    final venue = bookingProvider.selectedVenue ??
        courtProvider.selectedVenue ??
        (bookingProvider.venues.isNotEmpty ? bookingProvider.venues.first : null) ??
        (courtProvider.venues.isNotEmpty ? courtProvider.venues.first : null);

    if (venue != null) {
      eventProvider.setVenue(venue);
    }
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

  void _showVenueSelector(
    BuildContext context,
    OwnerBookingProvider bookingProvider,
    OwnerCourtProvider courtProvider,
    OwnerEventProvider eventProvider,
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
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final venue = venues[index];
                  final isSelected = venue.id == eventProvider.selectedVenue?.id;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLightBg : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.5)
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
                        eventProvider.setVenue(venue);
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

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<OwnerBookingProvider>();
    final courtProvider = context.watch<OwnerCourtProvider>();
    final eventProvider = context.watch<OwnerEventProvider>();

    final venue = eventProvider.selectedVenue ??
        bookingProvider.selectedVenue ??
        courtProvider.selectedVenue;
    final venueId = venue?.id ?? '';
    final venueName = venue?.name ?? "Cơ sở thể thao";
    final events = eventProvider.filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, venueName, bookingProvider, courtProvider, eventProvider),
      body: RefreshIndicator(
        onRefresh: () => eventProvider.refreshEvents(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Summary Metrics Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMetricsOverview(eventProvider),
              ),
              const SizedBox(height: 20),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(eventProvider),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              _buildFilterChips(eventProvider),
              const SizedBox(height: 16),

              // Events List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Danh sách sự kiện (${events.length})",
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                    Text(
                      venueName,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Event List Content
              if (eventProvider.isLoading && events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (events.isEmpty)
                _buildEmptyState(context, venueId, courtProvider, eventProvider)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, index) {
                    final event = events[index];
                    return OwnerEventCardWidget(
                      event: event,
                      venueId: venueId,
                      courts: courtProvider.courts,
                      provider: eventProvider,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AddEditEventSheet.show(
            context,
            venueId: venueId,
            courts: courtProvider.courts,
            provider: eventProvider,
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          "Tạo sự kiện mới",
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String venueName,
    OwnerBookingProvider bookingProvider,
    OwnerCourtProvider courtProvider,
    OwnerEventProvider eventProvider,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: InkWell(
        onTap: () => _showVenueSelector(context, bookingProvider, courtProvider, eventProvider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            venueName,
                            style: GoogleFonts.lexend(
                              color: AppColors.onBackground,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                    Text(
                      "Quản lý sự kiện & Giải đấu",
                      style: GoogleFonts.lexend(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: const [
        OwnerNotificationIcon(),
        SizedBox(width: 12),
      ],
    );
  }

  Widget _buildMetricsOverview(OwnerEventProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildMetricCard(
          title: "Sự kiện đang mở",
          value: "${provider.activeEventsCount} sự kiện",
          subText: "Tổng ${provider.totalEventsCount} sự kiện",
          icon: Icons.event_available_rounded,
          iconColor: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
        ),
        _buildMetricCard(
          title: "Vé đã bán",
          value: "${provider.totalSoldTickets} vé",
          subText: "Số lượt đăng ký",
          icon: Icons.confirmation_number_rounded,
          iconColor: const Color(0xFF0288D1),
          bgColor: const Color(0xFFE1F5FE),
        ),
        _buildMetricCard(
          title: "Doanh thu sự kiện",
          value: _formatCurrency(provider.totalRevenue),
          subText: "Tổng thu từ bán vé",
          icon: Icons.payments_rounded,
          iconColor: const Color(0xFFED6C02),
          bgColor: const Color(0xFFFFF4E5),
        ),
        _buildMetricCard(
          title: "Môn thể thao",
          value: "${provider.availableSports.length - 1} bộ môn",
          subText: "Đang tổ chức",
          icon: Icons.sports_tennis_rounded,
          iconColor: const Color(0xFF9C27B0),
          bgColor: const Color(0xFFF3E5F5),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subText,
                style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(OwnerEventProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.setSearchQuery,
      style: GoogleFonts.lexend(fontSize: 13),
      decoration: InputDecoration(
        hintText: "Tìm kiếm sự kiện theo tên, môn, sân...",
        hintStyle: GoogleFonts.lexend(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
                icon: const Icon(Icons.clear, size: 18),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildFilterChips(OwnerEventProvider provider) {
    final statusFilters = [
      {'label': 'Tất cả', 'value': 'all'},
      {'label': 'Đang mở', 'value': 'active'},
      {'label': 'Sắp tới', 'value': 'upcoming'},
      {'label': 'Đã kết thúc', 'value': 'past'},
      {'label': 'Tạm dừng', 'value': 'inactive'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final filter = statusFilters[index];
          final isSelected = provider.statusFilter == filter['value'];

          return InkWell(
            onTap: () => provider.setStatusFilter(filter['value']!),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                filter['label']!,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.onBackground,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String venueId,
    OwnerCourtProvider courtProvider,
    OwnerEventProvider eventProvider,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Icon(Icons.event_note_rounded, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            "Chưa có sự kiện nào",
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tạo các giải đấu giao lưu, sự kiện thể thao để thu hút thêm người chơi và tăng doanh thu!",
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              AddEditEventSheet.show(
                context,
                venueId: venueId,
                courts: courtProvider.courts,
                provider: eventProvider,
              );
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text("Tạo sự kiện đầu tiên", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
