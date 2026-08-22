class EventSlotEntity {
  final String id;
  final String eventId;
  final String courtId;
  final String eventDate;
  final int slotIndex;

  EventSlotEntity({
    required this.id,
    required this.eventId,
    required this.courtId,
    required this.eventDate,
    required this.slotIndex,
  });
}
