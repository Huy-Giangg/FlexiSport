import 'package:flexisport_app/features/booking/domain/entities/court_lock_entity.dart';
import 'package:flexisport_app/features/booking/domain/respositories/booking_repository.dart';

class GetActiveLocksUsecase {
  final BookingRepository repository;

  GetActiveLocksUsecase(this.repository);

  Future<List<CourtLockEntity>> call(String venueId, String date) {
    return repository.getActiveLocks(venueId, date);
  }
}
