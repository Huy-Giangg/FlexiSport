import 'package:flexisport_app/features/customer/booking/domain/entities/booking_slot_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

class GetBookedSlotsUsecase {
  final BookingRepository repository;

  GetBookedSlotsUsecase(this.repository);

  Future<List<BookingSlotEntity>> call(String venueId, String date) async {
    return await repository.getBookedSlots(venueId, date);
  }
}
