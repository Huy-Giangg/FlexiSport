
import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/sports_complex/domain/repositories/sports_complex_repository.dart';

class GetSportsComplexUsecase {
  final SportsComplexRepository repository;

  GetSportsComplexUsecase(this.repository);

  Future<List<SportsComplexEntity>> call() async {
    return await repository.getStadiums();
  }
}