import 'package:flexisport_app/features/booking/domain/entities/event_booking_entity.dart';
import 'package:flexisport_app/features/booking/domain/respositories/booking_repository.dart';

class GetUserEventBookingsUsecase {
  final BookingRepository repository;

  GetUserEventBookingsUsecase(this.repository);

  Future<List<EventBookingEntity>> call(String userId) async {
    return await repository.getUserEventBookings(userId);
  }

  Future<List<EventBookingEntity>> getGuestBookings(List<String> bookingIds) async {
    return await repository.getGuestEventBookings(bookingIds);
  }
}
