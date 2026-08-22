import 'package:flexisport_app/features/customer/booking/domain/entities/event_booking_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

class BookEventUsecase {
  final BookingRepository repository;

  BookEventUsecase(this.repository);

  Future<EventBookingEntity> call(Map<String, dynamic> bookingData) async {
    return await repository.bookEvent(bookingData);
  }

  Future<void> updateStatus(String bookingId, String status) async {
    await repository.updateEventBookingStatus(bookingId, status);
  }
}
