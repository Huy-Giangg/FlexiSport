import 'package:image_picker/image_picker.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class AddVenueUseCase {
  final OwnerCourtRepository repository;

  AddVenueUseCase(this.repository);

  Future<OwnerVenueEntity> call({
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? logoUrl,
    XFile? imageFile,
  }) async {
    return await repository.addVenue(
      name: name,
      address: address,
      openTime: openTime,
      closeTime: closeTime,
      sportsType: sportsType,
      logoUrl: logoUrl,
      imageFile: imageFile,
    );
  }
}
