import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class OwnerNotificationsBottomSheet extends StatefulWidget {
  const OwnerNotificationsBottomSheet({super.key});

  @override
  State<OwnerNotificationsBottomSheet> createState() => _OwnerNotificationsBottomSheetState();
}

class _OwnerNotificationsBottomSheetState extends State<OwnerNotificationsBottomSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    _ownerId = Supabase.instance.client.auth.currentUser?.id;
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (_ownerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Lấy thông báo từ bảng notifications
      final notifResp = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', _ownerId!)
          .order('created_at', ascending: false)
          .limit(30);

      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(notifResp as List);

      // Nếu bảng notifications rỗng, lấy các đơn đặt sân gần đây làm thông báo mặc định
      if (list.isEmpty) {
        // Tìm các cơ sở của chủ sân
        final venuesResp = await supabase
            .from('venues')
            .select('id, name')
            .eq('owner_id', _ownerId!);
        
        final venueIds = (venuesResp as List).map((v) => v['id'].toString()).toList();
        if (venueIds.isNotEmpty) {
          final bookingsResp = await supabase
              .from('booking_slots')
              .select('booking_id, booking_date, slot_index, courts!inner(name, venue_id, venues!inner(name)), bookings!inner(id, status, customer_name, total_amount, created_at)')
              .inFilter('courts.venue_id', venueIds)
              .order('created_at', ascending: false)
              .limit(20);

          final Set<String> seenBookingIds = {};
          for (var item in bookingsResp as List) {
            final b = item['bookings'];
            if (b == null) continue;
            final bId = b['id']?.toString() ?? '';
            if (seenBookingIds.contains(bId)) continue;
            seenBookingIds.add(bId);

            final customerName = b['customer_name']?.toString() ?? 'Khách hàng';
            final venueName = item['courts']?['venues']?['name']?.toString() ?? 'Cơ sở';
            final courtName = item['courts']?['name']?.toString() ?? 'Sân';
            final date = item['booking_date']?.toString() ?? '';
            final status = b['status']?.toString() ?? 'pending';

            list.add({
              'id': bId,
              'title': status == 'cancelled' ? 'Đơn đặt sân đã bị hủy ⚠️' : 'Đơn đặt sân mới! 🏸',
              'body': 'Khách $customerName đặt $courtName ngày $date tại $venueName.',
              'type': status == 'cancelled' ? 'booking_cancelled' : 'new_booking',
              'created_at': b['created_at'] ?? DateTime.now().toIso8601String(),
              'is_read': false,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải thông báo chủ sân: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_ownerId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _ownerId!);

      if (mounted) {
        setState(() {
          for (var item in _notifications) {
            item['is_read'] = true;
          }
        });
      }
    } catch (_) {}
  }

  String _formatTimeAgo(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Thanh gạt phía trên
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Tiêu đề & Nút Đánh dấu đã đọc
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Thông báo Chủ sân',
                      style: GoogleFonts.lexend(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _markAllAsRead,
                  child: Text(
                    'Đã đọc tất cả',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Danh sách thông báo
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final isUnread = item['is_read'] != true;
                          final isCancel = item['type'] == 'booking_cancelled';

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/owner/bookings');
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUnread ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isUnread ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isCancel ? Colors.red.shade50 : Colors.green.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCancel ? Icons.cancel_outlined : Icons.sports_tennis_rounded,
                                      color: isCancel ? Colors.red : AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['title'] ?? 'Thông báo',
                                                style: GoogleFonts.lexend(
                                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            if (isUnread)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['body'] ?? '',
                                          style: GoogleFonts.lexend(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatTimeAgo(item['created_at']),
                                          style: GoogleFonts.lexend(
                                            fontSize: 11,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 54, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              "Chưa có thông báo nào",
              style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              "Khi có khách hàng đặt sân hoặc hủy đơn, thông báo sẽ hiển thị tại đây.",
              style: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
