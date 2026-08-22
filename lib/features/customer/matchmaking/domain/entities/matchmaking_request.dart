class MatchmakingRequest {
  final String id;
  final String postId;
  final String userId;
  final String? message;
  final String status;
  final DateTime createdAt;

  final String? requesterName;
  final String? requesterPhone;

  const MatchmakingRequest({
    required this.id,
    required this.postId,
    required this.userId,
    this.message,
    required this.status,
    required this.createdAt,
    this.requesterName,
    this.requesterPhone,
  });
}
