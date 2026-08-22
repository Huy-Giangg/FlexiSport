import 'dart:async';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/customer/home/presentation/widgets/notifications_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final User? currentUser;
  final TextEditingController searchController;
  final String searchQuery;
  final bool showFavoritesOnly;
  final VoidCallback onFavoriteFilterToggled;

  HomeHeaderDelegate({
    required this.topPadding,
    this.currentUser,
    required this.searchController,
    required this.searchQuery,
    required this.showFavoritesOnly,
    required this.onFavoriteFilterToggled,
  });

  String getFormattedDate() {
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
  double get minExtent => topPadding + 65;

  @override
  double get maxExtent => topPadding + 125;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double percent = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // 1. Hình nền lá xanh đặc trưng
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        Positioned(
          top: topPadding + 10,
          left: 16,
          child: Opacity(
            opacity: percent.clamp(0.0, 1.0),
            child: Text(
              getFormattedDate(),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),

        Positioned(
          top: topPadding + 8,
          right: 48,
          child: Opacity(
            opacity: (1.0 - percent * 1.5).clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.yellow, size: 16),
            ),
          ),
        ),

        Positioned(
          top: topPadding - 2,
          right: 4,
          child: NotificationIconWidget(
            opacity: (1.0 - percent * 1.5).clamp(0.0, 1.0),
          ),
        ),

        // 3. Logo lớn + Các nút Đăng nhập / Đăng ký (Mờ dần và biến mất khi cuộn xuống)
        currentUser == null
            ? Positioned(
                top: topPadding + 10,
                left: 16,
                child: Opacity(
                  opacity: (1.0 - percent * 1.5).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 90,
                        width: 90,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            getFormattedDate(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryContainer,
                                  minimumSize: const Size(120, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: percent > 0.5
                                    ? null
                                    : () {
                                        context
                                            .read<MainPageProvider>()
                                            .hideNavbar();
                                        context.push('/login').then((_) {
                                          context
                                              .read<MainPageProvider>()
                                              .showNavbar();
                                        });
                                      },
                                child: const Text(
                                  "Đăng nhập",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(120, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  side: const BorderSide(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: percent > 0.5
                                    ? null
                                    : () {
                                        context
                                            .read<MainPageProvider>()
                                            .hideNavbar();
                                        context.push('/register').then((_) {
                                          context
                                              .read<MainPageProvider>()
                                              .showNavbar();
                                        });
                                      },
                                child: const Text(
                                  "Đăng ký",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : Positioned(
                top: topPadding + 20,
                left: 16,
                child: Opacity(
                  opacity: (1.0 - percent * 1.5).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar hình tròn màu tím chứa chữ cái đầu tiên của tên
                      Builder(
                        builder: (context) {
                          final displayName =
                              currentUser!.userMetadata?['full_name']
                                  as String? ??
                              currentUser!.userMetadata?['name'] as String? ??
                              currentUser!.email ??
                              'U';
                          final initial = displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U';
                          return Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            getFormattedDate(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              final displayName =
                                  currentUser!.userMetadata?['full_name']
                                      as String? ??
                                  currentUser!.userMetadata?['name']
                                      as String? ??
                                  currentUser!.email ??
                                  '';
                              return Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

        // 4. Thanh Tìm kiếm + Nút Yêu thích (Trượt lên trên và co giãn)
        Positioned(
          top: topPadding + 100 - (percent * 60),
          left: 16,
          right: 16,
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      context.read<SportsComplexProvider>().setSearchQuery(
                        value,
                      );
                    },
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'assets/images/ic_alobo-removebg.png',
                          height: 24,
                          width: 24,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      hintText: "Tìm kiếm",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                searchController.clear();
                                context
                                    .read<SportsComplexProvider>()
                                    .setSearchQuery('');
                              },
                            )
                          else
                            Icon(
                              Icons.search,
                              color: AppColors.primaryContainer,
                              size: 22,
                            ),

                          // Chỉ hiển thị biểu tượng bộ lọc (Filter Icon) trong ô tìm kiếm khi co nhỏ
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onFavoriteFilterToggled,
                  icon: Icon(
                    showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                    color: showFavoritesOnly
                        ? Colors.red
                        : AppColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant HomeHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding ||
        oldDelegate.currentUser != currentUser ||
        oldDelegate.searchController != searchController ||
        oldDelegate.searchQuery != searchQuery ||
        oldDelegate.showFavoritesOnly != showFavoritesOnly;
  }
}

class NotificationIconWidget extends StatefulWidget {
  final double opacity;
  const NotificationIconWidget({super.key, required this.opacity});

  @override
  State<NotificationIconWidget> createState() => _NotificationIconWidgetState();
}

class _NotificationIconWidgetState extends State<NotificationIconWidget> {
  int _pendingCount = 0;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchPendingCount();
    _subscribeToRequests();
  }

  @override
  void dispose() {
    if (_subscription != null) {
      Supabase.instance.client.removeChannel(_subscription!);
    }
    super.dispose();
  }

  Future<void> _fetchPendingCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Lấy danh sách ID các kèo do user làm host
      final myPosts = await Supabase.instance.client
          .from('matchmaking_posts')
          .select('id')
          .eq('host_id', user.id);
      
      final postIds = (myPosts as List).map((p) => p['id'] as String).toList();
      if (postIds.isEmpty) {
        if (mounted) setState(() => _pendingCount = 0);
        return;
      }

      // 2. Đếm số yêu cầu ghép kèo đang ở trạng thái 'pending'
      final countResponse = await Supabase.instance.client
          .from('matchmaking_requests')
          .select('id, created_at')
          .inFilter('post_id', postIds)
          .eq('status', 'pending');
      
      final requests = countResponse as List? ?? [];
      
      // Lấy thời điểm xem thông báo cuối cùng từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastSeenStr = prefs.getString('last_seen_notification_time');
      
      int count = 0;
      if (lastSeenStr == null) {
        // Nếu chưa xem lần nào, đếm toàn bộ các yêu cầu đang pending
        count = requests.length;
      } else {
        final lastSeen = DateTime.parse(lastSeenStr);
        for (var req in requests) {
          final createdAtStr = req['created_at'] as String?;
          if (createdAtStr != null) {
            final createdAt = DateTime.parse(createdAtStr);
            if (createdAt.isAfter(lastSeen)) {
              count++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingCount = count;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải số lượng thông báo: $e');
    }
  }

  void _subscribeToRequests() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _subscription = Supabase.instance.client
        .channel('public:matchmaking_requests_count')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_requests',
          callback: (payload) {
            _fetchPendingCount();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.opacity == 0.0) return const SizedBox.shrink();

    return Opacity(
      opacity: widget.opacity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _showNotifications,
          ),
          if (_pendingCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotifications() async {
    // Lưu thời điểm mở thông báo để ẩn badge thông báo
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_seen_notification_time',
        DateTime.now().toUtc().toIso8601String(),
      );
      if (mounted) {
        setState(() {
          _pendingCount = 0;
        });
      }
    } catch (e) {
      debugPrint('Lỗi lưu thời gian xem thông báo: $e');
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const NotificationsBottomSheet(),
    ).then((_) {
      // Refresh count khi đóng sheet (để cập nhật nếu có thông báo mới phát sinh)
      _fetchPendingCount();
    });
  }
}
