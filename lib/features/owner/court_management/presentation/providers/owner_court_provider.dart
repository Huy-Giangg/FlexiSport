import 'package:flexisport_app/features/owner/court_management/domain/entities/court_slot_status_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/add_court_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/add_venue_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/block_court_slot_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/delete_court_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/delete_venue_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/get_court_slots_status_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/get_owner_courts_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/get_owner_venues_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/toggle_court_status_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/unblock_court_slot_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/update_court_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/update_venue_info_usecase.dart';
import 'package:flutter/foundation.dart';

class OwnerCourtProvider extends ChangeNotifier {
  final GetOwnerVenuesUseCase getOwnerVenuesUseCase;
  final AddVenueUseCase addVenueUseCase;
  final DeleteVenueUseCase deleteVenueUseCase;
  final GetOwnerCourtsUseCase getOwnerCourtsUseCase;
  final AddCourtUseCase addCourtUseCase;
  final UpdateCourtUseCase updateCourtUseCase;
  final DeleteCourtUseCase deleteCourtUseCase;
  final ToggleCourtStatusUseCase toggleCourtStatusUseCase;
  final GetCourtSlotsStatusUseCase getCourtSlotsStatusUseCase;
  final BlockCourtSlotUseCase blockCourtSlotUseCase;
  final UnblockCourtSlotUseCase unblockCourtSlotUseCase;
  final UpdateVenueInfoUseCase updateVenueInfoUseCase;

