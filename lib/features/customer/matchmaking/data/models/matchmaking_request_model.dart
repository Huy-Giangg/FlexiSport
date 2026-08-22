import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_request.dart';

class MatchmakingRequestModel extends MatchmakingRequest {
  const MatchmakingRequestModel({
    required super.id,
    required super.postId,
    required super.userId,
    super.message,
    required super.status,
    required super.createdAt,
    super.requesterName,
    super.requesterPhone,
  });

  factory MatchmakingRequestModel.fromJson(Map<String, dynamic> json) {
    final requesterData = json['requester'] as Map<String, dynamic>?;
    final requesterName = requesterData?['name'] as String?;
    final requesterPhone = requesterData?['phone'] as String?;

    return MatchmakingRequestModel(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      requesterName: requesterName,
      requesterPhone: requesterPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'post_id': postId,
      'user_id': userId,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
