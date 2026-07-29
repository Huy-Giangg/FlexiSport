import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_request.dart';

abstract class MatchmakingRepository {
  Future<List<MatchmakingPost>> getMatchmakingPosts({
    String? sportCategory,
    String? district,
    String? level,
  });

  Future<void> createMatchmakingPost(MatchmakingPost post);

  Future<List<MatchmakingRequest>> getMatchmakingRequests(String postId);

  Future<void> submitMatchmakingRequest(MatchmakingRequest request);

  Future<void> updateRequestStatus(String requestId, String status);

  Future<void> updatePostStatus(String postId, String status);

  Future<List<MatchmakingRequest>> getUserRequests(String userId);
}
