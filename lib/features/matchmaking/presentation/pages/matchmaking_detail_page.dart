import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_request.dart';
import 'package:flexisport_app/features/matchmaking/presentation/providers/matchmaking_provider.dart';

class MatchmakingDetailPage extends StatefulWidget {
  final MatchmakingPost post;
  const MatchmakingDetailPage({super.key, required this.post});

  @override
  State<MatchmakingDetailPage> createState() => _MatchmakingDetailPageState();
}

class _MatchmakingDetailPageState extends State<MatchmakingDetailPage> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchmakingProvider>().loadRequests(widget.post.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendRequest() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để xin ghép kèo.')),
      );
      final mainPageProvider = context.read<MainPageProvider>();
      mainPageProvider.hideNavbar();
      context.push('/login').then((_) {
        mainPageProvider.showNavbar();
      });
      return;
    }

    final request = MatchmakingRequest(
      id: '',
      postId: widget.post.id,
      userId: currentUserId,
      message: _messageController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    context
        .read<MatchmakingProvider>()
        .submitRequest(request)
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi yêu cầu ghép kèo! Đang chờ chủ kèo duyệt.'),
            ),
          );
          Navigator.pop(context);
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gửi yêu cầu thất bại: $e')));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D38),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: const Text(
          "Chi tiết kèo ghép",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ chi tiết sân
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.post.sportType?.toUpperCase() ?? 'THỂ THAO',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Trình độ: ${widget.post.targetLevel}',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.post.venueName ?? 'Tổ hợp sân'} - ${widget.post.courtName ?? 'Sân con'}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.post.bookingDate ?? ''} | ${widget.post.bookingTime ?? ''}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on_outlined,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.post.estimatedCostPerPerson > 0
                              ? '${widget.post.estimatedCostPerPerson.toStringAsFixed(0)}đ / người'
                              : 'Miễn phí / Chủ kèo bao',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Thông tin chủ kèo
            const Text(
              'Chủ kèo:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 24,
                child: Icon(Icons.person),
              ),
              title: Text(
                widget.post.hostName ??
                    'Chủ kèo ID: ${widget.post.hostId.substring(0, 8)}',
              ),
              subtitle: const Text('Đánh giá: ⭐ 4.9 (15 kèo ghép thành công)'),
            ),
            const SizedBox(height: 16),

            // Lời nhắn từ chủ kèo
            if (widget.post.message != null &&
                widget.post.message!.isNotEmpty) ...[
              const Text(
                'Lời nhắn từ chủ kèo:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.post.message!),
              ),
              const SizedBox(height: 24),
            ],

            // Bộ đếm slot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Số chỗ trống còn lại:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.post.slotsAvailable} / ${widget.post.slotsNeeded}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Consumer for request status and action button
            Consumer<MatchmakingProvider>(
              builder: (context, provider, child) {
                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id;

                MatchmakingRequest? userRequest;
                for (final r in provider.requests) {
                  if (r.userId == currentUserId && r.status != 'cancelled') {
                    userRequest = r;
                    break;
                  }
                }

                final isHost =
                    currentUserId != null &&
                    currentUserId == widget.post.hostId;
                if (isHost) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.stars, color: Colors.green),
                            SizedBox(width: 12),
                            Text(
                              'Bạn là chủ kèo đấu này',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Hủy đăng kèo'),
                                content: const Text(
                                  'Bạn có chắc chắn muốn hủy đăng kèo ghép này không?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Không'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      provider.cancelPost(widget.post.id).then((
                                        _,
                                      ) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Đã hủy đăng kèo thành công',
                                              ),
                                            ),
                                          );
                                          Navigator.pop(context);
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
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text(
                            'Hủy Đăng Kèo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (userRequest != null) {
                  // User has an active request (pending, approved, or rejected)
                  String statusText = 'Đang chờ duyệt';
                  Color statusColor = Colors.orange;
                  IconData statusIcon = Icons.hourglass_empty;

                  if (userRequest.status == 'approved') {
                    statusText = 'Được chấp nhận';
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle_outline;
                  } else if (userRequest.status == 'rejected') {
                    statusText = 'Bị từ chối';
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel_outlined;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display the message they sent
                      if (userRequest.message != null &&
                          userRequest.message!.isNotEmpty) ...[
                        const Text(
                          'Lời nhắn của bạn:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(userRequest.message!),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Request status banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor),
                            const SizedBox(width: 12),
                            Text(
                              'Trạng thái yêu cầu: $statusText',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cancel/Withdraw button (only for pending or approved requests)
                      if (userRequest.status == 'pending' ||
                          userRequest.status == 'approved')
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Hủy yêu cầu tham gia'),
                                  content: const Text(
                                    'Bạn có chắc chắn muốn hủy yêu cầu tham gia kèo này không?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('Không'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                        provider
                                            .respondToRequest(
                                              userRequest!.id,
                                              'cancelled',
                                              widget.post.id,
                                            )
                                            .then((_) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Đã hủy yêu cầu tham gia thành công',
                                                    ),
                                                  ),
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
                            icon: const Icon(Icons.delete_outline),
                            label: const Text(
                              'Hủy Yêu Cầu Ghép Kèo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }

                // If no request exists, show the request input form and Submit button
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lời nhắn của bạn khi xin ghép:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText:
                            'Giới thiệu ngắn gọn trình độ của bạn hoặc phụ kiện (ví dụ: mình có vợt riêng)...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: widget.post.slotsAvailable > 0
                            ? _sendRequest
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.post.slotsAvailable > 0
                              ? 'Yêu Cầu Tham Gia Kèo'
                              : 'Kèo đã đầy',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
