import 'package:flexisport_app/features/booking/domain/entities/court_entity.dart';
import 'package:flexisport_app/features/booking/domain/entities/court_lock_entity.dart';
import 'package:flexisport_app/features/booking/domain/usecase/get_courts_usecase.dart';
import 'package:flexisport_app/features/booking/domain/usecase/hold_slot_usecase.dart';
import 'package:flexisport_app/features/booking/domain/usecase/release_slot_usecase.dart';
import 'package:flexisport_app/features/booking/domain/usecase/get_active_locks_usecase.dart';
import 'package:flutter/foundation.dart';

class BookingProvider extends ChangeNotifier {
  final GetCourtsUsecase getCourtsUseCase;
  final HoldSlotUsecase holdSlotUseCase;
  final ReleaseSlotUsecase releaseSlotUseCase;
  final GetActiveLocksUsecase getActiveLocksUseCase;

  BookingProvider(
    this.getCourtsUseCase,
    this.holdSlotUseCase,
    this.releaseSlotUseCase,
    this.getActiveLocksUseCase,
  );

  List<CourtEntity> _courts = [];
  List<CourtEntity> get courts => _courts;

  List<CourtLockEntity> _activeLocks = [];
  List<CourtLockEntity> get activeLocks => _activeLocks;

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
}
