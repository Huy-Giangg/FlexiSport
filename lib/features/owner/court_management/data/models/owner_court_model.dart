import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';

class OwnerCourtModel extends OwnerCourtEntity {
  const OwnerCourtModel({
    required super.id,
    required super.venueId,
    required super.name,
    required super.pricePerHour,
    super.peakPrice = 182000.0,
    super.applyPeak = true,
    super.weekendSurcharge = 20000.0,
    super.applyWeekend = true,
    super.isActive = true,
    super.sportType,
    super.todayBookingsCount = 0,
    super.todayBlockedCount = 0,
  });

  factory OwnerCourtModel.fromJson(
    Map<String, dynamic> json, {
    int todayBookings = 0,
    int todayBlocked = 0,
  }) {
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

    String? sportType = json['sport_type'] as String?;
    if (sportType == null) {
      final lowerName = name.toLowerCase();
      if (lowerName.contains('pickleball')) {
        sportType = 'Pickleball';
      } else if (lowerName.contains('cầu lông')) {
        sportType = 'Cầu lông';
      } else if (lowerName.contains('bóng đá')) {
        sportType = 'Bóng đá';
      } else if (lowerName.contains('tennis')) {
        sportType = 'Tennis';
      } else if (lowerName.contains('bóng rổ')) {
        sportType = 'Bóng rổ';
      }
    }

    final rawStatus = json['status']?.toString().toLowerCase();
    bool isCourtActive = true;
    if (rawStatus != null) {
      isCourtActive = (rawStatus == 'active' || rawStatus == 'open');
    } else if (json['is_active'] != null) {
      isCourtActive = json['is_active'] as bool;
    }

    if (todayBlocked > 0) {
      isCourtActive = false;
    }

    return OwnerCourtModel(
      id: json['id']?.toString() ?? '',
      venueId: json['venue_id']?.toString() ?? '',
      name: name,
      pricePerHour: price,
      peakPrice: peakPrice,
      applyPeak: applyPeak,
      weekendSurcharge: weekendSurcharge,
      applyWeekend: applyWeekend,
      isActive: isCourtActive,
      sportType: sportType,
      todayBookingsCount: todayBookings,
      todayBlockedCount: todayBlocked,
    );
  }

  @override
  OwnerCourtModel copyWith({
    String? id,
    String? venueId,
    String? name,
    double? pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    bool? isActive,
    String? sportType,
    int? todayBookingsCount,
    int? todayBlockedCount,
  }) {
    return OwnerCourtModel(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      name: name ?? this.name,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      peakPrice: peakPrice ?? this.peakPrice,
      applyPeak: applyPeak ?? this.applyPeak,
      weekendSurcharge: weekendSurcharge ?? this.weekendSurcharge,
      applyWeekend: applyWeekend ?? this.applyWeekend,
      isActive: isActive ?? this.isActive,
      sportType: sportType ?? this.sportType,
      todayBookingsCount: todayBookingsCount ?? this.todayBookingsCount,
      todayBlockedCount: todayBlockedCount ?? this.todayBlockedCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'name': name,
      'price_per_hour': pricePerHour,
      'peak_price': peakPrice,
      'apply_peak': applyPeak,
      'weekend_surcharge': weekendSurcharge,
      'apply_weekend': applyWeekend,
    };
  }
}
