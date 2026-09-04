import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/services/notification_service.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/usecases/cancel_booking_usecase.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/usecases/create_walkin_booking_usecase.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/usecases/get_owner_bookings_usecase.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/usecases/update_booking_status_usecase.dart';
import 'package:flexisport_app/features/owner/booking_management/domain/usecases/update_payment_status_usecase.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/usecases/get_owner_venues_usecase.dart';

class OwnerBookingProvider extends ChangeNotifier {
  final GetOwnerBookingsUseCase getOwnerBookingsUseCase;
  final UpdateBookingStatusUseCase updateBookingStatusUseCase;
  final UpdatePaymentStatusUseCase updatePaymentStatusUseCase;
  final CreateWalkInBookingUseCase createWalkInBookingUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final GetOwnerVenuesUseCase getOwnerVenuesUseCase;

  OwnerBookingProvider({
    required this.getOwnerBookingsUseCase,
    required this.updateBookingStatusUseCase,
    required this.updatePaymentStatusUseCase,
    required this.createWalkInBookingUseCase,
    required this.cancelBookingUseCase,
    required this.getOwnerVenuesUseCase,
  });

  List<OwnerVenueEntity> _venues = [];
  OwnerVenueEntity? _selectedVenue;
  List<OwnerBookingEntity> _bookings = [];
  bool _isLoading = false;
  String _searchQuery = '';
  DateTime? _selectedDate; // null means all dates
  String _selectedStatus = 'all'; // 'all', 'pending', 'confirmed', 'completed', 'cancelled'
  String? _selectedCourtId; // null means all courts
  RealtimeChannel? _realtimeChannel;

  List<OwnerVenueEntity> get venues => _venues;
  OwnerVenueEntity? get selectedVenue => _selectedVenue;
  List<OwnerBookingEntity> get allBookings => _bookings;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DateTime? get selectedDate => _selectedDate;
  String get selectedStatus => _selectedStatus;
  String? get selectedCourtId => _selectedCourtId;

