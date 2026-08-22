
import 'package:flexisport_app/features/customer/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

class GetCourtsUsecase {
  final BookingRepository repository;

  GetCourtsUsecase(this.repository);

  Future<List<CourtEntity>> call(String venueId){
    return repository.getCourts(venueId);
  }
}