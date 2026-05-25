
import 'package:flexisport_app/features/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/booking/domain/entities/court_lock_entity.dart';

abstract class BookingRepository {
  Future<List<CourtEntity>> getCourts(String venueId);
  Future<List<CourtLockEntity>> getActiveLocks(String venueId, String date);
  Future<bool> holdSlot(String courtId, int slotIndex, String date, String userId);
  Future<void> releaseSlot(String courtId, int slotIndex, String date, String userId);
  Future<void> releaseAllUserLocks(String userId);
}