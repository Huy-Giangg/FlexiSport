import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class AddCourtUseCase {
  final OwnerCourtRepository repository;
  AddCourtUseCase(this.repository);

  Future<OwnerCourtEntity> call({
    required String venueId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  }) async {
    return await repository.addCourt(
      venueId: venueId,
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
