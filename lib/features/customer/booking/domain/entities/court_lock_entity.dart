class CourtLockEntity {
  final String id;
  final String courtId;
  final int slotIndex;
  final String bookingDate;
  final String userId;
  final DateTime lockedUntil;
  final String? lockToken;

  CourtLockEntity({
    required this.id,
    required this.courtId,
    required this.slotIndex,
    required this.bookingDate,
    required this.userId,
    required this.lockedUntil,
    this.lockToken,
  });

  bool get isExpired => DateTime.now().isAfter(lockedUntil);
}
