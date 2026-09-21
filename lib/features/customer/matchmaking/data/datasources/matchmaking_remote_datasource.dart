import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/customer/matchmaking/data/models/matchmaking_post_model.dart';
import 'package:flexisport_app/features/customer/matchmaking/data/models/matchmaking_request_model.dart';

class MatchmakingRemoteDatasource {
  final SupabaseClient supabaseClient;

  MatchmakingRemoteDatasource(this.supabaseClient);

  Future<List<MatchmakingPostModel>> fetchMatchmakingPosts({
    String? sportCategory,
    String? district,
    String? level,
  }) async {
    var query = supabaseClient.from('matchmaking_posts').select('''
      *,
      host:profiles!host_id ( name, phone ),
      bookings!booking_id (
        id,
        booking_slots (
          booking_date,
          slot_index,
          courts (
            name,
            venue_id,
            venues (
              id,
              name,
              address,
              sports_type
            )
          )
        )
      )
    ''').neq('status', 'cancelled');

    if (level != null && level.isNotEmpty && level != 'Tất cả') {
      query = query.eq('target_level', level);
    }

    final response = await query.order('created_at', ascending: false);
    final List<MatchmakingPostModel> posts = (response as List)
        .map((json) => MatchmakingPostModel.fromJson(json))
        .toList();

    // Lọc client-side cho sportCategory để tránh cú pháp lọc join phức tạp dễ sinh lỗi
    if (sportCategory != null && sportCategory.isNotEmpty && sportCategory != 'Tất cả') {
      return posts.where((post) => 
        post.sportType?.toLowerCase() == sportCategory.toLowerCase()
      ).toList();
    }

    return posts;
  }

  Future<void> insertMatchmakingPost(MatchmakingPostModel post) async {
    await supabaseClient.from('matchmaking_posts').insert(post.toJson());
  }

  Future<List<MatchmakingRequestModel>> fetchMatchmakingRequests(String postId) async {
    final response = await supabaseClient
        .from('matchmaking_requests')
        .select('*, requester:profiles!user_id ( name, phone )')
        .eq('post_id', postId);

    return (response as List)
        .map((json) => MatchmakingRequestModel.fromJson(json))
        .toList();
  }

  Future<void> insertMatchmakingRequest(MatchmakingRequestModel request) async {
    await supabaseClient.from('matchmaking_requests').insert(request.toJson());
  }

  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? postId,
    bool? wasApproved,
  }) async {
    await supabaseClient
        .from('matchmaking_requests')
        .update({'status': status})
        .eq('id', requestId);

    // Khi chủ kèo xác nhận hủy cho thành viên đã được duyệt tham gia,
    // hoàn lại 1 slot cho post nếu cần
    if (status == 'cancelled' && wasApproved == true && postId != null) {
      final postRes = await supabaseClient
          .from('matchmaking_posts')
          .select('slots_available, slots_needed')
          .eq('id', postId)
          .maybeSingle();

      if (postRes != null) {
        final currentSlots = postRes['slots_available'] as int? ?? 0;
        final maxSlots = postRes['slots_needed'] as int? ?? 1;
        if (currentSlots < maxSlots) {
          final newSlots = (currentSlots + 1).clamp(0, maxSlots);
          await supabaseClient
              .from('matchmaking_posts')
              .update({
                'slots_available': newSlots,
                'status': 'open',
              })
              .eq('id', postId);
        }
      }
    }
  }

  Future<void> updatePostStatus(String postId, String status) async {
    if (status == 'cancelled') {
      final postRes = await supabaseClient
          .from('matchmaking_posts')
          .select('slots_needed, slots_available')
          .eq('id', postId)
          .maybeSingle();

      if (postRes != null) {
        final slotsNeeded = postRes['slots_needed'] as int? ?? 0;
        final slotsAvailable = postRes['slots_available'] as int? ?? 0;

        final activeRequests = await supabaseClient
            .from('matchmaking_requests')
            .select('id')
            .eq('post_id', postId)
            .inFilter('status', ['approved', 'cancel_requested']);

        if (slotsAvailable < slotsNeeded || (activeRequests as List).isNotEmpty) {
          throw Exception(
            'Không thể hủy kèo khi đã có người tham gia được duyệt. Chỉ có thể hủy khi tất cả người tham gia đã rời kèo.',
          );
        }
      }
    }

    await supabaseClient
        .from('matchmaking_posts')
        .update({'status': status})
        .eq('id', postId);
  }

  Future<List<MatchmakingRequestModel>> fetchUserRequests(String userId) async {
    final response = await supabaseClient
        .from('matchmaking_requests')
        .select('*')
        .eq('user_id', userId);

    return (response as List)
        .map((json) => MatchmakingRequestModel.fromJson(json))
        .toList();
  }
}
