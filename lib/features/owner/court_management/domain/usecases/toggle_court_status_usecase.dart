import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class ToggleCourtStatusUseCase {
  final OwnerCourtRepository repository;
  ToggleCourtStatusUseCase(this.repository);

  Future<void> call({
    required String courtId,
    required String venueId,
    required bool isActive,
    String? reason,
  }) async {
    await repository.toggleCourtStatus(
      courtId: courtId,
      venueId: venueId,
      isActive: isActive,
      reason: reason,
    );
  }
}
