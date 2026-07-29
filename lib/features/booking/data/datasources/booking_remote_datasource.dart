
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

  Future<List<Map<String, dynamic>>> fetchBookedSlots(String venueId, String date) async {
    final response = await supabaseClient
        .from('booking_slots')
        .select('id, booking_id, court_id, booking_date, slot_index, courts!inner(venue_id)')
        .eq('booking_date', date)
        .eq('courts.venue_id', venueId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchCourtBlocks(String venueId, String date) async {
    final response = await supabaseClient
        .from('court_blocks')
        .select('id, court_id, block_date, slot_index, reason, courts!inner(venue_id)')
        .eq('block_date', date)
        .eq('courts.venue_id', venueId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchEventSlots(String venueId, String date) async {
    final response = await supabaseClient
        .from('event_slots')
        .select('id, event_id, court_id, event_date, slot_index, courts!inner(venue_id)')
        .eq('event_date', date)
        .eq('courts.venue_id', venueId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<bool> insertLock(String courtId, int slotIndex, String date, String userId) async {
    try {
      await supabaseClient.from('court_locks').insert({
        'court_id': courtId,
        'slot_index': slotIndex,
        'booking_date': date,
        'user_id': (userId == 'guest_user' || userId.isEmpty) ? null : userId,
      });
      return true;
    } catch (e) {
      // Trả về false nếu bị trùng lặp hoặc vi phạm constraint (tranh chấp)
      return false;
    }
  }

  Future<void> deleteLock(String courtId, int slotIndex, String date, String userId) async {
    final query = supabaseClient
        .from('court_locks')
        .delete()
        .eq('court_id', courtId)
        .eq('slot_index', slotIndex)
        .eq('booking_date', date);

    if (userId == 'guest_user' || userId.isEmpty) {
      await query.isFilter('user_id', null);
    } else {
      await query.eq('user_id', userId);
    }
  }

  Future<void> deleteAllUserLocks(String userId) async {
    if (userId == 'guest_user' || userId.isEmpty) return;
    await supabaseClient
        .from('court_locks')
        .delete()
        .eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> fetchEvents(String venueId) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    var query = supabaseClient
        .from('events')
        .select()
        .eq('is_active', true)
        .gte('event_date', todayStr);
    if (venueId.isNotEmpty) {
      query = query.eq('venue_id', venueId);
    }
    final response = await query.order('event_date', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<int> fetchBookedTicketsCount(String eventId) async {
    final response = await supabaseClient
        .from('event_bookings')
        .select('ticket_count')
        .eq('event_id', eventId)
        .not('status', 'eq', 'cancelled'); // Count all except cancelled
    
    final list = response as List;
    int count = 0;
    for (var item in list) {
      count += (item['ticket_count'] as int? ?? 0);
    }
    return count;
  }

  Future<Map<String, dynamic>> insertEventBooking(Map<String, dynamic> bookingData) async {
    final response = await supabaseClient
        .from('event_bookings')
        .insert(bookingData)
        .select()
        .single();
    return response as Map<String, dynamic>;
  }

  Future<void> updateEventBookingStatus(String bookingId, String status) async {
    await supabaseClient
        .from('event_bookings')
        .update({'status': status})
        .eq('id', bookingId);
  }

  Future<List<Map<String, dynamic>>> fetchUserEventBookings(String userId) async {
    final response = await supabaseClient
        .from('event_bookings')
        .select('*, events(*, venues(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchGuestEventBookings(List<String> bookingIds) async {
    if (bookingIds.isEmpty) return [];
    final response = await supabaseClient
        .from('event_bookings')
        .select('*, events(*, venues(*))')
        .inFilter('id', bookingIds)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }
}