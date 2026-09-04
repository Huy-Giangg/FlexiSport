class OwnerBookingEntity {
  final String id;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final String? customerAvatarUrl;
  final String? userId;
  final double totalPrice;
  final double depositAmount;
  final String paymentStatus; // 'unpaid', 'deposit_paid', 'paid', 'refunded'
  final String bookingStatus; // 'pending', 'confirmed', 'playing', 'completed', 'cancelled'
  final String? notes;
  final String? cancellationReason;
  final String venueId;
  final String venueName;
  final String courtId;
  final String courtName;
  final String sportType;
  final String bookingDate; // YYYY-MM-DD
  final List<int> slotIndexes;
  final String timeRangeText; // e.g. "07:00 - 08:30"
  final int slotsCount;

  const OwnerBookingEntity({
    required this.id,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    this.customerAvatarUrl,
    this.userId,
    required this.totalPrice,
    required this.depositAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    this.notes,
    this.cancellationReason,
    required this.venueId,
    required this.venueName,
    required this.courtId,
    required this.courtName,
    required this.sportType,
    required this.bookingDate,
    required this.slotIndexes,
    required this.timeRangeText,
    required this.slotsCount,
  });

  bool get hasPassed {
    if (bookingDate.isEmpty) return false;
    try {
      final parts = bookingDate.split('-');
      if (parts.length != 3) return false;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      int endHour = 22;
      int endMinute = 0;

      if (timeRangeText.contains('-')) {
        final timePart = timeRangeText.split('-')[1].trim().split(' ')[0];
        final tParts = timePart.split(':');
        if (tParts.length >= 2) {
          endHour = int.parse(tParts[0]);
          endMinute = int.parse(tParts[1]);
        }
      } else if (slotIndexes.isNotEmpty) {
        final lastSlot = slotIndexes.reduce((a, b) => a > b ? a : b);
        final totalMinutes = 6 * 60 + (lastSlot + 1) * 30;
        endHour = totalMinutes ~/ 60;
        endMinute = totalMinutes % 60;
      }

      final endDateTime = DateTime(year, month, day, endHour, endMinute);
      return DateTime.now().isAfter(endDateTime);
    } catch (_) {
      return false;
    }
  }

  String get effectiveStatus {
    if (bookingStatus == 'cancelled') return 'cancelled';
    if (bookingStatus == 'completed' || hasPassed) return 'completed';
    return bookingStatus;
  }

  double get remainingAmount => totalPrice > depositAmount ? (totalPrice - depositAmount) : 0.0;

  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'completed';
  bool get isDepositPaid => paymentStatus == 'deposit_paid';
  bool get isPending => !isCancelled && !hasPassed && bookingStatus == 'pending';
  bool get isConfirmed => !isCancelled && !hasPassed && bookingStatus == 'confirmed';
  bool get isPlaying => !isCancelled && !hasPassed && bookingStatus == 'playing';
  bool get isCompleted => !isCancelled && (bookingStatus == 'completed' || hasPassed);
  bool get isCancelled => bookingStatus == 'cancelled';

  OwnerBookingEntity copyWith({
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
    return OwnerBookingEntity(
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
