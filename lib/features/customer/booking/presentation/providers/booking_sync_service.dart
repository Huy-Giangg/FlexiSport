import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BookingSyncService {
  static Future<void> syncGuestBookings(String loggedInUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Đồng bộ đặt sân thường (bookings)
      final List<String> guestBookingIds = prefs.getStringList('guest_booking_ids') ?? [];
      if (guestBookingIds.isNotEmpty) {
        await Supabase.instance.client
            .from('bookings')
            .update({'user_id': loggedInUserId})
            .inFilter('id', guestBookingIds);
            
        // Xóa danh sách tạm sau khi đồng bộ thành công
        await prefs.remove('guest_booking_ids');
        debugPrint("Đồng bộ hóa đặt sân vãng lai thành công cho user: $loggedInUserId");
      }

      // 2. Đồng bộ đặt vé sự kiện (event_bookings)
      final List<String> guestEventBookingIds = prefs.getStringList('guest_event_booking_ids') ?? [];
      if (guestEventBookingIds.isNotEmpty) {
        await Supabase.instance.client
            .from('event_bookings')
            .update({'user_id': loggedInUserId})
            .inFilter('id', guestEventBookingIds);
            
        await prefs.remove('guest_event_booking_ids');
        debugPrint("Đồng bộ hóa vé sự kiện vãng lai thành công cho user: $loggedInUserId");
      }
    } catch (e) {
      debugPrint("Lỗi khi đồng bộ hóa lịch đặt vãng lai: $e");
    }
  }
}
