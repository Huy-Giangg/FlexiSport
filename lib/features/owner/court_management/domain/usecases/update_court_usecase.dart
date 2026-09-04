import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class UpdateCourtUseCase {
  final OwnerCourtRepository repository;
  UpdateCourtUseCase(this.repository);

  Future<OwnerCourtEntity> call({
    required String courtId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  }) async {
    return await repository.updateCourt(
      courtId: courtId,
      name: name,
      pricePerHour: pricePerHour,
      peakPrice: peakPrice,
      applyPeak: applyPeak,
      weekendSurcharge: weekendSurcharge,
      applyWeekend: applyWeekend,
      sportType: sportType,
    );
  }
}
