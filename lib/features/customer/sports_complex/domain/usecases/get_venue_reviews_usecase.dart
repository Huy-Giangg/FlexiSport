import '../entities/venue_review_entity.dart';
import '../repositories/sports_complex_repository.dart';

class GetVenueReviewsUsecase {
  final SportsComplexRepository repository;
  GetVenueReviewsUsecase(this.repository);

  Future<List<VenueReviewEntity>> call(String venueId) async {
    return await repository.getVenueReviews(venueId);
  }
}
