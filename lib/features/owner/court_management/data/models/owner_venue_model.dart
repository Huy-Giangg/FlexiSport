import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';

class OwnerVenueModel extends OwnerVenueEntity {
  const OwnerVenueModel({
    required super.id,
    required super.name,
    required super.address,
    required super.openTime,
    required super.closeTime,
    super.rating = 5.0,
    super.sportsType,
    super.logoUrl,
    super.totalCourts = 0,
    super.bankName,
    super.accountNumber,
    super.ownerId,
  });

  factory OwnerVenueModel.fromJson(Map<String, dynamic> json, {int totalCourts = 0}) {
    return OwnerVenueModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      openTime: json['open_time']?.toString() ?? '06:00',
      closeTime: json['close_time']?.toString() ?? '22:00',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      sportsType: json['sports_type']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      totalCourts: totalCourts,
      bankName: json['bank_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      ownerId: json['owner_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'open_time': openTime,
      'close_time': closeTime,
      if (sportsType != null) 'sports_type': sportsType,
      if (bankName != null) 'bank_name': bankName,
      if (accountNumber != null) 'account_number': accountNumber,
      if (ownerId != null) 'owner_id': ownerId,
    };
  }
}
