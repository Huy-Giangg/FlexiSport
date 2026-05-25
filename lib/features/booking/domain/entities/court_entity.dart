// Model đại diện cho một Sân
class CourtEntity {
  final String id;
  final String venueId;
  final String name;
  final double pricePerHour;

  CourtEntity({
    required this.id,
    required this.name,
    required this.pricePerHour,
     required this.venueId,
  });
}