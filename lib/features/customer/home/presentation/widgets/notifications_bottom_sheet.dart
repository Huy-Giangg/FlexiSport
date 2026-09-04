import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class NotificationsBottomSheet extends StatefulWidget {
  const NotificationsBottomSheet({super.key});

  @override
  State<NotificationsBottomSheet> createState() => _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _userId;

  List<Map<String, dynamic>> _upcomingMatches = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // 1. Lấy lịch đặt sân (bookings)
      final bookingsResponse = await supabase
          .from('bookings')
          .select('*, booking_slots(*, courts(*, venues(*)))')
          .eq('user_id', _userId!)
          .inFilter('status', ['completed', 'confirmed']);
      
      final bookingsList = bookingsResponse as List? ?? [];
      final List<Map<String, dynamic>> tempMatches = [];

      for (var booking in bookingsList) {
        final slots = booking['booking_slots'] as List? ?? [];
        if (slots.isEmpty) continue;

        // Gom các slot theo ngày
        final Map<String, List<int>> dateToSlots = {};
        final Map<String, String> dateToVenueName = {};
        final Map<String, String> dateToCourtName = {};
        for (var slot in slots) {
          final dateStr = slot['booking_date'] as String;
          final slotIndex = slot['slot_index'] as int;
          final venueName = slot['courts']?['venues']?['name'] as String? ?? 'Sân thể thao';
          final courtName = slot['courts']?['name'] as String? ?? 'Sân';
          
          dateToSlots.putIfAbsent(dateStr, () => []).add(slotIndex);
          dateToVenueName[dateStr] = venueName;
          dateToCourtName[dateStr] = courtName;
        }

        for (var entry in dateToSlots.entries) {
          final dateStr = entry.key;
          final indices = entry.value..sort();
          final minSlotIndex = indices.first;
          final venueName = dateToVenueName[dateStr] ?? 'Sân thể thao';
          final courtName = dateToCourtName[dateStr] ?? 'Sân';

          final date = DateTime.parse(dateStr);
          final startMinutes = 6 * 60 + minSlotIndex * 30;
          final matchStart = date.add(Duration(minutes: startMinutes));

          if (matchStart.isAfter(now)) {
            final endMinutes = 6 * 60 + (indices.last + 1) * 30;
            final startH = startMinutes ~/ 60;
            final startM = startMinutes % 60;
            final endH = endMinutes ~/ 60;
            final endM = endMinutes % 60;
            final timeRange = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')} - ${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

            tempMatches.add({
              'type': 'court',
              'title': 'Lịch thi đấu sân',
              'subtitle': '$venueName ($courtName)',
              'date': dateStr,
              'time': timeRange,
              'dateTime': matchStart,
            });
          }
        }
      }

      // 2. Lấy vé sự kiện (event_bookings)
      final eventsResponse = await supabase
          .from('event_bookings')
          .select('*, events(*, venues(*))')
          .eq('user_id', _userId!)
          .eq('status', 'completed');
      
      final eventBookingsList = eventsResponse as List? ?? [];
      for (var eb in eventBookingsList) {
        final event = eb['events'];
        if (event == null) continue;

        final eventDateStr = event['event_date'] as String;
        final startTimeStr = event['start_time'] as String;
        final venueName = event['venues']?['name'] as String? ?? 'Sân thể thao';
        final eventTitle = event['title'] as String;

        final matchStart = DateTime.parse('$eventDateStr $startTimeStr');

        if (matchStart.isAfter(now)) {
          tempMatches.add({
            'type': 'event',
            'title': eventTitle,
            'subtitle': venueName,
            'date': eventDateStr,
            'time': startTimeStr,
            'dateTime': matchStart,
          });
        }
      }

      // 2.5 Lấy kèo ghép đã được duyệt (matchmaking_requests status = approved)
      final approvedRequestsResponse = await supabase
          .from('matchmaking_requests')
          .select('*, matchmaking_posts(*, host:profiles!host_id(name), bookings(booking_slots(courts(venues(name)))))')
          .eq('user_id', _userId!)
          .eq('status', 'approved');

      final approvedRequestsList = approvedRequestsResponse as List? ?? [];
      for (var req in approvedRequestsList) {
        final post = req['matchmaking_posts'];
        if (post == null) continue;
        final hostName = post['host']?['name'] as String? ?? 'Chủ kèo';
        final booking = post['bookings'];
        if (booking == null) continue;

        final slots = booking['booking_slots'] as List? ?? [];
        if (slots.isEmpty) continue;

        // Gom các slot theo ngày
        final Map<String, List<int>> dateToSlots = {};
        final Map<String, String> dateToVenueName = {};
        final Map<String, String> dateToCourtName = {};
        for (var slot in slots) {
          final dateStr = slot['booking_date'] as String;
          final slotIndex = slot['slot_index'] as int;
          final venueName = slot['courts']?['venues']?['name'] as String? ?? 'Sân thể thao';
          final courtName = slot['courts']?['name'] as String? ?? 'Sân';
          
          dateToSlots.putIfAbsent(dateStr, () => []).add(slotIndex);
          dateToVenueName[dateStr] = venueName;
          dateToCourtName[dateStr] = courtName;
        }

        for (var entry in dateToSlots.entries) {
          final dateStr = entry.key;
          final indices = entry.value..sort();
          final minSlotIndex = indices.first;
          final venueName = dateToVenueName[dateStr] ?? 'Sân thể thao';
          final courtName = dateToCourtName[dateStr] ?? 'Sân';

          final date = DateTime.parse(dateStr);
          final startMinutes = 6 * 60 + minSlotIndex * 30;
          final matchStart = date.add(Duration(minutes: startMinutes));

          // Chỉ hiển thị kèo còn hạn tham gia
          if (matchStart.isAfter(now)) {
            final endMinutes = 6 * 60 + (indices.last + 1) * 30;
            final startH = startMinutes ~/ 60;
            final startM = startMinutes % 60;
            final endH = endMinutes ~/ 60;
            final endM = endMinutes % 60;
            final timeRange = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')} - ${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

            tempMatches.add({
              'type': 'matchmaking_approved',
              'title': 'Kèo giao lưu (Đã duyệt)',
              'subtitle': '$venueName ($courtName) - Chủ sân: $hostName',
              'date': dateStr,
              'time': timeRange,
              'dateTime': matchStart,
            });
          }
        }
      }

      // Sắp xếp các trận đấu theo thứ tự thời gian tăng dần
      tempMatches.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));

      // 3. Lấy yêu cầu ghép kèo chờ duyệt (matchmaking_requests)
      final myPostsResponse = await supabase
          .from('matchmaking_posts')
          .select('id')
          .eq('host_id', _userId!);
      
      final myPostsList = myPostsResponse as List? ?? [];
      final postIds = myPostsList.map((p) => p['id'] as String).toList();

      List<Map<String, dynamic>> tempRequests = [];
      if (postIds.isNotEmpty) {
        final requestsResponse = await supabase
            .from('matchmaking_requests')
            .select('*, profiles!user_id(name), matchmaking_posts(*, bookings(booking_slots(courts(venues(name)))))')
            .inFilter('post_id', postIds)
            .eq('status', 'pending');
        
        final requestsList = requestsResponse as List? ?? [];
        for (var req in requestsList) {
          final requesterName = req['profiles']?['name'] as String? ?? 'Thành viên mới';
          final postMessage = req['matchmaking_posts']?['message'] as String? ?? 'Ghép đôi thi đấu';
          
          final slots = req['matchmaking_posts']?['bookings']?['booking_slots'] as List? ?? [];
          String venueName = 'Sân thể thao';
          if (slots.isNotEmpty) {
            venueName = slots.first['courts']?['venues']?['name'] as String? ?? 'Sân thể thao';
          }

          tempRequests.add({
            'id': req['id'],
            'postId': req['post_id'],
            'requesterName': requesterName,
            'message': req['message'] ?? 'Xin tham gia kèo',
            'postMessage': postMessage,
            'venue': venueName,
            'date': req['created_at'] != null 
                ? DateTime.parse(req['created_at']).toLocal().toString().substring(0, 16)
                : '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _upcomingMatches = tempMatches;
          _pendingRequests = tempRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu thông báo: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header thanh trượt kéo xuống
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 5),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Tiêu đề chính
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trung tâm thông báo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text('Lịch thi đấu'),
                    if (_upcomingMatches.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_upcomingMatches.length}',
                          style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      )
                    ]
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_soccer_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text('Kèo cần duyệt'),
                    if (_pendingRequests.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_pendingRequests.length}',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(height: 1),
          
          // Danh sách nội dung
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUpcomingMatchesList(),
                      _buildPendingRequestsList(),
                    ],
                  ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatchesList() {
    if (_upcomingMatches.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today_outlined,
        message: 'Bạn không có trận đấu hay sự kiện sắp diễn ra.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingMatches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = _upcomingMatches[index];
        final isEvent = match['type'] == 'event';
        final isMatchmakingApproved = match['type'] == 'matchmaking_approved';
        
        return InkWell(
          onTap: () {
            Navigator.pop(context);
            if (isMatchmakingApproved) {
              context.push('/MatchmakingBoardPage');
            } else {
              context.push('/BookedCourtPage');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEvent
                        ? Colors.orange.shade50
                        : isMatchmakingApproved
                            ? Colors.blue.shade50
                            : Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEvent
                        ? Icons.event_note
                        : isMatchmakingApproved
                            ? Icons.people_alt_outlined
                            : Icons.sports_tennis_rounded,
                    color: isEvent
                        ? Colors.orange
                        : isMatchmakingApproved
                            ? Colors.blue
                            : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match['subtitle'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${match['time']}  |  ${match['date']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsList() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sports_handball_outlined,
        message: 'Không có yêu cầu tham gia kèo mới nào cần duyệt.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = _pendingRequests[index];
        
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              TextSpan(
                                text: req['requesterName'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' muốn tham gia kèo của bạn'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sân: ${req['venue']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (req['message'] != null && req['message'].isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Text(
                              '"${req['message']}"',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    req['date'],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/ManageRequestsPage', extra: req['postId']);
                    },
                    child: const Text(
                      'Duyệt ngay',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
