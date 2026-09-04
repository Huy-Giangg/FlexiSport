import 'package:flexisport_app/features/customer/booking/domain/entities/court_entity.dart';

class CourtModel extends CourtEntity {
  CourtModel({
    required super.id,
    required super.name,
    required super.pricePerHour,
    required super.venueId,
    super.peakPrice = 182000.0,
    super.applyPeak = true,
    super.weekendSurcharge = 20000.0,
    super.applyWeekend = true,
    super.isActive = true,
    super.status,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json){
    final name = json['name'] as String? ?? 'Sân';
    double price = 140000.0;
    if (json['price_per_hour'] != null) {
      price = (json['price_per_hour'] as num).toDouble();
    } else {
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
    }

    final peakPrice = json['peak_price'] != null
        ? (json['peak_price'] as num).toDouble()
        : (price * 1.3).roundToDouble();

    final applyPeak = json['apply_peak'] != null
        ? (json['apply_peak'] == true || json['apply_peak'] == 1 || json['apply_peak'].toString() == 'true')
        : true;

    final weekendSurcharge = json['weekend_surcharge'] != null
        ? (json['weekend_surcharge'] as num).toDouble()
        : 20000.0;

    final applyWeekend = json['apply_weekend'] != null
        ? (json['apply_weekend'] == true || json['apply_weekend'] == 1 || json['apply_weekend'].toString() == 'true')
        : true;

    final rawStatus = json['status']?.toString().toLowerCase();
    final rawIsActive = json['is_active'];
    bool active = true;
    if (rawIsActive != null) {
      active = rawIsActive == true || rawIsActive == 1 || rawIsActive.toString() == 'true';
    }
    if (rawStatus == 'maintenance' || rawStatus == 'inactive' || rawStatus == 'closed') {
      active = false;
    }

    return CourtModel(
      id: json['id']?.toString() ?? '',
      name: name,
      pricePerHour: price,
      peakPrice: peakPrice,
      applyPeak: applyPeak,
      weekendSurcharge: weekendSurcharge,
      applyWeekend: applyWeekend,
      venueId: json['venue_id'] as String? ?? '',
      isActive: active,
      status: rawStatus,
    );
  }
}
