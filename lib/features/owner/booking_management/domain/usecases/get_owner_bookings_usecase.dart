import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/repositories/owner_booking_repository.dart';

class GetOwnerBookingsUseCase {
  final OwnerBookingRepository repository;
  GetOwnerBookingsUseCase(this.repository);

  Future<List<OwnerBookingEntity>> call({
    required String venueId,
    String? date,
    String? status,
  }) async {
    return await repository.getOwnerBookings(
      venueId: venueId,
      date: date,
      status: status,
    );
  }
}
