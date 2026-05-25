import 'package:flexisport_app/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:flexisport_app/features/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/booking/domain/entities/court_lock_entity.dart';
import 'package:flexisport_app/features/booking/domain/respositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository{
  final BookingRemoteDatasource remoteDatasource;

  BookingRepositoryImpl(this.remoteDatasource);

  @override
  Future<List<CourtEntity>> getCourts(String venueId) async{
    return await remoteDatasource.fetchCourts(venueId);
  }

  @override
  Future<List<CourtLockEntity>> getActiveLocks(String venueId, String date) async {
    final list = await remoteDatasource.fetchActiveLocks(venueId, date);
    return list.map((json) {
      return CourtLockEntity(
        id: json['id']?.toString() ?? '',
        courtId: json['court_id']?.toString() ?? '',
        slotIndex: json['slot_index'] as int? ?? 0,
        bookingDate: json['booking_date']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        lockedUntil: json['locked_until'] != null 
            ? DateTime.parse(json['locked_until']) 
            : DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<bool> holdSlot(String courtId, int slotIndex, String date, String userId) async {
    return await remoteDatasource.insertLock(courtId, slotIndex, date, userId);
  }

  @override
  Future<void> releaseSlot(String courtId, int slotIndex, String date, String userId) async {
    await remoteDatasource.deleteLock(courtId, slotIndex, date, userId);
  }

  @override
  Future<void> releaseAllUserLocks(String userId) async {
    await remoteDatasource.deleteAllUserLocks(userId);
  }
}