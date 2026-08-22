
import 'package:flexisport_app/features/customer/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_lock_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/booking_slot_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_block_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_slot_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_booking_entity.dart';

abstract class BookingRepository {
  Future<List<CourtEntity>> getCourts(String venueId);
  Future<List<CourtLockEntity>> getActiveLocks(String venueId, String date);
  Future<List<BookingSlotEntity>> getBookedSlots(String venueId, String date);
  Future<List<CourtBlockEntity>> getCourtBlocks(String venueId, String date);
  Future<List<EventSlotEntity>> getEventSlots(String venueId, String date);
  Future<bool> holdSlot(String courtId, int slotIndex, String date, String userId);
  Future<void> releaseSlot(String courtId, int slotIndex, String date, String userId);
  Future<void> releaseAllUserLocks(String userId);
  
  Future<List<EventEntity>> getEvents(String venueId);
  Future<int> getBookedTicketsCount(String eventId);
  Future<EventBookingEntity> bookEvent(Map<String, dynamic> bookingData);
  Future<void> updateEventBookingStatus(String bookingId, String status);
  Future<List<EventBookingEntity>> getUserEventBookings(String userId);
  Future<List<EventBookingEntity>> getGuestEventBookings(List<String> bookingIds);
}