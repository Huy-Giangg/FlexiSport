
import 'package:flutter/foundation.dart';
import 'package:flexisport_app/features/customer/booking/data/models/court_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/services/session_service.dart';

class BookingRemoteDatasource {
  final SupabaseClient supabaseClient;

  BookingRemoteDatasource(this.supabaseClient);

  Future<List<CourtModel>> fetchCourts(String venueId) async{
    final respone = await supabaseClient
    .from('courts')
    .select('*')
    .eq('venue_id', venueId);

    return (respone as List)
    .map((json) => CourtModel.fromJson(json))
    .toList();
  }

  Future<List<Map<String, dynamic>>> fetchActiveLocks(String venueId, String date) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      final response = await supabaseClient
          .from('court_locks')
          .select('id, court_id, slot_index, booking_date, user_id, lock_token, locked_until, courts!inner(venue_id)')
          .eq('booking_date', date)
          .eq('courts.venue_id', venueId)
          .gt('locked_until', nowIso);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (_) {
      final response = await supabaseClient
          .from('court_locks')
          .select('id, court_id, slot_index, booking_date, user_id, locked_until, courts!inner(venue_id)')
          .eq('booking_date', date)
          .eq('courts.venue_id', venueId)
          .gt('locked_until', nowIso);
      return List<Map<String, dynamic>>.from(response as List);
    }
  }

  Future<List<Map<String, dynamic>>> fetchBookedSlots(String venueId, String date) async {
    try {
      final response = await supabaseClient
          .from('booking_slots')
          .select('id, booking_id, court_id, booking_date, slot_index, is_active, bookings!inner(status), courts!inner(venue_id)')
          .eq('booking_date', date)
          .eq('courts.venue_id', venueId)
          .eq('is_active', true)
          .neq('bookings.status', 'cancelled');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (_) {
      try {
        final response = await supabaseClient
            .from('booking_slots')
            .select('id, booking_id, court_id, booking_date, slot_index, bookings!inner(status), courts!inner(venue_id)')
            .eq('booking_date', date)
            .eq('courts.venue_id', venueId)
            .neq('bookings.status', 'cancelled');
        return List<Map<String, dynamic>>.from(response as List);
      } catch (e2) {
        final response = await supabaseClient
            .from('booking_slots')
            .select('id, booking_id, court_id, booking_date, slot_index, courts!inner(venue_id)')
            .eq('booking_date', date)
            .eq('courts.venue_id', venueId);
        return List<Map<String, dynamic>>.from(response as List);
      }
    }
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
    try {
      final response = await supabaseClient
          .from('event_slots')
          .select('id, event_id, court_id, event_date, slot_index, courts!inner(venue_id)')
          .eq('event_date', date)
          .eq('courts.venue_id', venueId);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      try {
        final response = await supabaseClient
            .from('event_slots')
            .select('id, event_id, court_id, event_date, slot_index')
            .eq('event_date', date);
        return List<Map<String, dynamic>>.from(response as List);
      } catch (_) {
        return [];
      }
    }
  }

  Future<bool> insertLock(String courtId, int slotIndex, String date, String userId, {String? lockToken}) async {
    try {
      final authUser = supabaseClient.auth.currentUser;
      final actualUserId = authUser?.id;

      final lockPayload = <String, dynamic>{
        'court_id': courtId,
        'slot_index': slotIndex,
        'booking_date': date,
        'locked_until': DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
      };

      if (actualUserId != null) {
        lockPayload['user_id'] = actualUserId;
      }
      if (lockToken != null && lockToken.isNotEmpty) {
        lockPayload['lock_token'] = lockToken;
      } else if (actualUserId == null) {
        final guestToken = await SessionService.instance.getGuestSessionToken();
        lockPayload['lock_token'] = guestToken;
      }

      // 1. Thử insert với cả lock_token
      try {
        await supabaseClient.from('court_locks').insert(lockPayload);
        return true;
      } catch (insertErr) {
        // Fallback nếu cột lock_token chưa được nạp
        if (actualUserId != null) {
          await supabaseClient.from('court_locks').insert({
            'court_id': courtId,
            'slot_index': slotIndex,
            'booking_date': date,
            'user_id': actualUserId,
            'locked_until': DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
          });
          return true;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint("Lỗi giữ chỗ slot $slotIndex sân $courtId: $e");
      // Trả về false để UI không cho phép thêm vào giỏ và thông báo cho người dùng
      return false;
    }
  }

  Future<void> deleteLock(String courtId, int slotIndex, String date, String userId, {String? lockToken}) async {
    try {
      final authUser = supabaseClient.auth.currentUser;
      if (authUser != null) {
        await supabaseClient
            .from('court_locks')
            .delete()
            .eq('court_id', courtId)
            .eq('slot_index', slotIndex)
            .eq('booking_date', date)
            .eq('user_id', authUser.id);
      } else {
        final token = lockToken ?? await SessionService.instance.getGuestSessionToken();
        try {
          await supabaseClient
              .from('court_locks')
              .delete()
              .eq('court_id', courtId)
              .eq('slot_index', slotIndex)
              .eq('booking_date', date)
              .eq('lock_token', token);
        } catch (_) {
          await supabaseClient
              .from('court_locks')
              .delete()
              .eq('court_id', courtId)
              .eq('slot_index', slotIndex)
              .eq('booking_date', date);
        }
      }
    } catch (_) {}
  }

  Future<void> deleteAllUserLocks(String userId, {String? lockToken}) async {
    try {
      final authUser = supabaseClient.auth.currentUser;
      if (authUser != null) {
        await supabaseClient.from('court_locks').delete().eq('user_id', authUser.id);
      } else {
        final token = lockToken ?? await SessionService.instance.getGuestSessionToken();
        try {
          await supabaseClient.from('court_locks').delete().eq('lock_token', token);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<bool> extendCourtLocks({
    required List<Map<String, dynamic>> slots,
    String? lockToken,
    int durationMinutes = 10,
  }) async {
    if (slots.isEmpty) return true;
    try {
      final authUser = supabaseClient.auth.currentUser;
      final token = lockToken ?? await SessionService.instance.getGuestSessionToken();

      try {
        final response = await supabaseClient.rpc('extend_court_locks', params: {
          'p_slots': slots,
          'p_lock_token': token,
          'p_user_id': authUser?.id,
          'p_duration_minutes': durationMinutes,
        });
        if (response == true) return true;
      } catch (_) {}

      // Fallback: cập nhật trực tiếp locked_until
      final nowExtended = DateTime.now().toUtc().add(Duration(minutes: durationMinutes)).toIso8601String();
      for (final s in slots) {
        final courtId = s['court_id']?.toString() ?? '';
        final date = s['booking_date']?.toString() ?? '';
        final slotIdx = (s['slot_index'] as num?)?.toInt() ?? 0;
        await supabaseClient
            .from('court_locks')
            .update({'locked_until': nowExtended})
            .eq('court_id', courtId)
            .eq('booking_date', date)
            .eq('slot_index', slotIdx);
      }
      return true;
    } catch (e) {
      debugPrint("Lỗi gia hạn locks: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchEvents(String venueId) async {
    try {
      var query = supabaseClient
          .from('events')
          .select()
          .eq('is_active', true);
      if (venueId.isNotEmpty) {
        query = query.eq('venue_id', venueId);
      }
      final response = await query.order('event_date', ascending: true);
      final list = List<Map<String, dynamic>>.from(response as List);

      // Kiểm tra hủy tự động các sự kiện không đủ người trước 2 tiếng
      final now = DateTime.now();
      final activeList = <Map<String, dynamic>>[];

      for (final ev in list) {
        final eventId = ev['id']?.toString() ?? '';
        final eventDateStr = ev['event_date']?.toString() ?? '';
        final startTimeStr = ev['start_time']?.toString() ?? '15:00';
        final endTimeStr = ev['end_time']?.toString() ?? '22:00';
        int minTickets = (ev['min_tickets'] as num?)?.toInt() ?? 0;
        if (minTickets <= 0) {
          final d = ev['description']?.toString() ?? '';
          final match = RegExp(r'\[min_tickets:\s*(\d+)\]').firstMatch(d);
          minTickets = match != null ? (int.tryParse(match.group(1) ?? '') ?? 2) : 2;
        }

        bool shouldCancel = false;
        bool isExpired = false;
        if (eventDateStr.isNotEmpty && eventId.isNotEmpty) {
          try {
            final cleanDate = eventDateStr.split('T')[0].split(' ')[0].trim();
            final dParts = cleanDate.split('-');
            final tParts = startTimeStr.split(':');
            final endParts = endTimeStr.split(':');

            if (dParts.length == 3) {
              final year = int.parse(dParts[0]);
              final month = int.parse(dParts[1]);
              final day = int.parse(dParts[2]);

              // 1. Kiểm tra sự kiện đã kết thúc chưa
              final endHour = endParts.isNotEmpty ? (int.tryParse(endParts[0]) ?? 23) : 23;
              final endMin = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 59) : 59;
              final endDateTime = DateTime(year, month, day, endHour, endMin);
              if (now.isAfter(endDateTime)) {
                isExpired = true;
              }

              // 2. Kiểm tra hủy tự động trước 2 tiếng nếu không đủ người
              final hour = tParts.isNotEmpty ? (int.tryParse(tParts[0]) ?? 6) : 6;
              final min = tParts.length > 1 ? (int.tryParse(tParts[1]) ?? 0) : 0;
              final startDateTime = DateTime(year, month, day, hour, min);
              final diffMinutes = startDateTime.difference(now).inMinutes;

              if (!isExpired && diffMinutes <= 120 && diffMinutes >= 0) {
                final bookedCount = await fetchBookedTicketsCount(eventId);
                if (bookedCount < minTickets) {
                  shouldCancel = true;
                }
              }
            }
          } catch (_) {}
        }

        if (isExpired) {
          continue; // Bỏ qua sự kiện đã hết hạn
        }

        if (shouldCancel) {
          try {
            // Tắt sự kiện và giải phóng các slot
            await supabaseClient.from('events').update({'is_active': false}).eq('id', eventId);
            await supabaseClient.from('event_slots').delete().eq('event_id', eventId);
            await supabaseClient.from('event_bookings').update({
              'status': 'cancelled',
              'note': 'Tự động hủy trước 2h do không đủ số lượng người đăng ký tối thiểu. Tiền vé đã được hoàn lại.',
            }).eq('event_id', eventId);
          } catch (_) {}
        } else {
          activeList.add(ev);
        }
      }

      return activeList;
    } catch (e) {
      debugPrint("Lỗi fetchEvents: $e");
      return [];
    }
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
    final cleanData = Map<String, dynamic>.from(bookingData);
    if (cleanData['user_id'] == null ||
        cleanData['user_id'] == 'guest_user' ||
        cleanData['user_id'].toString().isEmpty) {
      cleanData.remove('user_id');
    }
    final response = await supabaseClient
        .from('event_bookings')
        .insert(cleanData)
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