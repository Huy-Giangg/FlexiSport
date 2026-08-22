import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';

class SportsComplexModel extends SportsComplexEntity {
  SportsComplexModel({
    required super.id,
    required super.name,
    required super.address,
    required super.logoUrl,
    required super.rating,
    required super.open_time,
    required super.close_time,
    super.latitude,
    super.longitude,
    super.sportsType,
  });

  factory SportsComplexModel.fromJson(Map<String, dynamic> json) {
    return SportsComplexModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      open_time: json['open_time']?.toString() ?? '',
      close_time: json['close_time']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sportsType: json['sports_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'logo_url': logoUrl,
      'rating': rating,
      'open_time': open_time,
      'close_time': close_time,
      'latitude': latitude,
      'longitude': longitude,
      'sports_type': sportsType,
    };
  }
}
