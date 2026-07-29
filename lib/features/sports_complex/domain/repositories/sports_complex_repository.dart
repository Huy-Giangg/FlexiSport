

import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/venue_images_entity.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/venue_review_entity.dart';

abstract class SportsComplexRepository {
  Future<List<SportsComplexEntity>> getStadiums();
  Future<List<VenueImageEntity>> getStadiumImages(String stadiumId);
  Future<List<VenueReviewEntity>> getVenueReviews(String venueId);
  Future<void> submitVenueReview({
    required String bookingId,
    required String venueId,
    required String userId,
    required double rating,
    required String content,
  });
}