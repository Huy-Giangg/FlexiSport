import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

class ReleaseSlotUsecase {
  final BookingRepository repository;

  ReleaseSlotUsecase(this.repository);

  Future<void> call({
    required String courtId,
    required int slotIndex,
    required String date,
    required String userId,
    String? lockToken,
  }) {
    return repository.releaseSlot(courtId, slotIndex, date, userId, lockToken: lockToken);
  }

  Future<void> releaseAll(String userId, {String? lockToken}) {
    return repository.releaseAllUserLocks(userId, lockToken: lockToken);
  }
}
