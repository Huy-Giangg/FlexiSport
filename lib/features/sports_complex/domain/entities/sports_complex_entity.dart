class SportsComplexEntity {
  final String id;
  final String name;
  final String address;
  final String logoUrl;
  final double rating;
  final String open_time;
  final String close_time;
  final double? latitude;
  final double? longitude;
  final String? sportsType;

  SportsComplexEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.logoUrl, 
    required this.rating, 
    required this.open_time,
    required this.close_time,
    this.latitude,
    this.longitude,
    this.sportsType,
  });
}
