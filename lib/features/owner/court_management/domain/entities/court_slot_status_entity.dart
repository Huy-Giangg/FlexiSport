class CourtSlotStatusEntity {
  final int slotIndex;
  final String timeLabel;
  final bool isBooked;
  final bool isBlocked;
  final String? blockReason;
  final String? blockId;
  final String? customerName;
  final String? bookingId;

  const CourtSlotStatusEntity({
    required this.slotIndex,
    required this.timeLabel,
    this.isBooked = false,
    this.isBlocked = false,
    this.blockReason,
    this.blockId,
    this.customerName,
    this.bookingId,
  });

  bool get isAvailable => !isBooked && !isBlocked;

  String get endTime {
    final parts = timeLabel.split(':');
    if (parts.length >= 2) {
      int h = int.tryParse(parts[0]) ?? 0;
      int m = int.tryParse(parts[1]) ?? 0;
      m += 30;
      if (m >= 60) {
        h += m ~/ 60;
        m = m % 60;
      }
      final endH = h.toString().padLeft(2, '0');
      final endM = m.toString().padLeft(2, '0');
      return "$endH:$endM";
    }
    return timeLabel;
  }

  String get timeRange => "$timeLabel - $endTime";

  CourtSlotStatusEntity copyWith({
    int? slotIndex,
    String? timeLabel,
    bool? isBooked,
    bool? isBlocked,
    String? blockReason,
    String? blockId,
    String? customerName,
    String? bookingId,
  }) {
    return CourtSlotStatusEntity(
      slotIndex: slotIndex ?? this.slotIndex,
      timeLabel: timeLabel ?? this.timeLabel,
      isBooked: isBooked ?? this.isBooked,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
      blockId: blockId ?? this.blockId,
      customerName: customerName ?? this.customerName,
      bookingId: bookingId ?? this.bookingId,
    );
  }
}
