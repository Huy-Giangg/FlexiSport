import 'package:flexisport_app/features/customer/booking/data/datasources/booking_remote_datasource.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_lock_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/booking_slot_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_block_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_slot_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_booking_entity.dart';
import 'package:flexisport_app/features/customer/booking/data/models/event_model.dart';
import 'package:flexisport_app/features/customer/booking/data/models/event_booking_model.dart';
import 'package:flexisport_app/features/customer/booking/domain/respositories/booking_repository.dart';

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
  Future<List<BookingSlotEntity>> getBookedSlots(String venueId, String date) async {
    final list = await remoteDatasource.fetchBookedSlots(venueId, date);
    return list.map((json) {
      return BookingSlotEntity(
        id: json['id']?.toString() ?? '',
        bookingId: json['booking_id']?.toString() ?? '',
        courtId: json['court_id']?.toString() ?? '',
        bookingDate: json['booking_date']?.toString() ?? '',
        slotIndex: json['slot_index'] as int? ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<CourtBlockEntity>> getCourtBlocks(String venueId, String date) async {
    final list = await remoteDatasource.fetchCourtBlocks(venueId, date);
    return list.map((json) {
      return CourtBlockEntity(
        id: json['id']?.toString() ?? '',
        courtId: json['court_id']?.toString() ?? '',
        blockDate: json['block_date']?.toString() ?? '',
        slotIndex: json['slot_index'] as int? ?? 0,
        reason: json['reason']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<List<EventSlotEntity>> getEventSlots(String venueId, String date) async {
    final list = await remoteDatasource.fetchEventSlots(venueId, date);
    return list.map((json) {
      return EventSlotEntity(
        id: json['id']?.toString() ?? '',
        eventId: json['event_id']?.toString() ?? '',
        courtId: json['court_id']?.toString() ?? '',
        eventDate: json['event_date']?.toString() ?? '',
        slotIndex: json['slot_index'] as int? ?? 0,
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

  @override
  Future<List<EventEntity>> getEvents(String venueId) async {
    final list = await remoteDatasource.fetchEvents(venueId);
    return list.map((json) => EventModel.fromJson(json)).toList();
  }

  @override
  Future<int> getBookedTicketsCount(String eventId) async {
    return await remoteDatasource.fetchBookedTicketsCount(eventId);
  }

  @override
  Future<EventBookingEntity> bookEvent(Map<String, dynamic> bookingData) async {
    final response = await remoteDatasource.insertEventBooking(bookingData);
    return EventBookingModel.fromJson(response);
  }

  @override
  Future<void> updateEventBookingStatus(String bookingId, String status) async {
    await remoteDatasource.updateEventBookingStatus(bookingId, status);
  }

  @override
  Future<List<EventBookingEntity>> getUserEventBookings(String userId) async {
    final list = await remoteDatasource.fetchUserEventBookings(userId);
    return list.map((json) => EventBookingModel.fromJson(json)).toList();
  }

  @override
  Future<List<EventBookingEntity>> getGuestEventBookings(List<String> bookingIds) async {
    final list = await remoteDatasource.fetchGuestEventBookings(bookingIds);
    return list.map((json) => EventBookingModel.fromJson(json)).toList();
  }
}