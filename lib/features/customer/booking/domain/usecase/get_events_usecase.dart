import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

class GetEventsUsecase {
  final BookingRepository repository;

  GetEventsUsecase(this.repository);

  Future<List<EventEntity>> call(String venueId) async {
    return await repository.getEvents(venueId);
  }

  Future<int> getBookedCount(String eventId) async {
    return await repository.getBookedTicketsCount(eventId);
  }
}
