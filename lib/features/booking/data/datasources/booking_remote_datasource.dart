
import 'package:flexisport_app/features/booking/data/models/court_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRemoteDatasource {
  final SupabaseClient supabaseClient;

  BookingRemoteDatasource(this.supabaseClient);

  Future<List<CourtModel>> fetchCourts(String venueId) async{
    final respone = await supabaseClient
    .from('courts')
    .select('id, name, venue_id, sport_type_id')
    .eq('venue_id', venueId);

    return (respone as List)
    .map((json) => CourtModel.fromJson(json))
    .toList();
  }

  Future<List<Map<String, dynamic>>> fetchActiveLocks(String venueId, String date) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final response = await supabaseClient
        .from('court_locks')
        .select('id, court_id, slot_index, booking_date, user_id, locked_until, courts!inner(venue_id)')
        .eq('booking_date', date)
        .eq('courts.venue_id', venueId)
        .gt('locked_until', nowIso);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<bool> insertLock(String courtId, int slotIndex, String date, String userId) async {
    try {
      await supabaseClient.from('court_locks').insert({
        'court_id': courtId,
        'slot_index': slotIndex,
        'booking_date': date,
        'user_id': userId,
      });
      return true;
    } catch (e) {
      // Trả về false nếu bị trùng lặp hoặc vi phạm constraint (tranh chấp)
      return false;
    }
  }

  Future<void> deleteLock(String courtId, int slotIndex, String date, String userId) async {
    await supabaseClient
        .from('court_locks')
        .delete()
        .eq('court_id', courtId)
        .eq('slot_index', slotIndex)
        .eq('booking_date', date)
        .eq('user_id', userId);
  }

  Future<void> deleteAllUserLocks(String userId) async {
    await supabaseClient
        .from('court_locks')
        .delete()
        .eq('user_id', userId);
  }
}