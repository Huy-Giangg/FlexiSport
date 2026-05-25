
import 'package:flexisport_app/features/sports_complex/data/datasources/sports_complex_remote_datasource.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/venue_images_entity.dart';
import 'package:flexisport_app/features/sports_complex/domain/repositories/sports_complex_repository.dart';

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
}