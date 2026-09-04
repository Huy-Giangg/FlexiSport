import 'package:flexisport_app/features/owner/booking_management/domain/entities/owner_booking_entity.dart';

class OwnerBookingModel extends OwnerBookingEntity {
  const OwnerBookingModel({
    required super.id,
    required super.createdAt,
    required super.customerName,
    required super.customerPhone,
    super.customerAvatarUrl,
    super.userId,
    required super.totalPrice,
    required super.depositAmount,
    required super.paymentStatus,
    required super.bookingStatus,
    super.notes,
    super.cancellationReason,
    required super.venueId,
    required super.venueName,
    required super.courtId,
    required super.courtName,
    required super.sportType,
    required super.bookingDate,
    required super.slotIndexes,
    required super.timeRangeText,
    required super.slotsCount,
  });

  factory OwnerBookingModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    final rawTotalPrice = (json['total_price'] as num?)?.toDouble() 
        ?? (json['total_amount'] as num?)?.toDouble() 
        ?? (json['amount'] as num?)?.toDouble() 
        ?? 0.0;
    double totalPrice = rawTotalPrice;
    double depositAmount = (json['deposit_amount'] as num?)?.toDouble() ?? 0.0;

    final rawStatus = json['status']?.toString().toLowerCase();
    final rawBookingStatus = json['booking_status']?.toString().toLowerCase();
    String bookingStatus = 'pending';
    if (rawStatus == 'cancelled' || rawBookingStatus == 'cancelled') {
      bookingStatus = 'cancelled';
    } else if (rawBookingStatus == 'completed' || rawBookingStatus == 'used') {
      bookingStatus = 'completed';
    } else if (rawBookingStatus == 'playing') {
      bookingStatus = 'playing';
    } else if (rawBookingStatus == 'confirmed') {
      bookingStatus = 'confirmed';
    } else if (rawStatus == 'completed' || rawStatus == 'confirmed') {
      // Đơn thanh toán online thành công hoặc đã duyệt
      bookingStatus = 'confirmed';
    } else {
      bookingStatus = 'pending';
    }

    final rawPaymentStatus = json['payment_status']?.toString().toLowerCase();
    String paymentStatus = 'unpaid';
    if (bookingStatus == 'cancelled' || rawStatus == 'cancelled' || rawPaymentStatus == 'refunded' || rawPaymentStatus == 'cancelled') {
      paymentStatus = 'refunded';
    } else if (rawPaymentStatus != null && rawPaymentStatus.isNotEmpty) {
      if (rawPaymentStatus == 'paid' || rawPaymentStatus == 'completed' || rawPaymentStatus == 'success') {
        paymentStatus = 'paid';
      } else if (rawPaymentStatus == 'deposit_paid') {
        paymentStatus = 'deposit_paid';
      } else {
        paymentStatus = rawPaymentStatus;
      }
    } else {
      // Khi khách hàng đặt sân online thành công (status == 'completed' / 'confirmed') mặc định đã thanh toán đủ 100%
      if (bookingStatus == 'confirmed' || rawStatus == 'completed' || rawStatus == 'confirmed') {
        paymentStatus = 'paid';
      } else if (depositAmount >= totalPrice && totalPrice > 0) {
        paymentStatus = 'paid';
      } else if (depositAmount > 0) {
        paymentStatus = 'deposit_paid';
      } else {
        paymentStatus = 'unpaid';
      }
    }

    final notes = json['notes']?.toString() ?? json['note']?.toString();
    final cancellationReason = json['cancellation_reason']?.toString();
    final userId = json['user_id']?.toString();

