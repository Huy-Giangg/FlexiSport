import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class DeleteVenueUseCase {
  final OwnerCourtRepository repository;

  DeleteVenueUseCase(this.repository);

  Future<bool> call(String venueId) async {
    return await repository.deleteVenue(venueId);
  }
}
