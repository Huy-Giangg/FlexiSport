

import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/venue_images_entity.dart';
abstract class SportsComplexRepository {
  Future<List<SportsComplexEntity>> getStadiums();
  Future<List<VenueImageEntity>> getStadiumImages(String stadiumId);
}