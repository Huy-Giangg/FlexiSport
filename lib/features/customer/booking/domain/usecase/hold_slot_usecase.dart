import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

class HoldSlotUsecase {
  final BookingRepository repository;

  HoldSlotUsecase(this.repository);

  Future<bool> call({
    required String courtId,
    required int slotIndex,
    required String date,
    required String userId,
    String? lockToken,
  }) {
    return repository.holdSlot(courtId, slotIndex, date, userId, lockToken: lockToken);
  }

  Future<Map<String, dynamic>> verifyAndHoldSlotsBatch({
    required List<Map<String, dynamic>> slots,
    String? lockToken,
    int durationMinutes = 10,
  }) {
    return repository.verifyAndHoldSlotsBatch(
      slots,
      lockToken: lockToken,
      durationMinutes: durationMinutes,
    );
  }
}
