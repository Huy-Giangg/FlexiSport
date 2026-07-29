class BookingSlotEntity {
  final String id;
  final String bookingId;
  final String courtId;
  final String bookingDate;
  final int slotIndex;

  BookingSlotEntity({
    required this.id,
    required this.bookingId,
    required this.courtId,
    required this.bookingDate,
    required this.slotIndex,
  });
}
