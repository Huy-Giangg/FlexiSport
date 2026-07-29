import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/features/matchmaking/presentation/providers/matchmaking_provider.dart';
import 'package:flexisport_app/features/profile/presentation/page/profile_detail_page.dart';

class ManageRequestsPage extends StatefulWidget {
  final String postId;
  const ManageRequestsPage({super.key, required this.postId});

  @override
  State<ManageRequestsPage> createState() => _ManageRequestsPageState();
}

class _ManageRequestsPageState extends State<ManageRequestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchmakingProvider>().loadRequests(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
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
          "Duyệt yêu cầu ghép kèo",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Consumer<MatchmakingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.requests.isEmpty) {
            return const Center(
              child: Text('Chưa có yêu cầu nào gửi tới kèo này.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.requests.length,
            itemBuilder: (context, index) {
              final request = provider.requests[index];
              final isPending = request.status == 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.requesterName ?? 'Người dùng ID: ${request.userId.substring(0, 8)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Trạng thái: ${request.status.toUpperCase()}'),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileDetailPage(userId: request.userId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.account_circle_outlined, size: 18),
                            label: const Text('Xem hồ sơ', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (request.message != null && request.message!.isNotEmpty) ...[
                        const Text(
                          'Lời nhắn:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(request.message!),
                        const SizedBox(height: 16),
                      ],
                      if (isPending)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                provider.respondToRequest(request.id, 'rejected', widget.postId);
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Từ chối'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                provider.respondToRequest(request.id, 'approved', widget.postId);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Đồng ý'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
