import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class DeleteCourtUseCase {
  final OwnerCourtRepository repository;
  DeleteCourtUseCase(this.repository);

  Future<void> call(String courtId) async {
    await repository.deleteCourt(courtId);
  }
}
