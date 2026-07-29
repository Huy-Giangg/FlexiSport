import 'package:flexisport_app/features/booking/domain/entities/court_block_entity.dart';
import 'package:flexisport_app/features/booking/domain/respositories/booking_repository.dart';

class GetCourtBlocksUsecase {
  final BookingRepository repository;

  GetCourtBlocksUsecase(this.repository);

  Future<List<CourtBlockEntity>> call(String venueId, String date) async {
    return await repository.getCourtBlocks(venueId, date);
  }
}
