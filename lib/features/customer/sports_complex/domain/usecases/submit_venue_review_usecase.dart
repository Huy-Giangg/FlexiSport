import '../repositories/sports_complex_repository.dart';

class SubmitVenueReviewUsecase {
  final SportsComplexRepository repository;
  SubmitVenueReviewUsecase(this.repository);

  Future<void> call({
    required String bookingId,
    required String venueId,
    required String userId,
    required double rating,
    required String content,
  }) async {
    await repository.submitVenueReview(
      bookingId: bookingId,
      venueId: venueId,
      userId: userId,
      rating: rating,
      content: content,
    );
  }
}
