import 'dart:ffi';

class SportsComplexEntity {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double rating;
  final String open_time;
  final String close_time;

  SportsComplexEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl, 
    required this.rating, 
    required this.open_time,
     required this.close_time,
  });
}
