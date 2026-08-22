import 'package:flexisport_app/features/customer/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_lock_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/booking_slot_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_block_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_slot_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_booking_entity.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_courts_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/hold_slot_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/release_slot_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_active_locks_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_booked_slots_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_court_blocks_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_event_slots_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_events_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/book_event_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_user_event_bookings_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:flexisport_app/core/services/notification_service.dart';

class BookingProvider extends ChangeNotifier {
  final GetCourtsUsecase getCourtsUseCase;
  final HoldSlotUsecase holdSlotUseCase;
  final ReleaseSlotUsecase releaseSlotUseCase;
  final GetActiveLocksUsecase getActiveLocksUseCase;
  final GetBookedSlotsUsecase getBookedSlotsUseCase;
  final GetCourtBlocksUsecase getCourtBlocksUseCase;
  final GetEventSlotsUsecase getEventSlotsUseCase;
  final GetEventsUsecase getEventsUseCase;
  final BookEventUsecase bookEventUseCase;
  final GetUserEventBookingsUsecase getUserEventBookingsUseCase;

  BookingProvider(
    this.getCourtsUseCase,
    this.holdSlotUseCase,
    this.releaseSlotUseCase,
    this.getActiveLocksUseCase,
    this.getBookedSlotsUseCase,
    this.getCourtBlocksUseCase,
    this.getEventSlotsUseCase,
    this.getEventsUseCase,
    this.bookEventUseCase,
    this.getUserEventBookingsUseCase,
  );

  List<CourtEntity> _courts = [];
  List<CourtEntity> get courts => _courts;

  List<CourtLockEntity> _activeLocks = [];
  List<CourtLockEntity> get activeLocks => _activeLocks;

  List<BookingSlotEntity> _bookedSlots = [];
  List<BookingSlotEntity> get bookedSlots => _bookedSlots;

  List<CourtBlockEntity> _courtBlocks = [];
  List<CourtBlockEntity> get courtBlocks => _courtBlocks;

  List<EventSlotEntity> _eventSlots = [];
  List<EventSlotEntity> get eventSlots => _eventSlots;

  List<EventEntity> _events = [];
  List<EventEntity> get events => _events;

  List<EventBookingEntity> _eventBookings = [];
  List<EventBookingEntity> get eventBookings => _eventBookings;

  Map<String, int> _eventBookedTicketsCount = {};
  Map<String, int> get eventBookedTicketsCount => _eventBookedTicketsCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadCourts(String venueId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _courts = await getCourtsUseCase(venueId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveLocks(String venueId, String date) async {
    try {
      _activeLocks = await getActiveLocksUseCase(venueId, date);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading active locks: $e");
    }
  }

  Future<void> loadBookedSlots(String venueId, String date) async {
    try {
      _bookedSlots = await getBookedSlotsUseCase(venueId, date);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading booked slots: $e");
    }
  }

  Future<void> loadCourtBlocks(String venueId, String date) async {
    try {
      _courtBlocks = await getCourtBlocksUseCase(venueId, date);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading court blocks: $e");
    }
  }

  Future<void> loadEventSlots(String venueId, String date) async {
    try {
      _eventSlots = await getEventSlotsUseCase(venueId, date);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading event slots: $e");
    }
  }

  Future<bool> holdCourtSlot({
    required String venueId,
    required String courtId,
    required int slotIndex,
    required String date,
    required String userId,
  }) async {
    final success = await holdSlotUseCase(
      courtId: courtId,
      slotIndex: slotIndex,
      date: date,
      userId: userId,
    );
    if (success) {
      await loadActiveLocks(venueId, date);
    }
    return success;
  }

  Future<void> releaseCourtSlot({
    required String venueId,
    required String courtId,
    required int slotIndex,
    required String date,
    required String userId,
  }) async {
    await releaseSlotUseCase(
      courtId: courtId,
      slotIndex: slotIndex,
      date: date,
      userId: userId,
    );
    await loadActiveLocks(venueId, date);
  }

  Future<void> releaseAllUserLocks({
    required String venueId,
    required String date,
    required String userId,
  }) async {
    await releaseSlotUseCase.releaseAll(userId);
    await loadActiveLocks(venueId, date);
  }

  Future<void> loadEvents(String venueId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _events = await getEventsUseCase(venueId);
      
      // Load capacity details for each event
      final Map<String, int> ticketCounts = {};
      for (var e in _events) {
        final count = await getEventsUseCase.getBookedCount(e.id);
        ticketCounts[e.id] = count;
      }
      _eventBookedTicketsCount = ticketCounts;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EventBookingEntity> registerEvent(Map<String, dynamic> bookingData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final booking = await bookEventUseCase(bookingData);
      
      // Refresh count for the event
      final eventId = booking.eventId;
      final count = await getEventsUseCase.getBookedCount(eventId);
      _eventBookedTicketsCount[eventId] = count;
      
      // Lên lịch nhắc nhở lịch thi đấu cho vé sự kiện vừa đặt
      final userId = booking.userId;
      if (userId != null && userId.isNotEmpty) {
        NotificationService.instance.syncMatchReminders(userId);
      }

      return booking;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserEventBookings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _eventBookings = await getUserEventBookingsUseCase(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGuestEventBookings(List<String> bookingIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _eventBookings = await getUserEventBookingsUseCase.getGuestBookings(bookingIds);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEventBookingStatus({
    required String bookingId,
    required String status,
    String userId = '',
    List<String> guestIds = const [],
  }) async {
    try {
      await bookEventUseCase.updateStatus(bookingId, status);
      
      // Refresh user event bookings list
      if (userId.isNotEmpty) {
        await loadUserEventBookings(userId);
      } else if (guestIds.isNotEmpty) {
        await loadGuestEventBookings(guestIds);
      }
    } catch (e) {
      debugPrint("Error updating event booking status: $e");
    }
  }
}
