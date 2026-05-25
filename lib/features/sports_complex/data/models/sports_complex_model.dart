import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';

class SportsComplexModel extends SportsComplexEntity {
  SportsComplexModel({
    required super.id,
    required super.name,
    required super.address,
    required super.imageUrl,
    required super.rating,
    required super.open_time,
    required super.close_time,
  });

  factory SportsComplexModel.fromJson(Map<String, dynamic> json) {
    return SportsComplexModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      imageUrl: '',
      rating: json['rating'].toDouble(),
      open_time: json['open_time'],
      close_time: json['close_time'],
    );
  }
}
