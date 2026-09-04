import 'package:flexisport_app/features/owner/booking_management/data/datasources/owner_booking_remote_datasource.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/repositories/owner_booking_repository.dart';

class OwnerBookingRepositoryImpl implements OwnerBookingRepository {
  final OwnerBookingRemoteDataSource remoteDataSource;

  OwnerBookingRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<OwnerBookingEntity>> getOwnerBookings({
    required String venueId,
    String? date,
    String? status,
  }) async {
    final list = await remoteDataSource.fetchOwnerBookings(
      venueId: venueId,
      date: date,
      status: status,
    );
    return List<OwnerBookingEntity>.from(list);
  }

  @override
  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
    String? cancellationReason,
  }) async {
    await remoteDataSource.updateBookingStatus(
      bookingId: bookingId,
      newStatus: newStatus,
      cancellationReason: cancellationReason,
    );
  }

  @override
  Future<void> updatePaymentStatus({
    required String bookingId,
    required String newPaymentStatus,
  }) async {
    await remoteDataSource.updatePaymentStatus(
      bookingId: bookingId,
      newPaymentStatus: newPaymentStatus,
    );
  }

  @override
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
  }) async {
    return await remoteDataSource.createWalkInBooking(
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

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    await remoteDataSource.cancelBooking(
      bookingId: bookingId,
      reason: reason,
    );
  }
}
