import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/providers/matchmaking_provider.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryContainer, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
        title: Text(
          "Duyệt yêu cầu ghép kèo",
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<MatchmakingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer));
          }

          if (provider.requests.isEmpty) {
            return Center(
              child: Text(
                'Chưa có yêu cầu nào gửi tới kèo này.',
                style: GoogleFonts.lexend(color: Colors.grey.shade600, fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.requests.length,
            itemBuilder: (context, index) {
              final request = provider.requests[index];
              final isPending = request.status == 'pending';
              final isCancelRequested = request.status == 'cancel_requested';
              final isPendingCancel = request.status == 'pending_cancel';

              String statusLabel = 'Chờ duyệt';
              Color statusColor = Colors.orange;
              Color statusBg = Colors.orange.shade50;
              if (request.status == 'approved') {
                statusLabel = 'Đã chấp nhận';
                statusColor = AppColors.primaryContainer;
                statusBg = AppColors.primaryContainer.withValues(alpha: 0.1);
              } else if (isCancelRequested) {
                statusLabel = 'Xin hủy tham gia';
                statusColor = Colors.deepOrange;
                statusBg = Colors.deepOrange.shade50;
              } else if (isPendingCancel) {
                statusLabel = 'Xin rút yêu cầu';
                statusColor = Colors.orange.shade800;
                statusBg = Colors.orange.shade50;
              } else if (request.status == 'rejected') {
                statusLabel = 'Đã từ chối';
                statusColor = Colors.red;
                statusBg = Colors.red.shade50;
              } else if (request.status == 'cancelled') {
                statusLabel = 'Đã hủy';
                statusColor = Colors.grey.shade600;
                statusBg = Colors.grey.shade100;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.primaryContainer.withValues(alpha: 0.15)),
                ),
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: AppColors.primaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.requesterName ?? 'Người dùng ID: ${request.userId.substring(0, 8)}',
                                  style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: GoogleFonts.lexend(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
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
                            label: Text(
                              'Xem hồ sơ',
                              style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (request.message != null && request.message!.isNotEmpty) ...[
                        Text(
                          'Lời nhắn:',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            request.message!,
                            style: GoogleFonts.lexend(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Thông báo khi có yêu cầu hủy
                      if (isCancelRequested) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.deepOrange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.deepOrange.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Thành viên đã được duyệt này muốn hủy tham gia kèo. Bạn cần xác nhận để hoàn lại slot.',
                                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.deepOrange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isPendingCancel) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Người dùng muốn rút lại yêu cầu xin ghép kèo này.',
                                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Hành động cho trạng thái chờ duyệt
                      if (isPending)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                provider.respondToRequest(request.id, 'rejected', widget.postId);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text('Từ chối', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                provider.respondToRequest(request.id, 'approved', widget.postId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                elevation: 0,
                              ),
                              child: Text('Đồng ý', style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      // Hành động khi thành viên xin hủy tham gia (cancel_requested)
                      else if (isCancelRequested)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Từ chối yêu cầu hủy'),
                                    content: Text(
                                      'Bạn có chắc chắn muốn từ chối yêu cầu hủy của ${request.requesterName ?? 'thành viên này'} không? Họ vẫn sẽ ở trong kèo.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text('Đóng'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          provider.respondToRequest(
                                            request.id,
                                            'approved',
                                            widget.postId,
                                            wasApproved: true,
                                          ).then((_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Đã từ chối yêu cầu hủy.')),
                                              );
                                            }
                                          });
                                        },
                                        child: const Text('Từ chối hủy', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: Text('Từ chối hủy', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Xác nhận đồng ý hủy'),
                                    content: Text(
                                      'Xác nhận cho phép ${request.requesterName ?? 'thành viên này'} hủy tham gia kèo? 1 vị trí trống sẽ được hoàn lại cho kèo.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text('Không'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          provider.respondToRequest(
                                            request.id,
                                            'cancelled',
                                            widget.postId,
                                            wasApproved: true,
                                          ).then((_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Đã xác nhận hủy tham gia và hoàn lại slot thành công.'),
                                                ),
                                              );
                                            }
                                          });
                                        },
                                        child: const Text('Đồng ý hủy', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 0,
                              ),
                              child: Text('Xác nhận hủy', style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      // Hành động khi người dùng xin rút yêu cầu đang chờ (pending_cancel)
                      else if (isPendingCancel)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                provider.respondToRequest(
                                  request.id,
                                  'pending',
                                  widget.postId,
                                  wasApproved: false,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: Text('Từ chối', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                provider.respondToRequest(
                                  request.id,
                                  'cancelled',
                                  widget.postId,
                                  wasApproved: false,
                                ).then((_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã đồng ý hủy yêu cầu.')),
                                    );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 0,
                              ),
                              child: Text('Xác nhận hủy', style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
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
