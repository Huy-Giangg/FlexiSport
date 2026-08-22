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
            venues (
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

  Future<void> updateRequestStatus(String requestId, String status) async {
    await supabaseClient
        .from('matchmaking_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  Future<void> updatePostStatus(String postId, String status) async {
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
