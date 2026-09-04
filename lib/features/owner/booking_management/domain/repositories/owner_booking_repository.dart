import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';

abstract class OwnerBookingRepository {
  Future<List<OwnerBookingEntity>> getOwnerBookings({
    required String venueId,
    String? date,
    String? status,
  });

  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
    String? cancellationReason,
  });

  Future<void> updatePaymentStatus({
    required String bookingId,
    required String newPaymentStatus,
  });

  Future<OwnerBookingEntity> createWalkInBooking({
    required String venueId,
    required String courtId,
    required String bookingDate,
    required List<int> slotIndexes,
    required String customerName,
    required String customerPhone,
    required double totalPrice,
    required double depositAmount,
    String? notes,
  });

  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
  });
}
