class OwnerCourtEntity {
  final String id;
  final String venueId;
  final String name;
  final double pricePerHour;
  final double peakPrice;
  final bool applyPeak;
  final double weekendSurcharge;
  final bool applyWeekend;
  final bool isActive;
  final String? sportType;
  final int todayBookingsCount;
  final int todayBlockedCount;

  const OwnerCourtEntity({
    required this.id,
    required this.venueId,
    required this.name,
    required this.pricePerHour,
    this.peakPrice = 182000.0,
    this.applyPeak = true,
    this.weekendSurcharge = 20000.0,
    this.applyWeekend = true,
    this.isActive = true,
    this.sportType,
    this.todayBookingsCount = 0,
    this.todayBlockedCount = 0,
  });

  OwnerCourtEntity copyWith({
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
    return OwnerCourtEntity(
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
}