    // 1. Lấy thông tin khách hàng từ profiles hoặc json gốc
    String customerName = json['customer_name']?.toString() ?? '';
    String customerPhone = json['customer_phone']?.toString() ?? '';
    String? customerAvatarUrl;

    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      final profile = json['profiles'] as Map<String, dynamic>;
      if (customerName.isEmpty) {
        customerName = profile['name']?.toString() ?? profile['full_name']?.toString() ?? '';
      }
      if (customerPhone.isEmpty) {
        customerPhone = profile['phone']?.toString() ?? '';
      }
      customerAvatarUrl = profile['avatar_url']?.toString();
    }

    if (customerName.isEmpty) {
      customerName = 'Khách vãng lai';
    }
    if (customerPhone.isEmpty) {
      customerPhone = 'Chưa cập nhật SĐT';
    }

    // 2. Lấy thông tin booking_slots, courts, venues
    String venueId = json['venue_id']?.toString() ?? '';
    String venueName = 'Cơ sở thể thao';
    String courtId = '';
    String courtName = 'Sân thể thao';
    String sportType = 'Thể thao';
    String bookingDate = '';
    final List<int> slotIndexes = [];
    String openTime = '06:00';

    if (json['booking_slots'] != null && json['booking_slots'] is List) {
      final slotsList = json['booking_slots'] as List;
      for (final s in slotsList) {
        if (s is Map<String, dynamic>) {
          if (s['slot_index'] != null) {
            final idx = (s['slot_index'] as num).toInt();
            if (!slotIndexes.contains(idx)) {
              slotIndexes.add(idx);
            }
          }
          if (bookingDate.isEmpty && s['booking_date'] != null) {
            bookingDate = s['booking_date'].toString();
          }
          if (courtId.isEmpty && s['court_id'] != null) {
            courtId = s['court_id'].toString();
          }

          if (s['courts'] != null && s['courts'] is Map<String, dynamic>) {
            final c = s['courts'] as Map<String, dynamic>;
            courtName = c['name']?.toString() ?? courtName;
            if (c['venue_id'] != null && venueId.isEmpty) {
              venueId = c['venue_id'].toString();
            }

            if (c['venues'] != null && c['venues'] is Map<String, dynamic>) {
              final v = c['venues'] as Map<String, dynamic>;
              venueName = v['name']?.toString() ?? venueName;
              sportType = v['sports_type']?.toString() ?? sportType;
              openTime = v['open_time']?.toString() ?? '06:00';
            }
          }
        }
      }
    }

    if (bookingDate.isEmpty) {
      bookingDate = "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
    }

    if (totalPrice == 0.0 && json['booking_slots'] != null && json['booking_slots'] is List) {
      double sumSlots = 0.0;
      for (final s in (json['booking_slots'] as List)) {
        if (s is Map<String, dynamic> && s['price'] != null) {
          sumSlots += (s['price'] as num).toDouble();
        }
      }
      if (sumSlots > 0) {
        totalPrice = sumSlots;
      }
    }

    if (paymentStatus == 'paid' && depositAmount == 0.0 && totalPrice > 0) {
      depositAmount = totalPrice;
    }

    // 3. Tính toán khung giờ chuỗi
    final timeRangeText = _formatTimeRange(slotIndexes, openTime);

    return OwnerBookingModel(
      id: id,
      createdAt: createdAt,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAvatarUrl: customerAvatarUrl,
      userId: userId,
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      paymentStatus: paymentStatus,
      bookingStatus: bookingStatus,
      notes: notes,
      cancellationReason: cancellationReason,
      venueId: venueId,
      venueName: venueName,
      courtId: courtId,
      courtName: courtName,
      sportType: sportType,
      bookingDate: bookingDate,
      slotIndexes: slotIndexes,
      timeRangeText: timeRangeText,
      slotsCount: slotIndexes.length,
    );
  }

  static String _formatTimeRange(List<int> slots, String openTimeStr) {
    if (slots.isEmpty) return 'Chưa chọn ca';

    final parts = openTimeStr.split(':');
    final startH = int.tryParse(parts[0]) ?? 6;
    final startM = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final baseMinutes = startH * 60 + startM;

    final firstSlot = slots.first;
    final lastSlot = slots.last;

    final startMinutes = baseMinutes + firstSlot * 30;
    final endMinutes = baseMinutes + (lastSlot + 1) * 30;

    final sH = (startMinutes ~/ 60).toString().padLeft(2, '0');
    final sM = (startMinutes % 60).toString().padLeft(2, '0');
    final eH = (endMinutes ~/ 60).toString().padLeft(2, '0');
    final eM = (endMinutes % 60).toString().padLeft(2, '0');

    return "$sH:$sM - $eH:$eM (${slots.length} ca)";
  }

  @override
  OwnerBookingModel copyWith({
    String? id,
    DateTime? createdAt,
    String? customerName,
    String? customerPhone,
    String? customerAvatarUrl,
    String? userId,
    double? totalPrice,
    double? depositAmount,
    String? paymentStatus,
    String? bookingStatus,
    String? notes,
    String? cancellationReason,
    String? venueId,
    String? venueName,
    String? courtId,
    String? courtName,
    String? sportType,
    String? bookingDate,
    List<int>? slotIndexes,
    String? timeRangeText,
    int? slotsCount,
  }) {
    return OwnerBookingModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAvatarUrl: customerAvatarUrl ?? this.customerAvatarUrl,
      userId: userId ?? this.userId,
      totalPrice: totalPrice ?? this.totalPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      courtId: courtId ?? this.courtId,
      courtName: courtName ?? this.courtName,
      sportType: sportType ?? this.sportType,
      bookingDate: bookingDate ?? this.bookingDate,
      slotIndexes: slotIndexes ?? this.slotIndexes,
      timeRangeText: timeRangeText ?? this.timeRangeText,
      slotsCount: slotsCount ?? this.slotsCount,
    );
  }
}
