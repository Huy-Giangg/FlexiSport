class CourtLockEntity {
  final String id;
  final String courtId;
  final int slotIndex;
  final String bookingDate;
  final String userId;
  final DateTime lockedUntil;

  CourtLockEntity({
    required this.id,
    required this.courtId,
    required this.slotIndex,
    required this.bookingDate,
    required this.userId,
    required this.lockedUntil,
  });

  bool get isExpired => DateTime.now().isAfter(lockedUntil);
}
