import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/customer/home/presentation/widgets/header_widget.dart';
import 'package:flexisport_app/features/customer/booking/presentation/providers/booking_provider.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSport = 'Tất cả';
  String _selectedLevel = 'Tất cả';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _sportsFilter = [
    {'name': 'Tất cả', 'icon': Icons.grid_view_rounded},
    {'name': 'Pickleball', 'icon': Icons.sports_tennis_rounded},
    {'name': 'Cầu lông', 'icon': Icons.sports_tennis_outlined},
    {'name': 'Bóng đá', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Tennis', 'icon': Icons.sports_baseball_rounded},
    {'name': 'Bóng rổ', 'icon': Icons.sports_basketball_rounded},
    {'name': 'Bóng bàn', 'icon': Icons.sports_baseball_outlined},
    {'name': 'Bơi lội', 'icon': Icons.pool_rounded},
    {'name': 'Khác', 'icon': Icons.sports_outlined},
  ];

  final List<String> _levelsList = [
    'Tất cả',
    'Mọi trình độ',
    'Người mới (Cơ bản)',
    'Trung bình (Phong trào)',
    'Nâng cao / Bán chuyên',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BookingProvider>().loadEvents('');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatVND(double amount) {
    if (amount <= 0) return "Miễn phí";
    final String str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return "${buffer.toString()} đ";
  }

  String _formatDate(String dateStr) {
    try {
      final clean = dateStr.split('T')[0].split(' ')[0].trim();
      final parts = clean.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return dateStr;
  }

  String _cleanTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }
    return timeStr;
  }

  bool _isEventExpired(EventEntity event) {
    if (!event.isActive) return true;
    if (event.eventDate.isEmpty) return false;

    try {
      final cleanDate = event.eventDate.split('T')[0].split(' ')[0].trim();
      final dateParts = cleanDate.split('-');
      if (dateParts.length != 3) return false;

      final year = int.tryParse(dateParts[0]) ?? 0;
      final month = int.tryParse(dateParts[1]) ?? 0;
      final day = int.tryParse(dateParts[2]) ?? 0;

      int endHour = 23;
      int endMinute = 59;

      if (event.endTime.isNotEmpty) {
        final timeParts = event.endTime.trim().split(':');
        if (timeParts.isNotEmpty) {
          endHour = int.tryParse(timeParts[0]) ?? endHour;
        }
        if (timeParts.length >= 2) {
          endMinute = int.tryParse(timeParts[1]) ?? endMinute;
        }
      }

      final endDateTime = DateTime(year, month, day, endHour, endMinute);
      return DateTime.now().isAfter(endDateTime);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final allEvents = bookingProvider.events;

    // Lọc sự kiện theo môn thể thao, trình độ, tìm kiếm và bỏ qua sự kiện hết hạn
    final filteredEvents = allEvents.where((event) {
      // 0. Bỏ qua các sự kiện đã kết thúc/hết hạn
      if (_isEventExpired(event)) return false;

      // 1. Lọc theo từ khóa tìm kiếm
      final matchesSearch = _searchQuery.isEmpty ||
          event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.courtName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.sportType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.level.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Lọc theo môn thể thao
      final matchesSport = _selectedSport == 'Tất cả' ||
          event.sportType.toLowerCase() == _selectedSport.toLowerCase();

      // 3. Lọc theo trình độ
      final matchesLevel = _selectedLevel == 'Tất cả' ||
          event.level.toLowerCase() == _selectedLevel.toLowerCase() ||
          event.level == 'Mọi trình độ';

      return matchesSearch && matchesSport && matchesLevel;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
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
        ),
        title: Text(
          "Sự Kiện & Giải Đấu",
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 6),
            child: NotificationIconWidget(opacity: 1.0),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header xanh lá chứa ô tìm kiếm và bộ lọc môn thể thao dạng chip
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
              top: 8,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryContainer,
                  AppColors.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ô tìm kiếm hiện đại
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    style: GoogleFonts.lexend(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Tìm giải đấu, sự kiện, sân đấu...",
                      hintStyle: GoogleFonts.lexend(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryContainer),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Thanh trượt bộ lọc môn thể thao
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sportsFilter.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _sportsFilter[index];
                      final isSelected = _selectedSport == item['name'];
                      return _buildSportChip(
                        name: item['name'] as String,
                        icon: item['icon'] as IconData,
                        isSelected: isSelected,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Thanh phụ: Đếm số lượng & Bộ lọc trình độ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Danh sách sự kiện",
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C19),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${filteredEvents.length}",
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),

                // Dropdown chọn trình độ nhanh
                PopupMenuButton<String>(
                  initialValue: _selectedLevel,
                  onSelected: (val) {
                    setState(() {
                      _selectedLevel = val;
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 14,
                          color: _selectedLevel == 'Tất cả' ? Colors.grey.shade600 : AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedLevel == 'Tất cả' ? "Trình độ" : _selectedLevel,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedLevel == 'Tất cả' ? Colors.grey.shade700 : AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => _levelsList.map((level) {
                    return PopupMenuItem<String>(
                      value: level,
                      child: Row(
                        children: [
                          if (_selectedLevel == level)
                            const Icon(Icons.check_rounded, color: AppColors.primaryContainer, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(
                            level,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: _selectedLevel == level ? FontWeight.bold : FontWeight.normal,
                              color: _selectedLevel == level ? AppColors.primaryContainer : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Danh sách sự kiện
          Expanded(
            child: bookingProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryContainer),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await bookingProvider.loadEvents('');
                    },
                    color: AppColors.primaryContainer,
                    child: filteredEvents.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = filteredEvents[index];
                              final bookedCount =
                                  bookingProvider.eventBookedTicketsCount[event.id] ?? 0;
                              return _buildModernEventCard(event, bookedCount);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget Chip bộ lọc môn thể thao
  Widget _buildSportChip({
    required String name,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSport = name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.white, width: 1.2)
              : Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primaryContainer : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: GoogleFonts.lexend(
                color: isSelected ? AppColors.primaryContainer : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thẻ sự kiện thiết kế hiện đại
  Widget _buildModernEventCard(EventEntity event, int bookedCount) {
    final maxAvailable = (event.maxTickets - bookedCount).clamp(0, event.maxTickets);
    final isFull = maxAvailable <= 0;
    final progress = event.maxTickets > 0 ? (bookedCount / event.maxTickets).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            context.read<MainPageProvider>().hideNavbar();
            context.push(
              '/EventBookingDetailPage',
              extra: {
                'event': event,
                'bookedCount': bookedCount,
                'showNavbarOnPop': true,
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner ảnh hoặc Header màu sắc theo môn
              Stack(
                children: [
                  if (event.bannerUrl != null && event.bannerUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        event.bannerUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildSportDefaultBanner(event.sportType),
                      ),
                    )
                  else
                    _buildSportDefaultBanner(event.sportType),

                  // Lớp Gradient phủ bóng
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tag môn thể thao & Trình độ
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006D38),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                event.sportType,
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.level,
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trạng thái vé (Đang mở / Hết vé)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFull ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isFull ? "HẾT VÉ" : "ĐANG MỞ",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Tiêu đề sự kiện nổi trên banner
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      event.title,
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Nội dung chi tiết sự kiện
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sân thi đấu
                    Row(
                      children: [
                        const Icon(Icons.stadium_outlined, size: 15, color: Color(0xFF006D38)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.courtName,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1C19),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Ngày & Giờ
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(event.eventDate),
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 5),
                        Text(
                          "${_cleanTime(event.startTime)} - ${_cleanTime(event.endTime)}",
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Thanh tiến độ vé đã bán
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isFull
                                  ? "Đã kín chỗ"
                                  : "Còn lại $maxAvailable / ${event.maxTickets} vé (Tối thiểu ${event.minTickets} vé)",
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isFull ? const Color(0xFFD32F2F) : const Color(0xFF006D38),
                              ),
                            ),
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFull ? const Color(0xFFD32F2F) : const Color(0xFF006D38),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 20, thickness: 0.8),

                    // Giá vé & Nút Chi tiết
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Giá vé tham gia",
                              style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey.shade500),
                            ),
                            Text(
                              _formatVND(event.ticketPrice),
                              style: GoogleFonts.lexend(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: event.ticketPrice == 0 ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006D38),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Chi tiết",
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
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

  // Banner mặc định với màu gradient & icon môn thể thao khi không có bannerUrl
  Widget _buildSportDefaultBanner(String sportType) {
    Color startColor = const Color(0xFF1B5E20);
    Color endColor = const Color(0xFF004D40);

    final sportLower = sportType.toLowerCase();
    if (sportLower.contains('pickleball')) {
      startColor = const Color(0xFF0277BD);
      endColor = const Color(0xFF004D40);
    } else if (sportLower.contains('cầu lông')) {
      startColor = const Color(0xFFE65100);
      endColor = const Color(0xFFBF360C);
    } else if (sportLower.contains('bóng đá')) {
      startColor = const Color(0xFF2E7D32);
      endColor = const Color(0xFF1B5E20);
    } else if (sportLower.contains('tennis')) {
      startColor = const Color(0xFF6A1B9A);
      endColor = const Color(0xFF4A148C);
    } else if (sportLower.contains('bóng rổ')) {
      startColor = const Color(0xFFEF6C00);
      endColor = const Color(0xFFD84315);
    }

    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  // Trạng thái trống khi không tìm thấy sự kiện nào
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF006D38).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: Color(0xFF006D38),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Không tìm thấy sự kiện nào!",
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B1C19),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Hiện tại chưa có sự kiện hoặc giải đấu nào phù hợp với bộ lọc đã chọn.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSport = 'Tất cả';
                  _selectedLevel = 'Tất cả';
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                "Đặt lại bộ lọc",
                style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D38),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
