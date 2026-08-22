import 'package:flexisport_app/features/customer/booking/domain/entities/court_entity.dart';

class CourtModel extends CourtEntity {
  CourtModel({
    required super.id,
    required super.name,
    required super.pricePerHour,
     required super.venueId,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json){
    final name = json['name'] as String? ?? 'Sân';
    double price = 150000.0;
    final lowerName = name.toLowerCase();
    if (lowerName.contains('pickleball')) {
      if (name.contains('3') || name.contains('4')) {
        price = 160000.0;
      } else {
        price = 140000.0;
      }
    } else if (lowerName.contains('tennis')) {
      price = 220000.0;
    } else if (lowerName.contains('cầu lông') || lowerName.contains('badminton')) {
      price = 80000.0;
    } else if (lowerName.contains('bóng đá') || lowerName.contains('football') || lowerName.contains('soccer')) {
      price = 200000.0;
    }

    return CourtModel(
      id: json['id']?.toString() ?? '',
      name: name,
      pricePerHour: price,
      venueId: json['venue_id'] as String? ?? '',
    );
  }
}
