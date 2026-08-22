import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

class HoldSlotUsecase {
  final BookingRepository repository;

  HoldSlotUsecase(this.repository);

  Future<bool> call({
    required String courtId,
    required int slotIndex,
    required String date,
    required String userId,
  }) {
    return repository.holdSlot(courtId, slotIndex, date, userId);
  }
}
