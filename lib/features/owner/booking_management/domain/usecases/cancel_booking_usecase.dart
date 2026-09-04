import 'package:flexisport_app/features/owner/booking_management/domain/repositories/owner_booking_repository.dart';

class CancelBookingUseCase {
  final OwnerBookingRepository repository;
  CancelBookingUseCase(this.repository);

  Future<void> call({
    required String bookingId,
    required String reason,
  }) async {
    await repository.cancelBooking(
      bookingId: bookingId,
      reason: reason,
    );
  }
}
