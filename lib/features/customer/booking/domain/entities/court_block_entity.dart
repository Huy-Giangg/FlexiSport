class CourtBlockEntity {
  final String id;
  final String courtId;
  final String blockDate;
  final int slotIndex;
  final String reason;

  CourtBlockEntity({
    required this.id,
    required this.courtId,
    required this.blockDate,
    required this.slotIndex,
    required this.reason,
  });
}
