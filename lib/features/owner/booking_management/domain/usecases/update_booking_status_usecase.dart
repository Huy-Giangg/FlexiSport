import 'package:flexisport_app/features/owner/booking_management/domain/repositories/owner_booking_repository.dart';

class UpdateBookingStatusUseCase {
  final OwnerBookingRepository repository;
  UpdateBookingStatusUseCase(this.repository);

  Future<void> call({
    required String bookingId,
    required String newStatus,
    String? cancellationReason,
  }) async {
    await repository.updateBookingStatus(
      bookingId: bookingId,
      newStatus: newStatus,
      cancellationReason: cancellationReason,
    );
  }
}
