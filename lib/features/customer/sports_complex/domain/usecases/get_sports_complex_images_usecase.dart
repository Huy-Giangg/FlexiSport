import 'package:flexisport_app/features/customer/sports_complex/domain/entities/venue_images_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/repositories/sports_complex_repository.dart';

class GetSportsComplexImagesUsecase {
  final SportsComplexRepository repository;

  GetSportsComplexImagesUsecase(this.repository);

  Future<List<VenueImageEntity>> call(String stadiumId) async {
    return await repository.getStadiumImages(stadiumId);
  }
}
