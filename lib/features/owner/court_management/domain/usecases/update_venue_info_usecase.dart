import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class UpdateVenueInfoUseCase {
  final OwnerCourtRepository repository;
  UpdateVenueInfoUseCase(this.repository);

  Future<void> call({
    required String venueId,
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? bankName,
    String? accountNumber,
  }) async {
    await repository.updateVenueInfo(
      venueId: venueId,
      name: name,
      address: address,
      openTime: openTime,
      closeTime: closeTime,
      sportsType: sportsType,
      bankName: bankName,
      accountNumber: accountNumber,
    );
  }
}
