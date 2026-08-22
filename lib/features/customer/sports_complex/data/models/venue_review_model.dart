import 'package:flexisport_app/features/customer/sports_complex/domain/entities/venue_review_entity.dart';

class VenueReviewModel extends VenueReviewEntity {
  VenueReviewModel({
    required super.id,
    required super.bookingId,
    required super.venueId,
    required super.userId,
    required super.rating,
    required super.content,
    required super.createdAt,
    required super.userName,
  });

  factory VenueReviewModel.fromJson(Map<String, dynamic> json) {
    final rawProfiles = json['profiles'];
    String name = 'Người dùng';
    if (rawProfiles is Map) {
      name = rawProfiles['name']?.toString() ?? 'Người dùng';
    } else if (rawProfiles is List && rawProfiles.isNotEmpty) {
      final firstProfile = rawProfiles.first;
      if (firstProfile is Map) {
        name = firstProfile['name']?.toString() ?? 'Người dùng';
      }
    }

    return VenueReviewModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      venueId: json['venue_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      userName: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'venue_id': venueId,
      'user_id': userId,
      'rating': rating,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
