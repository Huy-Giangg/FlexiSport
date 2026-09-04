import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class BlockCourtSlotUseCase {
  final OwnerCourtRepository repository;
  BlockCourtSlotUseCase(this.repository);

  Future<void> call({
    required String courtId,
    required String date,
    required int slotIndex,
    required String reason,
  }) async {
    await repository.blockCourtSlot(
      courtId: courtId,
      date: date,
      slotIndex: slotIndex,
      reason: reason,
    );
  }
}
