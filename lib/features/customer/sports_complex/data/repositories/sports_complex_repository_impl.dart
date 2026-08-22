
import 'package:flexisport_app/features/customer/sports_complex/data/datasources/sports_complex_remote_datasource.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/venue_images_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/venue_review_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/repositories/sports_complex_repository.dart';

class SportsComplexRepositoryImpl implements SportsComplexRepository{
  final SportsComplexRemoteDatasource remoteDataSource;

  SportsComplexRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<SportsComplexEntity>> getStadiums() async {
    return await remoteDataSource.getStadiums();
  }

  @override
  Future<List<VenueImageEntity>> getStadiumImages(String stadiumId) async {
    return await remoteDataSource.getStadiumImages(stadiumId);
  }

  @override
  Future<List<VenueReviewEntity>> getVenueReviews(String venueId) async {
    return await remoteDataSource.getVenueReviews(venueId);
  }

  @override
  Future<void> submitVenueReview({
    required String bookingId,
    required String venueId,
    required String userId,
    required double rating,
    required String content,
  }) async {
    await remoteDataSource.submitVenueReview(
      bookingId: bookingId,
      venueId: venueId,
      userId: userId,
      rating: rating,
      content: content,
    );
  }
}