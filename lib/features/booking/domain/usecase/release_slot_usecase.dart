import 'package:flexisport_app/features/booking/domain/respositories/booking_repository.dart';

class ReleaseSlotUsecase {
  final BookingRepository repository;

  ReleaseSlotUsecase(this.repository);

  Future<void> call({
    required String courtId,
    required int slotIndex,
    required String date,
    required String userId,
  }) {
    return repository.releaseSlot(courtId, slotIndex, date, userId);
  }

  Future<void> releaseAll(String userId) {
    return repository.releaseAllUserLocks(userId);
  }
}
