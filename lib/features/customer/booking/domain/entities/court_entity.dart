// Model đại diện cho một Sân
class CourtEntity {
  final String id;
  final String venueId;
  final String name;
  final double pricePerHour;
  final double peakPrice;
  final bool applyPeak;
  final double weekendSurcharge;
  final bool applyWeekend;
  final bool isActive;
  final String? status;

  CourtEntity({
    required this.id,
    required this.name,
    required this.pricePerHour,
    required this.venueId,
    this.peakPrice = 182000.0,
    this.applyPeak = true,
    this.weekendSurcharge = 20000.0,
    this.applyWeekend = true,
    this.isActive = true,
    this.status,
  });
}