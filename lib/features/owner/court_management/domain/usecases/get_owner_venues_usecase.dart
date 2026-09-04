import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class GetOwnerVenuesUseCase {
  final OwnerCourtRepository repository;
  GetOwnerVenuesUseCase(this.repository);

  Future<List<OwnerVenueEntity>> call() async {
    return await repository.getOwnerVenues();
  }
}
