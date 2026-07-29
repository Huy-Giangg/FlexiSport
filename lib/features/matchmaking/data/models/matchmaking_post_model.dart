import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_post.dart';

class MatchmakingPostModel extends MatchmakingPost {
  const MatchmakingPostModel({
    required super.id,
    required super.bookingId,
    required super.hostId,
    required super.slotsNeeded,
    required super.slotsAvailable,
    required super.targetLevel,
    required super.estimatedCostPerPerson,
    super.message,
    required super.status,
    required super.createdAt,
    super.hostName,
    super.venueName,
    super.courtName,
    super.sportType,
    super.bookingDate,
    super.bookingTime,
  });

  factory MatchmakingPostModel.fromJson(Map<String, dynamic> json) {
    final hostData = json['host'] as Map<String, dynamic>?;
    final hostName = hostData?['name'] as String?;

    final bookingData = json['bookings'] as Map<String, dynamic>?;
    final slotsList = bookingData?['booking_slots'] as List?;
    
    String? bookingDate;
    String? bookingTime;
    String? venueName;
    String? courtName;
    String? sportType;

    if (slotsList != null && slotsList.isNotEmpty) {
      final firstSlot = slotsList.first as Map<String, dynamic>;
      bookingDate = firstSlot['booking_date'] as String?;
      
      final courtData = firstSlot['courts'] as Map<String, dynamic>?;
      courtName = courtData?['name'] as String?;

      final venueData = courtData?['venues'] as Map<String, dynamic>?;
      venueName = venueData?['name'] as String?;
      sportType = venueData?['sports_type'] as String?;

      final List<int> indices = slotsList
          .map((s) => s['slot_index'] as int? ?? 0)
          .toList()
          ..sort();
      bookingTime = _formatIndicesToTimeRange(indices);
    }

    return MatchmakingPostModel(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      hostId: json['host_id'] as String? ?? '',
      slotsNeeded: json['slots_needed'] as int? ?? 1,
      slotsAvailable: json['slots_available'] as int? ?? 1,
      targetLevel: json['target_level'] as String? ?? 'Intermediate',
      estimatedCostPerPerson: (json['estimated_cost_per_person'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'open',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      hostName: hostName,
      venueName: venueName,
      courtName: courtName,
      sportType: sportType,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
    );
  }

  static String _formatIndicesToTimeRange(List<int> indices) {
    if (indices.isEmpty) return '';
    const startHour = 6; // Giờ mở cửa mặc định của các sân
    final startIdx = indices.first;
    final endIdx = indices.last;

    final startMinutesTotal = startHour * 60 + startIdx * 30;
    final endMinutesTotal = startHour * 60 + (endIdx + 1) * 30;

    final startH = startMinutesTotal ~/ 60;
    final startM = startMinutesTotal % 60;
    final endH = endMinutesTotal ~/ 60;
    final endM = endMinutesTotal % 60;

    final startStr = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
    final endStr = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
    
    return '$startStr - $endStr';
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'booking_id': bookingId,
      'host_id': hostId,
      'slots_needed': slotsNeeded,
      'slots_available': slotsAvailable,
      'target_level': targetLevel,
      'estimated_cost_per_person': estimatedCostPerPerson,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
