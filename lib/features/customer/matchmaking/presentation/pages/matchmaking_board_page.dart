import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/customer/home/presentation/widgets/header_widget.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/providers/matchmaking_provider.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/widgets/matchmaking_card.dart';

class MatchmakingBoardPage extends StatefulWidget {
  const MatchmakingBoardPage({super.key});

  @override
  State<MatchmakingBoardPage> createState() => _MatchmakingBoardPageState();
}

class _MatchmakingBoardPageState extends State<MatchmakingBoardPage> {
  String _selectedSport = 'Tất cả';
  final List<String> _sports = ['Tất cả', 'Pickleball', 'Cầu lông', 'Bóng đá', 'Tennis'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      context.read<MatchmakingProvider>().loadPosts();
      if (currentUserId != null) {
        context.read<MatchmakingProvider>().loadUserRequests(currentUserId);
      }
    });
  }

  bool _isPostExpired(MatchmakingPost post) {
    if (post.bookingDate == null || post.bookingDate!.isEmpty) return false;
    if (post.bookingTime == null || post.bookingTime!.isEmpty) return false;

    try {
      final dateParts = post.bookingDate!.split('-');
      if (dateParts.length != 3) return false;
      final year = int.tryParse(dateParts[0]) ?? 0;
      final month = int.tryParse(dateParts[1]) ?? 0;
      final day = int.tryParse(dateParts[2]) ?? 0;

      final cleanTime = post.bookingTime!.replaceAll(' ', '');
      final timeParts = cleanTime.split('-');
      if (timeParts.length != 2) return false;
      final endTimeStr = timeParts[1];

      final endTimeParts = endTimeStr.split(':');
      if (endTimeParts.length != 2) return false;
      final hour = int.tryParse(endTimeParts[0]) ?? 0;
      final minute = int.tryParse(endTimeParts[1]) ?? 0;

      final endDateTime = DateTime(year, month, day, hour, minute);
      return DateTime.now().isAfter(endDateTime);
    } catch (_) {
      return false;
    }
  }

  Widget _buildPostList(BuildContext context, String? currentUserId, {required bool isMine}) {
    return Consumer<MatchmakingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Text('Lỗi: ${provider.errorMessage}'),
          );
        }

        // Lọc các kèo tương ứng
        final filteredPosts = provider.posts.where((post) {
          // Chỉ hiển thị các kèo còn hạn (chưa diễn ra hoặc chưa kết thúc)
          if (_isPostExpired(post)) return false;

          if (isMine) {
            final isHost = post.hostId == currentUserId;
            final hasApplied = provider.userRequests.any(
              (r) => r.postId == post.id && r.status != 'cancelled',
            );
            return isHost || hasApplied;
          } else {
            final matchesHost = post.hostId != currentUserId;
            final hasApplied = provider.userRequests.any(
              (r) => r.postId == post.id && r.status != 'cancelled',
            );
            final matchesSport = _selectedSport == 'Tất cả' ||
                post.sportType?.toLowerCase() == _selectedSport.toLowerCase();
            return matchesHost && !hasApplied && matchesSport;
          }
        }).toList();

        if (filteredPosts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                isMine
                    ? 'Bạn chưa có hoạt động ghép kèo nào.'
                    : 'Chưa có kèo nào được tạo từ người khác.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            return MatchmakingCard(post: post);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
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
            'Ghép kèo & Tìm đồng đội',
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              height: 44,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.primaryContainer,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.9),
                labelStyle: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Kèo quanh đây'),
                  Tab(text: 'Kèo của tôi'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Kèo quanh đây (Có bộ lọc môn thể thao)
            Column(
              children: [
                // Sports selection chips
                SizedBox(
                  height: 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _sports.length,
                    itemBuilder: (context, index) {
                      final sport = _sports[index];
                      final isSelected = _selectedSport == sport;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            sport,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primaryContainer : AppColors.onBackground,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSport = sport;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primaryLightBg,
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryContainer : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: _buildPostList(context, currentUserId, isMine: false),
                ),
              ],
            ),

            // Tab 2: Kèo của tôi (Không có bộ lọc môn thể thao)
            _buildPostList(context, currentUserId, isMine: true),
          ],
        ),
      ),
    );
  }
}
