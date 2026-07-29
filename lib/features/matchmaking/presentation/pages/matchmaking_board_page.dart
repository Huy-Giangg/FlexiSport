import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/matchmaking/presentation/providers/matchmaking_provider.dart';
import 'package:flexisport_app/features/matchmaking/presentation/widgets/matchmaking_card.dart';

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
        
        appBar: AppBar(
          title: const Text(
            'Ghép kèo & Tìm đồng đội',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF006D38),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Colors.white,),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Kèo quanh đây'),
              Tab(text: 'Kèo của tôi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Kèo quanh đây (Có bộ lọc môn thể thao)
            Column(
              children: [
                // Sports selection chips
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only( left: 16, right: 16, top: 16),
                    itemCount: _sports.length,
                    itemBuilder: (context, index) {
                      final sport = _sports[index];
                      final isSelected = _selectedSport == sport;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(sport),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSport = sport;
                            });
                          },
                          
                          selectedColor: Colors.green.shade100,
                          checkmarkColor: Colors.green.shade700,
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