  OwnerCourtProvider({
    required this.getOwnerVenuesUseCase,
    required this.addVenueUseCase,
    required this.deleteVenueUseCase,
    required this.getOwnerCourtsUseCase,
    required this.addCourtUseCase,
    required this.updateCourtUseCase,
    required this.deleteCourtUseCase,
    required this.toggleCourtStatusUseCase,
    required this.getCourtSlotsStatusUseCase,
    required this.blockCourtSlotUseCase,
    required this.unblockCourtSlotUseCase,
    required this.updateVenueInfoUseCase,
  }) {
    loadData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  List<OwnerVenueEntity> _venues = [];
  List<OwnerVenueEntity> get venues => _venues;

  OwnerVenueEntity? _selectedVenue;
  OwnerVenueEntity? get selectedVenue => _selectedVenue;

  List<OwnerCourtEntity> _courts = [];
  List<OwnerCourtEntity> get courts => _courts;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _statusFilter = 'all'; // 'all', 'active', 'maintenance'
  String get statusFilter => _statusFilter;

  String? _sportFilter;
  String? get sportFilter => _sportFilter;

  // Schedule slot state
  OwnerCourtEntity? _activeCourtForSchedule;
  OwnerCourtEntity? get activeCourtForSchedule => _activeCourtForSchedule;

  DateTime _scheduleDate = DateTime.now();
  DateTime get scheduleDate => _scheduleDate;

  List<CourtSlotStatusEntity> _courtSlots = [];
  List<CourtSlotStatusEntity> get courtSlots => _courtSlots;

  bool _isLoadingSlots = false;
  bool get isLoadingSlots => _isLoadingSlots;

  // Filtered courts getter
  List<OwnerCourtEntity> get filteredCourts {
    return _courts.where((court) {
      // 1. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final nameMatch = court.name.toLowerCase().contains(q);
        final sportMatch = court.sportType?.toLowerCase().contains(q) ?? false;
        if (!nameMatch && !sportMatch) return false;
      }

      // 2. Status Filter
      if (_statusFilter == 'active' && !court.isActive) return false;
      if (_statusFilter == 'maintenance' && court.isActive) return false;

      // 3. Sport Filter
      if (_sportFilter != null && _sportFilter!.isNotEmpty && _sportFilter != 'Tất cả') {
        final q = _sportFilter!.toLowerCase();
        final cSport = court.sportType?.toLowerCase() ?? '';
        final cName = court.name.toLowerCase();
        final vSport = _selectedVenue?.sportsType?.toLowerCase() ?? '';

        final matches = cSport == q ||
            cSport.contains(q) ||
            q.contains(cSport) ||
            cName.contains(q) ||
            vSport == q ||
            vSport.contains(q) ||
            q.contains(vSport);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  // Summary Metrics
  int get totalCourtsCount => _courts.length;
  int get activeCourtsCount => _courts.where((c) => c.isActive).length;
  int get maintenanceCourtsCount => _courts.where((c) => !c.isActive).length;
  int get todayTotalBookings => _courts.fold(0, (sum, c) => sum + c.todayBookingsCount);

  // Available sports in current venue
  List<String> get availableSports {
    final set = <String>{'Tất cả'};
    if (_selectedVenue?.sportsType != null && _selectedVenue!.sportsType!.isNotEmpty) {
      set.add(_selectedVenue!.sportsType!);
    }
    for (final c in _courts) {
      if (c.sportType != null && c.sportType!.isNotEmpty) {
        set.add(c.sportType!);
      }
    }
    return set.toList();
  }

  // --- ACTIONS ---

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _venues = await getOwnerVenuesUseCase();
      if (_venues.isNotEmpty) {
        if (_selectedVenue == null || !_venues.any((v) => v.id == _selectedVenue!.id)) {
          _selectedVenue = _venues.first;
        }
        await _loadCourts();
      }
    } catch (e) {
      print("Lỗi loadData OwnerCourtProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectVenue(OwnerVenueEntity venue) async {
    _selectedVenue = venue;
    _searchQuery = '';
    _statusFilter = 'all';
    _sportFilter = null;
    notifyListeners();
    await _loadCourts();
  }

  Future<void> refreshCourts() async {
    await _loadCourts();
  }

  Future<void> _loadCourts() async {
    if (_selectedVenue == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await getOwnerCourtsUseCase(_selectedVenue!.id);
      _courts = List<OwnerCourtEntity>.from(fetched);
    } catch (e) {
      print("Lỗi loadCourts: $e");
      _courts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSportFilter(String? sport) {
    _sportFilter = sport;
    notifyListeners();
  }

  // Thêm sân mới
  Future<bool> addCourt({
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  }) async {
    if (_selectedVenue == null) return false;
    _isSaving = true;
    notifyListeners();

    try {
      final newCourt = await addCourtUseCase(
        venueId: _selectedVenue!.id,
        name: name,
        pricePerHour: pricePerHour,
        peakPrice: peakPrice,
        applyPeak: applyPeak,
        weekendSurcharge: weekendSurcharge,
        applyWeekend: applyWeekend,
        sportType: sportType ?? _selectedVenue!.sportsType,
      );
      _courts.insert(0, newCourt);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Lỗi addCourt: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Sửa sân
  Future<bool> updateCourt({
    required String courtId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final updatedCourt = await updateCourtUseCase(
        courtId: courtId,
        name: name,
        pricePerHour: pricePerHour,
        peakPrice: peakPrice,
        applyPeak: applyPeak,
        weekendSurcharge: weekendSurcharge,
        applyWeekend: applyWeekend,
        sportType: sportType,
      );

      final index = _courts.indexWhere((c) => c.id == courtId);
      if (index != -1) {
        _courts[index] = updatedCourt;
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Lỗi updateCourt: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Xóa sân
  Future<bool> deleteCourt(String courtId) async {
    try {
      await deleteCourtUseCase(courtId);
      _courts.removeWhere((c) => c.id == courtId);
      notifyListeners();
      return true;
    } catch (e) {
      print("Lỗi deleteCourt: $e");
      return false;
    }
  }

  // Bật/Tắt trạng thái hoạt động của sân
  Future<bool> toggleCourtActive(String courtId, {String? reason}) async {
    final index = _courts.indexWhere((c) => c.id == courtId);
    if (index == -1) return false;

    final current = _courts[index];
    final newStatus = !current.isActive;

    _courts[index] = current.copyWith(
      isActive: newStatus,
      todayBlockedCount: newStatus ? 0 : (current.todayBlockedCount > 0 ? current.todayBlockedCount : 1),
    );
    notifyListeners();

    try {
      await toggleCourtStatusUseCase(
        courtId: courtId,
        venueId: current.venueId.isNotEmpty ? current.venueId : (_selectedVenue?.id ?? ''),
        isActive: newStatus,
        reason: reason,
      );
      await _loadCourts();
      return true;
    } catch (e) {
      print("Lỗi toggleCourtStatus: $e");
      // Revert if error
      _courts[index] = current;
      notifyListeners();
      return false;
    }
  }

  // --- QUẢN LÝ LỊCH TRÌNH VÀ KHÓA Ô GIỜ SÂN (SLOT SCHEDULE) ---

  Future<void> loadCourtSchedule(OwnerCourtEntity court, {DateTime? date}) async {
    _activeCourtForSchedule = court;
    if (date != null) {
      _scheduleDate = date;
    }
    _isLoadingSlots = true;
    notifyListeners();

    final dateStr = _formatDate(_scheduleDate);
    try {
      _courtSlots = await getCourtSlotsStatusUseCase(
        courtId: court.id,
        venueId: court.venueId.isNotEmpty ? court.venueId : (_selectedVenue?.id ?? ''),
        date: dateStr,
      );
    } catch (e) {
      print("Lỗi loadCourtSchedule: $e");
      _courtSlots = [];
    } finally {
      _isLoadingSlots = false;
      notifyListeners();
    }
  }

  Future<void> changeScheduleDate(DateTime date) async {
    if (_activeCourtForSchedule == null) return;
    await loadCourtSchedule(_activeCourtForSchedule!, date: date);
  }

  Future<bool> blockSlot({
    required int slotIndex,
    required String reason,
  }) async {
    if (_activeCourtForSchedule == null) return false;

    final dateStr = _formatDate(_scheduleDate);
    try {
      await blockCourtSlotUseCase(
        courtId: _activeCourtForSchedule!.id,
        date: dateStr,
        slotIndex: slotIndex,
        reason: reason,
      );
      // Reload schedule
      await loadCourtSchedule(_activeCourtForSchedule!);
      return true;
    } catch (e) {
      print("Lỗi blockSlot: $e");
      return false;
    }
  }

  Future<bool> unblockSlot(String blockId) async {
    if (_activeCourtForSchedule == null) return false;

    try {
      await unblockCourtSlotUseCase(blockId);
      // Reload schedule
      await loadCourtSchedule(_activeCourtForSchedule!);
      return true;
    } catch (e) {
      print("Lỗi unblockSlot: $e");
      return false;
    }
  }

  // Thiết lập chế độ bảo trì sân đa dạng (theo khung giờ, cả ngày, vô thời hạn, hoặc mở lại)
  Future<bool> setCourtMaintenance({
    required String courtId,
    required String venueId,
    required String date,
    required String mode, // 'custom_range', 'all_day', 'indefinite', 'release'
    List<int>? slotIndices,
    String? reason,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final effectiveVenueId = venueId.isNotEmpty ? venueId : (_selectedVenue?.id ?? '');
      final effectiveReason = reason?.trim().isNotEmpty == true ? reason!.trim() : 'Bảo trì kỹ thuật';

      if (mode == 'release') {
        // Mở lại sân hoạt động
        await toggleCourtStatusUseCase(
          courtId: courtId,
          venueId: effectiveVenueId,
          isActive: true,
        );
      } else if (mode == 'indefinite') {
        // Đóng sân vô thời hạn
        await toggleCourtStatusUseCase(
          courtId: courtId,
          venueId: effectiveVenueId,
          isActive: false,
          reason: effectiveReason,
        );
      } else if (mode == 'all_day') {
        // Khóa tất cả các slot trong ngày
        final slots = await getCourtSlotsStatusUseCase(
          courtId: courtId,
          venueId: effectiveVenueId,
          date: date,
        );
        for (final slot in slots) {
          if (!slot.isBooked) {
            await blockCourtSlotUseCase(
              courtId: courtId,
              date: date,
              slotIndex: slot.slotIndex,
              reason: effectiveReason,
            );
          }
        }
      } else if (mode == 'custom_range') {
        // Khóa các slot cụ thể đã chọn
        if (slotIndices != null && slotIndices.isNotEmpty) {
          for (final idx in slotIndices) {
            await blockCourtSlotUseCase(
              courtId: courtId,
              date: date,
              slotIndex: idx,
              reason: effectiveReason,
            );
          }
        }
      }

      await _loadCourts();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Lỗi setCourtMaintenance: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Cập nhật thông tin cơ sở
  Future<bool> updateVenueInfo({
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? bankName,
    String? accountNumber,
  }) async {
    if (_selectedVenue == null) return false;
    _isSaving = true;
    notifyListeners();

    try {
      await updateVenueInfoUseCase(
        venueId: _selectedVenue!.id,
        name: name,
        address: address,
        openTime: openTime,
        closeTime: closeTime,
        sportsType: sportsType,
        bankName: bankName,
        accountNumber: accountNumber,
      );

      _selectedVenue = _selectedVenue!.copyWith(
        name: name,
        address: address,
        openTime: openTime,
        closeTime: closeTime,
        sportsType: sportsType,
        bankName: bankName,
        accountNumber: accountNumber,
      );

      // Cập nhật trong danh sách venues
      final idx = _venues.indexWhere((v) => v.id == _selectedVenue!.id);
      if (idx != -1) {
        _venues[idx] = _selectedVenue!;
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Lỗi updateVenueInfo: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Thêm cơ sở cụm sân mới
  Future<bool> addVenue({
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? logoUrl,
    dynamic imageFile, // XFile
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final newVenue = await addVenueUseCase(
        name: name,
        address: address,
        openTime: openTime,
        closeTime: closeTime,
        sportsType: sportsType,
        logoUrl: logoUrl,
        imageFile: imageFile,
      );

      _venues.insert(0, newVenue);
      _selectedVenue = newVenue;
      _searchQuery = '';
      _statusFilter = 'all';
      _sportFilter = null;
      _isSaving = false;
      notifyListeners();

      // Tải lại danh sách sân con cho venue mới (ban đầu = 0)
      await _loadCourts();
      return true;
    } catch (e) {
      print("Lỗi addVenue trong Provider: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Xóa cụm sân / cơ sở
  Future<bool> deleteVenue(String venueId) async {
    _isSaving = true;
    notifyListeners();

    try {
      final success = await deleteVenueUseCase(venueId);
      if (success) {
        _venues.removeWhere((v) => v.id == venueId);
        if (_selectedVenue?.id == venueId) {
          _selectedVenue = _venues.isNotEmpty ? _venues.first : null;
        }
        _isSaving = false;
        notifyListeners();
        if (_selectedVenue != null) {
          await _loadCourts();
        } else {
          _courts = [];
          notifyListeners();
        }
        return true;
      }
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      print("Lỗi deleteVenue trong Provider: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Đặt trạng thái đồng loạt cho tất cả các sân con (bảo trì hoặc hoạt động)
  Future<bool> setAllCourtsStatus(bool setToActive) async {
    if (_courts.isEmpty) return true;
    _isSaving = true;
    notifyListeners();

    try {
      for (final court in List<OwnerCourtEntity>.from(_courts)) {
        if (court.isActive != setToActive) {
          await toggleCourtActive(court.id);
        }
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Lỗi setAllCourtsStatus: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }
}
