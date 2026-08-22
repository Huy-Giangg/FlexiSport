import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_request.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:flexisport_app/features/customer/matchmaking/data/datasources/matchmaking_remote_datasource.dart';
import 'package:flexisport_app/features/customer/matchmaking/data/models/matchmaking_post_model.dart';
import 'package:flexisport_app/features/customer/matchmaking/data/models/matchmaking_request_model.dart';

class MatchmakingRepositoryImpl implements MatchmakingRepository {
  final MatchmakingRemoteDatasource remoteDatasource;

  MatchmakingRepositoryImpl(this.remoteDatasource);

  @override
  Future<List<MatchmakingPost>> getMatchmakingPosts({
    String? sportCategory,
    String? district,
    String? level,
  }) async {
    final models = await remoteDatasource.fetchMatchmakingPosts(
      sportCategory: sportCategory,
      district: district,
      level: level,
    );
    return models.map((m) => m as MatchmakingPost).toList();
  }

  @override
  Future<void> createMatchmakingPost(MatchmakingPost post) async {
    final model = MatchmakingPostModel(
      id: post.id,
      bookingId: post.bookingId,
      hostId: post.hostId,
      slotsNeeded: post.slotsNeeded,
      slotsAvailable: post.slotsAvailable,
      targetLevel: post.targetLevel,
      estimatedCostPerPerson: post.estimatedCostPerPerson,
      message: post.message,
      status: post.status,
      createdAt: post.createdAt,
    );
    await remoteDatasource.insertMatchmakingPost(model);
  }

  @override
  Future<List<MatchmakingRequest>> getMatchmakingRequests(String postId) async {
    final models = await remoteDatasource.fetchMatchmakingRequests(postId);
    return models.map((m) => m as MatchmakingRequest).toList();
  }

  @override
  Future<void> submitMatchmakingRequest(MatchmakingRequest request) async {
    final model = MatchmakingRequestModel(
      id: request.id,
      postId: request.postId,
      userId: request.userId,
      message: request.message,
      status: request.status,
      createdAt: request.createdAt,
    );
    await remoteDatasource.insertMatchmakingRequest(model);
  }

  @override
  Future<void> updateRequestStatus(String requestId, String status) async {
    await remoteDatasource.updateRequestStatus(requestId, status);
  }

  @override
  Future<void> updatePostStatus(String postId, String status) async {
    await remoteDatasource.updatePostStatus(postId, status);
  }

  @override
  Future<List<MatchmakingRequest>> getUserRequests(String userId) async {
    final models = await remoteDatasource.fetchUserRequests(userId);
    return models.map((m) => m as MatchmakingRequest).toList();
  }
}
