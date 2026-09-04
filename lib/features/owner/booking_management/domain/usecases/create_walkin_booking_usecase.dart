import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/repositories/owner_booking_repository.dart';

class CreateWalkInBookingUseCase {
  final OwnerBookingRepository repository;
  CreateWalkInBookingUseCase(this.repository);

  Future<OwnerBookingEntity> call({
    required String venueId,
    required String courtId,
    required String bookingDate,
    required List<int> slotIndexes,
    required String customerName,
    required String customerPhone,
    required double totalPrice,
    required double depositAmount,
    String? notes,
  }) async {
    return await repository.createWalkInBooking(
      venueId: venueId,
      courtId: courtId,
      bookingDate: bookingDate,
      slotIndexes: slotIndexes,
      customerName: customerName,
      customerPhone: customerPhone,
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      notes: notes,
    );
  }
}
