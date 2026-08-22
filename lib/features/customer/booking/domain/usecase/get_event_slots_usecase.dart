import 'package:flexisport_app/features/customer/booking/domain/entities/event_slot_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

class GetEventSlotsUsecase {
  final BookingRepository repository;

  GetEventSlotsUsecase(this.repository);

  Future<List<EventSlotEntity>> call(String venueId, String date) async {
    return await repository.getEventSlots(venueId, date);
  }
}
