class OwnerVenueEntity {
  final String id;
  final String name;
  final String address;
  final String openTime;
  final String closeTime;
  final double rating;
  final String? sportsType;
  final String? logoUrl;
  final int totalCourts;
  final String? bankName;
  final String? accountNumber;
  final String? ownerId;

  const OwnerVenueEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.openTime,
    required this.closeTime,
    this.rating = 5.0,
    this.sportsType,
    this.logoUrl,
    this.totalCourts = 0,
    this.bankName,
    this.accountNumber,
    this.ownerId,
  });

  OwnerVenueEntity copyWith({
    String? id,
    String? name,
    String? address,
    String? openTime,
    String? closeTime,
    double? rating,
    String? sportsType,
    String? logoUrl,
    int? totalCourts,
    String? bankName,
    String? accountNumber,
    String? ownerId,
  }) {
    return OwnerVenueEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      rating: rating ?? this.rating,
      sportsType: sportsType ?? this.sportsType,
      logoUrl: logoUrl ?? this.logoUrl,
      totalCourts: totalCourts ?? this.totalCourts,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
