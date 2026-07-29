class MatchmakingPost {
  final String id;
  final String bookingId;
  final String hostId;
  final int slotsNeeded;
  final int slotsAvailable;
  final String targetLevel;
  final double estimatedCostPerPerson;
  final String? message;
  final String status;
  final DateTime createdAt;

  final String? hostName;
  final String? venueName;
  final String? courtName;
  final String? sportType;
  final String? bookingDate;
  final String? bookingTime;

  const MatchmakingPost({
    required this.id,
    required this.bookingId,
    required this.hostId,
    required this.slotsNeeded,
    required this.slotsAvailable,
    required this.targetLevel,
    required this.estimatedCostPerPerson,
    this.message,
    required this.status,
    required this.createdAt,
    this.hostName,
    this.venueName,
    this.courtName,
    this.sportType,
    this.bookingDate,
    this.bookingTime,
  });
}
