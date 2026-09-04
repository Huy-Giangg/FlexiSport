import 'package:flexisport_app/features/owner/court_management/domain/entities/court_slot_status_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class GetCourtSlotsStatusUseCase {
  final OwnerCourtRepository repository;
  GetCourtSlotsStatusUseCase(this.repository);

  Future<List<CourtSlotStatusEntity>> call({
    required String courtId,
    required String venueId,
    required String date,
  }) async {
    return await repository.getCourtSlotsStatus(
      courtId: courtId,
      venueId: venueId,
      date: date,
    );
  }
}