  // Khởi tạo và tải danh sách cơ sở cùng đơn đặt sân
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _venues = await getOwnerVenuesUseCase();
      if (_venues.isNotEmpty && _selectedVenue == null) {
        _selectedVenue = _venues.first;
      }
      if (_selectedVenue != null) {
        await _loadBookings();
        _subscribeRealtime();
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo OwnerBookingProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectVenue(OwnerVenueEntity venue) {
    if (_selectedVenue?.id == venue.id) return;
    _selectedVenue = venue;
    notifyListeners();
    _loadBookings();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _realtimeChannel?.unsubscribe();
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('public:owner_bookings_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'bookings',
            callback: (payload) {
              debugPrint("Realtime bookings INSERT detected: ${payload.eventType}");
              _loadBookings();

              // Bắn thông báo đẩy cho Chủ sân
              try {
                final newRecord = payload.newRecord;
                final customerName = newRecord['customer_name']?.toString() ?? 'Khách hàng';
                final venueName = _selectedVenue?.name ?? 'Cơ sở của bạn';
                final notificationId = (newRecord['id'] ?? DateTime.now().millisecondsSinceEpoch).hashCode & 0x7FFFFFFF;
                
                NotificationService.instance.showNotification(
                  id: notificationId,
                  title: 'Có đơn đặt sân mới! 🏸',
                  body: 'Khách $customerName vừa đặt sân tại $venueName. Nhấn để kiểm tra ngay!',
                  payload: jsonEncode({'route': '/booking-management'}),
                );
              } catch (e) {
                debugPrint("Lỗi hiển thị thông báo cho chủ sân: $e");
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            callback: (payload) {
              debugPrint("Realtime bookings change detected: ${payload.eventType}");
              _loadBookings();

              // Nếu đơn được thanh toán thành công (UPDATE sang completed/confirmed)
              if (payload.eventType == PostgresChangeEvent.update) {
                try {
                  final newRecord = payload.newRecord;
                  final oldRecord = payload.oldRecord;
                  final newStatus = newRecord['status']?.toString();
                  final oldStatus = oldRecord['status']?.toString();

                  if ((newStatus == 'completed' || newStatus == 'confirmed') && oldStatus != 'completed' && oldStatus != 'confirmed') {
                    final customerName = newRecord['customer_name']?.toString() ?? 'Khách hàng';
                    final venueName = _selectedVenue?.name ?? 'Cơ sở của bạn';
                    final notificationId = (newRecord['id'] ?? DateTime.now().millisecondsSinceEpoch).hashCode & 0x7FFFFFFF;

                    NotificationService.instance.showNotification(
                      id: notificationId,
                      title: 'Đơn đặt sân đã thanh toán thành công! 🏸',
                      body: 'Khách $customerName vừa thanh toán thành công đơn đặt sân tại $venueName. Hãy kiểm tra ngay!',
                      payload: jsonEncode({'route': '/owner/bookings'}),
                    );
                  }
                } catch (e) {
                  debugPrint("Lỗi bắn thông báo update cho chủ sân: $e");
                }
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'booking_slots',
            callback: (payload) {
              debugPrint("Realtime booking_slots change detected: ${payload.eventType}");
              _loadBookings();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint("Lỗi đăng ký Realtime owner bookings: $e");
    }
  }

  int _refreshCounter = 0;
  int get refreshCounter => _refreshCounter;

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> refreshBookings() async {
    _refreshCounter++;
    notifyListeners();

    if (_selectedVenue == null) {
      try {
        _venues = await getOwnerVenuesUseCase();
        if (_venues.isNotEmpty) {
          _selectedVenue = _venues.first;
        }
      } catch (_) {}
    }

    await _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (_selectedVenue == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await getOwnerBookingsUseCase(
        venueId: _selectedVenue!.id,
      );
      _bookings = List<OwnerBookingEntity>.from(fetched);
    } catch (e) {
      debugPrint("Lỗi loadBookings: $e");
      _bookings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- BỘ LỌC VÀ TÌM KIẾM ---

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setCourtFilter(String? courtId) {
    _selectedCourtId = courtId;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedDate = null;
    _selectedStatus = 'all';
    _selectedCourtId = null;
    notifyListeners();
  }

  // Danh sách đơn sau khi áp dụng toàn bộ bộ lọc
  List<OwnerBookingEntity> get filteredBookings {
    return _bookings.where((b) {
      // 1. Tìm kiếm theo tên khách, SĐT, hoặc mã đơn
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = b.customerName.toLowerCase().contains(q);
        final matchPhone = b.customerPhone.toLowerCase().contains(q);
        final matchId = b.id.toLowerCase().contains(q);
        final matchCourt = b.courtName.toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchId && !matchCourt) return false;
      }

      // 2. Lọc theo ngày đặt sân
      if (_selectedDate != null) {
        final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
        if (b.bookingDate != dateStr) return false;
      }

      // 3. Lọc theo trạng thái
      if (_selectedStatus != 'all') {
        if (_selectedStatus == 'pending' && !b.isPending) return false;
        if (_selectedStatus == 'confirmed' && !b.isConfirmed) return false;
        if (_selectedStatus == 'completed' && !b.isCompleted) return false;
        if (_selectedStatus == 'cancelled' && !b.isCancelled) return false;
      }

      // 4. Lọc theo sân
      if (_selectedCourtId != null && _selectedCourtId!.isNotEmpty) {
        if (b.courtId != _selectedCourtId) return false;
      }

      return true;
    }).toList();
  }

  // --- THỐNG KÊ NHANH ---

  String get _todayStr {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  int get todayBookingsCount => _bookings.where((b) => b.bookingDate == _todayStr).length;
  int get todayPendingCount => _bookings.where((b) => b.bookingDate == _todayStr && b.isPending).length;
  int get todayConfirmedCount => _bookings.where((b) => b.bookingDate == _todayStr && b.isConfirmed).length;
  int get todayCompletedCount => _bookings.where((b) => b.bookingDate == _todayStr && b.isCompleted).length;

  double get todayTotalRevenue {
    return _bookings
        .where((b) => b.bookingDate == _todayStr && !b.isCancelled)
        .fold(0.0, (sum, b) => sum + b.totalPrice);
  }

  double get todayDepositRevenue {
    return _bookings
        .where((b) => b.bookingDate == _todayStr && !b.isCancelled)
        .fold(0.0, (sum, b) => sum + b.depositAmount);
  }

  // --- THAO TÁC DUYỆT ĐƠN & THANH TOÁN ---

  // Xác nhận đơn đặt sân
  Future<bool> confirmBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final current = _bookings[index];
    _bookings[index] = current.copyWith(bookingStatus: 'confirmed');
    notifyListeners();

    try {
      await updateBookingStatusUseCase(bookingId: bookingId, newStatus: 'confirmed');
      return true;
    } catch (e) {
      debugPrint("Lỗi confirmBooking: $e");
      _bookings[index] = current;
      notifyListeners();
      return false;
    }
  }

  // Đánh dấu đã thanh toán đủ 100%
  Future<bool> markAsPaid(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final current = _bookings[index];
    _bookings[index] = current.copyWith(
      paymentStatus: 'paid',
      depositAmount: current.totalPrice,
    );
    notifyListeners();

    try {
      await updatePaymentStatusUseCase(bookingId: bookingId, newPaymentStatus: 'paid');
      return true;
    } catch (e) {
      debugPrint("Lỗi markAsPaid: $e");
      _bookings[index] = current;
      notifyListeners();
      return false;
    }
  }

  // Check-in nhận sân (Chuyển sang trạng thái đang chơi / hoàn thành)
  Future<bool> completeBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final current = _bookings[index];
    _bookings[index] = current.copyWith(bookingStatus: 'completed');
    notifyListeners();

    try {
      await updateBookingStatusUseCase(bookingId: bookingId, newStatus: 'completed');
      return true;
    } catch (e) {
      debugPrint("Lỗi completeBooking: $e");
      _bookings[index] = current;
      notifyListeners();
      return false;
    }
  }

  // Hủy đơn đặt sân
  Future<bool> cancelBooking(String bookingId, String reason) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final current = _bookings[index];
    _bookings[index] = current.copyWith(
      bookingStatus: 'cancelled',
      paymentStatus: 'refunded',
      cancellationReason: reason,
    );
    notifyListeners();

    try {
      await cancelBookingUseCase(bookingId: bookingId, reason: reason);
      await _loadBookings();
      return true;
    } catch (e) {
      debugPrint("Lỗi cancelBooking: $e");
      _bookings[index] = current;
      notifyListeners();
      return false;
    }
  }

  // Tạo đơn đặt sân trực tiếp tại quầy cho khách vãng lai
  Future<bool> createWalkInBooking({
    required String courtId,
    required String bookingDate,
    required List<int> slotIndexes,
    required String customerName,
    required String customerPhone,
    required double totalPrice,
    required double depositAmount,
    String? notes,
  }) async {
    if (_selectedVenue == null) {
      if (_venues.isNotEmpty) {
        _selectedVenue = _venues.first;
      } else {
        try {
          _venues = await getOwnerVenuesUseCase();
          if (_venues.isNotEmpty) {
            _selectedVenue = _venues.first;
          }
        } catch (_) {}
      }
    }

    final venueId = _selectedVenue?.id ?? '';
    if (venueId.isEmpty) {
      debugPrint("createWalkInBooking failed: venueId is empty");
      return false;
    }

    try {
      final newBooking = await createWalkInBookingUseCase(
        venueId: venueId,
        courtId: courtId,
        bookingDate: bookingDate,
        slotIndexes: slotIndexes,
        customerName: customerName,
        customerPhone: customerPhone,
        totalPrice: totalPrice,
        depositAmount: depositAmount,
        notes: notes,
      );

      _bookings.insert(0, newBooking);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Lỗi createWalkInBooking: $e");
      return false;
    }
  }
}
