import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_request.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/pages/matchmaking_detail_page.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/pages/manage_requests_page.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/providers/matchmaking_provider.dart';

class MatchmakingCard extends StatelessWidget {
  final MatchmakingPost post;
  const MatchmakingCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isHost = currentUserId != null && post.hostId == currentUserId;

    final provider = context.watch<MatchmakingProvider>();
    MatchmakingRequest? userRequest;
    for (final r in provider.userRequests) {
      if (r.postId == post.id && r.status != 'cancelled') {
        userRequest = r;
        break;
      }
    }

    String? requestStatusText;
    Color requestStatusColor = Colors.orange;
    if (userRequest != null) {
      if (userRequest.status == 'pending') {
        requestStatusText = 'Chờ duyệt';
        requestStatusColor = Colors.orange;
      } else if (userRequest.status == 'approved') {
        requestStatusText = 'Đã nhận';
        requestStatusColor = Colors.green;
      } else if (userRequest.status == 'rejected') {
        requestStatusText = 'Bị từ chối';
        requestStatusColor = Colors.red;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchmakingDetailPage(post: post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header: Host avatar, name, and sport tag
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.hostName ?? 'Chủ kèo ID: ${post.hostId.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('⭐ 4.9 (Uy tín cao)'),
                    ],
                  ),
                ),
                if (requestStatusText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: requestStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: requestStatusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      requestStatusText,
                      style: TextStyle(color: requestStatusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    post.sportType ?? 'Thể thao',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Venue and time
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${post.venueName ?? 'Tổ hợp sân'} (${post.courtName ?? 'Sân con'})',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${post.bookingDate ?? ''} | ${post.bookingTime ?? ''}',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Slots and Cost row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chi phí / Người', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      post.estimatedCostPerPerson > 0
                          ? '${post.estimatedCostPerPerson.toStringAsFixed(0)}đ'
                          : 'Miễn phí',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trình độ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      post.targetLevel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Còn trống', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      '${post.slotsAvailable} / ${post.slotsNeeded} chỗ',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Message preview
            if (post.message != null && post.message!.isNotEmpty) ...[
              Text(
                '"${post.message}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],

            // Action button
            SizedBox(
              width: double.infinity,
              child: isHost
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Hủy đăng kèo'),
                                  content: const Text(
                                      'Bạn có chắc chắn muốn hủy đăng kèo ghép này không?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('Không'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                        context
                                            .read<MatchmakingProvider>()
                                            .cancelPost(post.id)
                                            .then((_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Đã hủy đăng kèo thành công')),
                                            );
                                          }
                                        });
                                      },
                                      child: const Text(
                                        'Có, Hủy',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Hủy Đăng Kèo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageRequestsPage(postId: post.id),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Duyệt Yêu Cầu'),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchmakingDetailPage(post: post),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userRequest != null ? Colors.blueGrey : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        userRequest != null
                            ? 'Xem Chi Tiết & Hủy Yêu Cầu'
                            : 'Xem Chi Tiết & Xin Ghép',
                      ),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
