import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class GetOwnerCourtsUseCase {
  final OwnerCourtRepository repository;
  GetOwnerCourtsUseCase(this.repository);

  Future<List<OwnerCourtEntity>> call(String venueId) async {
    return await repository.getCourtsByVenue(venueId);
  }
}
