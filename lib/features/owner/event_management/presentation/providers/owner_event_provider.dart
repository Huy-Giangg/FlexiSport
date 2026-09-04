import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/event_management/data/datasources/owner_event_remote_datasource.dart';
import 'package:flexisport_app/features/owner/event_management/domain/entities/owner_event_attendee_entity.dart';
import 'package:flexisport_app/features/owner/event_management/domain/entities/owner_event_entity.dart';

class OwnerEventProvider extends ChangeNotifier {
  final OwnerEventRemoteDataSource remoteDataSource;

  OwnerEventProvider({required this.remoteDataSource});

  List<OwnerEventEntity> _events = [];
  List<OwnerEventAttendeeEntity> _attendees = [];
  bool _isLoading = false;
  bool _isLoadingAttendees = false;
  bool _isSaving = false;

  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'upcoming', 'past', 'inactive'
  String? _sportFilter; // null or 'Tất cả' or specific sport
  OwnerVenueEntity? _selectedVenue;

  List<OwnerEventEntity> get events => _events;
  List<OwnerEventAttendeeEntity> get attendees => _attendees;
  bool get isLoading => _isLoading;
  bool get isLoadingAttendees => _isLoadingAttendees;
  bool get isSaving => _isSaving;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String? get sportFilter => _sportFilter;
  OwnerVenueEntity? get selectedVenue => _selectedVenue;

  // Tổng hợp metrics
  int get totalEventsCount => _events.length;
  int get activeEventsCount => _events.where((e) => e.isActive && !e.hasPassed).length;
  int get totalSoldTickets => _events.fold(0, (sum, e) => sum + e.bookedTicketsCount);
  double get totalRevenue => _events.fold(0.0, (sum, e) => sum + e.totalRevenue);

  // Danh sách môn thể thao có trong sự kiện
  List<String> get availableSports {
    final set = <String>{'Tất cả'};
    for (final e in _events) {
      if (e.sportType.isNotEmpty) {
        set.add(e.sportType);
      }
    }
    return set.toList();
  }

  // Danh sách sự kiện sau lọc
  List<OwnerEventEntity> get filteredEvents {
    return _events.where((event) {
      // 1. Tìm kiếm theo tên hoặc mô tả
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchTitle = event.title.toLowerCase().contains(q);
        final matchDesc = event.description.toLowerCase().contains(q);
        final matchCourt = event.courtName.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchCourt) return false;
      }

      // 2. Lọc theo trạng thái
      if (_statusFilter == 'active') {
        if (!event.isActive || event.hasPassed) return false;
      } else if (_statusFilter == 'upcoming') {
        if (event.hasPassed) return false;
      } else if (_statusFilter == 'past') {
        if (!event.hasPassed) return false;
      } else if (_statusFilter == 'inactive') {
        if (event.isActive) return false;
      }

      // 3. Lọc theo môn thể thao
      if (_sportFilter != null && _sportFilter!.isNotEmpty && _sportFilter != 'Tất cả') {
        if (event.sportType.toLowerCase() != _sportFilter!.toLowerCase()) return false;
      }

      return true;
    }).toList();
  }

  // --- THAO TÁC DỮ LIỆU ---

  void setVenue(OwnerVenueEntity venue) {
    if (_selectedVenue?.id == venue.id) return;
    _selectedVenue = venue;
    loadEvents(venue.id);
  }

  Future<void> loadEvents(String venueId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _events = await remoteDataSource.fetchOwnerEvents(venueId);
    } catch (e) {
      debugPrint("Lỗi loadEvents: $e");
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshEvents() async {
    if (_selectedVenue != null) {
      await loadEvents(_selectedVenue!.id);
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

  String? _lastError;
  String? get lastError => _lastError;

  // Tạo sự kiện
  Future<bool> createEvent(Map<String, dynamic> eventData, {XFile? imageFile}) async {
    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      final newEvent = await remoteDataSource.createEvent(eventData, imageFile: imageFile);
      _events.insert(0, newEvent);
      return true;
    } catch (e) {
      debugPrint("Lỗi createEvent: $e");
      _lastError = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Cập nhật sự kiện
  Future<bool> updateEvent(String eventId, Map<String, dynamic> updateData, {XFile? imageFile}) async {
    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      final updated = await remoteDataSource.updateEvent(eventId, updateData, imageFile: imageFile);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _events[index] = updated.copyWith(
          bookedTicketsCount: _events[index].bookedTicketsCount,
          totalRevenue: _events[index].totalRevenue,
          attendeesCount: _events[index].attendeesCount,
        );
      }
      return true;
    } catch (e) {
      debugPrint("Lỗi updateEvent: $e");
      _lastError = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Bật/Tắt trạng thái sự kiện
  Future<void> toggleEventStatus(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final current = _events[index];
    final newStatus = !current.isActive;

    _events[index] = current.copyWith(isActive: newStatus);
    notifyListeners();

    try {
      await remoteDataSource.toggleEventStatus(eventId, newStatus);
    } catch (e) {
      debugPrint("Lỗi toggleEventStatus: $e");
      _events[index] = current;
      notifyListeners();
    }
  }

  // Xóa sự kiện
  Future<bool> deleteEvent(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final removed = _events.removeAt(index);
    notifyListeners();

    try {
      await remoteDataSource.deleteEvent(eventId);
      return true;
    } catch (e) {
      debugPrint("Lỗi deleteEvent: $e");
      _events.insert(index, removed);
      notifyListeners();
      return false;
    }
  }

  // Hủy sự kiện, hoàn vé cho khách và giải phóng ô giờ
  Future<bool> cancelEvent(
    String eventId, {
    String reason = 'Không đủ số lượng người tham gia tối thiểu',
  }) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;

    final current = _events[index];
    _events[index] = current.copyWith(isActive: false);
    notifyListeners();

    try {
      final ok = await remoteDataSource.cancelEventAndRefund(eventId, reason: reason);
      if (ok) {
        if (_selectedVenue != null) {
          await loadEvents(_selectedVenue!.id);
        }
      }
      return ok;
    } catch (e) {
      debugPrint("Lỗi cancelEvent: $e");
      _events[index] = current;
      notifyListeners();
      return false;
    }
  }

  // Lấy danh sách người tham gia
  Future<void> fetchAttendees(String eventId) async {
    _isLoadingAttendees = true;
    _attendees = [];
    notifyListeners();

    try {
      _attendees = await remoteDataSource.fetchEventAttendees(eventId);
    } catch (e) {
      debugPrint("Lỗi fetchAttendees: $e");
      _attendees = [];
    } finally {
      _isLoadingAttendees = false;
      notifyListeners();
    }
  }
}
