import 'package:flexisport_app/features/owner/booking_management/domain/repositories/owner_booking_repository.dart';

class UpdatePaymentStatusUseCase {
  final OwnerBookingRepository repository;
  UpdatePaymentStatusUseCase(this.repository);

  Future<void> call({
    required String bookingId,
    required String newPaymentStatus,
  }) async {
    await repository.updatePaymentStatus(
      bookingId: bookingId,
      newPaymentStatus: newPaymentStatus,
    );
  }
}
