import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class UnblockCourtSlotUseCase {
  final OwnerCourtRepository repository;
  UnblockCourtSlotUseCase(this.repository);

  Future<void> call(String blockId) async {
    await repository.unblockCourtSlot(blockId);
  }
}
