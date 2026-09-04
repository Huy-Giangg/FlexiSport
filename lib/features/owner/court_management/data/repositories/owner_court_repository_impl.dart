import 'package:image_picker/image_picker.dart';
import 'package:flexisport_app/features/owner/court_management/data/datasources/owner_court_remote_datasource.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/court_slot_status_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_court_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/court_management/domain/repositories/owner_court_repository.dart';

class OwnerCourtRepositoryImpl implements OwnerCourtRepository {
  final OwnerCourtRemoteDataSource remoteDataSource;

  OwnerCourtRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<OwnerVenueEntity>> getOwnerVenues() async {
    final list = await remoteDataSource.fetchOwnerVenues();
    return List<OwnerVenueEntity>.from(list);
  }

  @override
  Future<OwnerVenueEntity> addVenue({
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? logoUrl,
    XFile? imageFile,
  }) async {
    return await remoteDataSource.addVenue(
      name: name,
      address: address,
      openTime: openTime,
      closeTime: closeTime,
      sportsType: sportsType,
      logoUrl: logoUrl,
      imageFile: imageFile,
    );
  }

  @override
  Future<bool> deleteVenue(String venueId) async {
    return await remoteDataSource.deleteVenue(venueId);
  }

  @override
  Future<List<OwnerCourtEntity>> getCourtsByVenue(String venueId) async {
    final list = await remoteDataSource.fetchCourtsByVenue(venueId);
    return List<OwnerCourtEntity>.from(list);
  }

  @override
  Future<OwnerCourtEntity> addCourt({
    required String venueId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  }) async {
    return await remoteDataSource.addCourt(
      venueId: venueId,
      name: name,
      pricePerHour: pricePerHour,
      peakPrice: peakPrice,
      applyPeak: applyPeak,
      weekendSurcharge: weekendSurcharge,
      applyWeekend: applyWeekend,
      sportType: sportType,
    );
  }

  @override
  Future<OwnerCourtEntity> updateCourt({
    required String courtId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  }) async {
    return await remoteDataSource.updateCourt(
      courtId: courtId,
      name: name,
      pricePerHour: pricePerHour,
      peakPrice: peakPrice,
      applyPeak: applyPeak,
      weekendSurcharge: weekendSurcharge,
      applyWeekend: applyWeekend,
      sportType: sportType,
    );
  }

  @override
  Future<void> deleteCourt(String courtId) async {
    await remoteDataSource.deleteCourt(courtId);
  }

  @override
  Future<void> toggleCourtStatus({
    required String courtId,
    required String venueId,
    required bool isActive,
    String? reason,
  }) async {
    await remoteDataSource.toggleCourtStatus(
      courtId: courtId,
      venueId: venueId,
      setToActive: isActive,
      reason: reason,
    );
  }

  @override
  Future<List<CourtSlotStatusEntity>> getCourtSlotsStatus({
    required String courtId,
    required String venueId,
    required String date,
  }) async {
    return await remoteDataSource.fetchCourtSlotsStatus(
      courtId: courtId,
      venueId: venueId,
      date: date,
    );
  }

  @override
  Future<void> blockCourtSlot({
    required String courtId,
    required String date,
    required int slotIndex,
    required String reason,
  }) async {
    await remoteDataSource.blockCourtSlot(
      courtId: courtId,
      date: date,
      slotIndex: slotIndex,
      reason: reason,
    );
  }

  @override
  Future<void> unblockCourtSlot(String blockId) async {
    await remoteDataSource.unblockCourtSlot(blockId);
  }

  @override
  Future<void> updateVenueInfo({
    required String venueId,
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? bankName,
    String? accountNumber,
  }) async {
    await remoteDataSource.updateVenueInfo(
      venueId: venueId,
      name: name,
      address: address,
      openTime: openTime,
      closeTime: closeTime,
      sportsType: sportsType,
      bankName: bankName,
      accountNumber: accountNumber,
    );
  }
}
