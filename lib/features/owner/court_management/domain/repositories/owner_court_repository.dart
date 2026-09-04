import 'package:image_picker/image_picker.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/court_slot_status_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';

abstract class OwnerCourtRepository {
  Future<List<OwnerVenueEntity>> getOwnerVenues();
  Future<OwnerVenueEntity> addVenue({
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? logoUrl,
    XFile? imageFile,
  });
  Future<bool> deleteVenue(String venueId);
  Future<List<OwnerCourtEntity>> getCourtsByVenue(String venueId);
  Future<OwnerCourtEntity> addCourt({
    required String venueId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  });
  Future<OwnerCourtEntity> updateCourt({
    required String courtId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  });
  Future<void> deleteCourt(String courtId);
  Future<void> toggleCourtStatus({
    required String courtId,
    required String venueId,
    required bool isActive,
    String? reason,
  });
  Future<List<CourtSlotStatusEntity>> getCourtSlotsStatus({
    required String courtId,
    required String venueId,
    required String date,
  });
  Future<void> blockCourtSlot({
    required String courtId,
    required String date,
    required int slotIndex,
    required String reason,
  });
  Future<void> unblockCourtSlot(String blockId);
  Future<void> updateVenueInfo({
    required String venueId,
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? bankName,
    String? accountNumber,
  });
}
