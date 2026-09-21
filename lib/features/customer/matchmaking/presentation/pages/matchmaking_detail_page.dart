import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/auth/utils/validators.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_request.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/providers/matchmaking_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/data/models/sports_complex_model.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/sport_show_detail.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/pages/manage_requests_page.dart';

class MatchmakingDetailPage extends StatefulWidget {
  final MatchmakingPost post;
  const MatchmakingDetailPage({super.key, required this.post});

  @override
  State<MatchmakingDetailPage> createState() => _MatchmakingDetailPageState();
}

class _MatchmakingDetailPageState extends State<MatchmakingDetailPage> {
  final _messageController = TextEditingController();
  String? _venueAddress;
  String? _venueId;
  SportsComplexEntity? _venueEntity;
  bool _isLoadingVenue = false;

  @override
  void initState() {
    super.initState();
    _venueAddress = widget.post.venueAddress;
    _venueId = widget.post.venueId;
    _fetchVenueInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchmakingProvider>().loadRequests(widget.post.id);
    });
  }

  Future<void> _fetchVenueInfo() async {
    // 1. Kiểm tra trong cache của SportsComplexProvider
    try {
      final provider = context.read<SportsComplexProvider>();
      if (_venueId != null && _venueId!.isNotEmpty) {
        final cached = provider.stadiums.where((s) => s.id == _venueId).firstOrNull;
        if (cached != null) {
          if (mounted) {
            setState(() {
              _venueEntity = cached;
              if (_venueAddress == null || _venueAddress!.isEmpty) {
                _venueAddress = cached.address;
              }
            });
          }
          return;
        }
      }
    } catch (_) {}

    // 2. Tải trực tiếp từ bảng venues nếu có venueId
    try {
      if (_venueId != null && _venueId!.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('venues')
            .select('*')
            .eq('id', _venueId!)
            .maybeSingle();
        if (res != null && mounted) {
          final venue = SportsComplexModel.fromJson(res);
          setState(() {
            _venueEntity = venue;
            _venueAddress = venue.address;
          });
          return;
        }
      }

      // 3. Dự phòng: Tìm venue qua booking_id -> booking_slots -> courts -> venues
      if (widget.post.bookingId.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('bookings')
            .select('''
              booking_slots (
                courts (
                  venue_id,
                  venues (
                    id,
                    name,
                    address,
                    logo_url,
                    rating,
                    open_time,
                    close_time,
                    latitude,
                    longitude,
                    sports_type
                  )
                )
              )
            ''')
            .eq('id', widget.post.bookingId)
            .maybeSingle();

        if (res != null && mounted) {
          final slots = res['booking_slots'] as List? ?? [];
          if (slots.isNotEmpty) {
            final court = slots.first['courts'] as Map<String, dynamic>?;
            final venueData = court?['venues'] as Map<String, dynamic>?;
            if (venueData != null) {
              final venue = SportsComplexModel.fromJson(venueData);
              setState(() {
                _venueId = venue.id;
                _venueAddress = venue.address;
                _venueEntity = venue;
              });
              return;
            }
          }
        }
      }

      // 4. Dự phòng: Tìm theo tên venueName
      if (widget.post.venueName != null && widget.post.venueName!.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('venues')
            .select('*')
            .ilike('name', widget.post.venueName!)
            .maybeSingle();
        if (res != null && mounted) {
          final venue = SportsComplexModel.fromJson(res);
          setState(() {
            _venueId = venue.id;
            _venueAddress = venue.address;
            _venueEntity = venue;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi nạp thông tin sân thể thao: $e");
    }
  }

  void _openVenueDetail() async {
    if (_venueEntity != null) {
      _showDetailBottomSheet(_venueEntity!);
      return;
    }

    setState(() => _isLoadingVenue = true);
    await _fetchVenueInfo();
    if (mounted) setState(() => _isLoadingVenue = false);

    if (_venueEntity != null && mounted) {
      _showDetailBottomSheet(_venueEntity!);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin chi tiết sân thể thao này.')),
      );
    }
  }

  void _showDetailBottomSheet(SportsComplexEntity venue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SportShowDetail(sportsComplexEntity: venue),
    );
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
          "Chi tiết kèo ghép",
          style: GoogleFonts.lexend(
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
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primaryContainer.withValues(alpha: 0.15)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Môn thể thao & Trình độ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.post.sportType?.toUpperCase() ?? 'THỂ THAO',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            'Trình độ: ${widget.post.targetLevel}',
                            style: GoogleFonts.lexend(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tên sân & Tổ hợp
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.stadium_rounded,
                          color: AppColors.primaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.post.venueName ?? 'Tổ hợp sân'} - ${widget.post.courtName ?? 'Sân con'}',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Địa chỉ chi tiết của sân thể thao
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (_venueAddress != null && _venueAddress!.isNotEmpty)
                                ? _venueAddress!
                                : (widget.post.venueAddress ?? 'Đang cập nhật địa chỉ...'),
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Thời gian thi đấu
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: AppColors.outline,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${widget.post.bookingDate ?? ''} | ${widget.post.bookingTime ?? ''}',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chi phí dự kiến
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on_outlined,
                          color: AppColors.primaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.post.estimatedCostPerPerson > 0
                              ? '${MyValidators.formatCurrency(widget.post.estimatedCostPerPerson)}đ / người'
                              : 'Miễn phí / Chủ kèo bao',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: widget.post.estimatedCostPerPerson > 0
                                ? AppColors.primaryContainer
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Nút bấm Xem chi tiết sân thể thao
                    InkWell(
                      onTap: _openVenueDetail,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.storefront_rounded,
                                  size: 18,
                                  color: AppColors.primaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Xem chi tiết sân thể thao',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            _isLoadingVenue
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryContainer,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.primaryContainer,
                                  ),
                          ],
                        ),
                      ),
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
            Consumer<MatchmakingProvider>(
              builder: (context, provider, _) {
                final livePost = provider.posts.firstWhere(
                  (p) => p.id == widget.post.id,
                  orElse: () => widget.post,
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Số chỗ trống còn lại:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${livePost.slotsAvailable} / ${livePost.slotsNeeded}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Consumer for request status and action button
            Consumer<MatchmakingProvider>(
              builder: (context, provider, child) {
                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id;

                final livePost = provider.posts.firstWhere(
                  (p) => p.id == widget.post.id,
                  orElse: () => widget.post,
                );

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
                  final hasAcceptedParticipants = livePost.slotsAvailable < livePost.slotsNeeded ||
                      provider.requests.any((r) => r.status == 'approved' || r.status == 'cancel_requested');

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
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
                      const SizedBox(height: 16),

                      // Nút Quản lý / Duyệt yêu cầu dành cho chủ kèo
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageRequestsPage(postId: widget.post.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.people_alt_outlined),
                          label: const Text(
                            'Duyệt Yêu Cầu Ghép Kèo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (hasAcceptedParticipants) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kèo hiện có ${livePost.slotsNeeded - livePost.slotsAvailable} người tham gia được duyệt. Bạn không thể hủy kèo khi vẫn còn người tham gia.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (hasAcceptedParticipants) {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Không thể hủy kèo'),
                                  content: Text(
                                    'Kèo ghép này đã có người tham gia được duyệt (${livePost.slotsNeeded - livePost.slotsAvailable}/${livePost.slotsNeeded} chỗ).\n\nBạn chỉ có thể hủy kèo khi không còn người tham gia nào trong kèo (tất cả người tham gia đã hủy và được xác nhận).',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('Đã hiểu'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

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
                                      }).catchError((err) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Lỗi: $err')),
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
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text(
                            'Hủy Đăng Kèo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasAcceptedParticipants ? Colors.grey.shade300 : Colors.red,
                            foregroundColor: hasAcceptedParticipants ? Colors.grey.shade600 : Colors.white,
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
                  // User has an active request (pending, approved, cancel_requested, pending_cancel, or rejected)
                  String statusText = 'Đang chờ duyệt';
                  Color statusColor = Colors.orange;
                  IconData statusIcon = Icons.hourglass_empty;

                  final isCancelPending = userRequest.status == 'cancel_requested' ||
                      userRequest.status == 'pending_cancel';

                  if (userRequest.status == 'approved') {
                    statusText = 'Được chấp nhận';
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle_outline;
                  } else if (isCancelPending) {
                    statusText = 'Chờ chủ kèo xác nhận hủy';
                    statusColor = Colors.deepOrange;
                    statusIcon = Icons.hourglass_top_rounded;
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
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Trạng thái yêu cầu: $statusText',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isCancelPending) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.deepOrange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.deepOrange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bạn đã gửi yêu cầu hủy. Vui lòng chờ phản hồi xác nhận từ chủ kèo.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.deepOrange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Cancel/Withdraw button
                      if (userRequest.status == 'pending' ||
                          userRequest.status == 'approved')
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final wasApproved = userRequest!.status == 'approved';
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(wasApproved ? 'Hủy tham gia kèo' : 'Hủy yêu cầu ghép kèo'),
                                  content: Text(
                                    wasApproved
                                        ? 'Yêu cầu hủy tham gia cần được chủ kèo xác nhận. Bạn có chắc chắn muốn gửi yêu cầu hủy tham gia kèo này không?'
                                        : 'Yêu cầu hủy cần được chủ kèo xác nhận. Bạn có chắc chắn muốn gửi yêu cầu hủy không?',
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
                                            .requestCancelParticipation(
                                              userRequest!.id,
                                              widget.post.id,
                                              wasApproved: wasApproved,
                                            )
                                            .then((_) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Đã gửi yêu cầu hủy tới chủ kèo. Vui lòng chờ xác nhận.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            })
                                            .catchError((err) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi: $err')),
                                                );
                                              }
                                            });
                                      },
                                      child: const Text(
                                        'Gửi yêu cầu hủy',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: Text(
                              userRequest.status == 'approved'
                                  ? 'Hủy Tham Gia Kèo'
                                  : 'Hủy Yêu Cầu Ghép Kèo',
                              style: const TextStyle(
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
                        )
                      else if (isCancelPending)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.access_time_rounded),
                            label: const Text(
                              'Đang Chờ Chủ Kèo Xác Nhận Hủy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: BorderSide(color: Colors.grey.shade400),
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
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: widget.post.slotsAvailable > 0
                            ? const LinearGradient(
                                colors: [AppColors.primaryContainer, AppColors.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: widget.post.slotsAvailable <= 0 ? Colors.grey.shade400 : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: widget.post.slotsAvailable > 0
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: widget.post.slotsAvailable > 0
                            ? _sendRequest
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.post.slotsAvailable > 0
                              ? 'Yêu Cầu Tham Gia Kèo'
                              : 'Kèo đã đầy',
                          style: GoogleFonts.lexend(
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
