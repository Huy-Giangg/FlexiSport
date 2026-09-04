import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/owner/booking_management/data/models/owner_booking_model.dart';

class OwnerBookingRemoteDataSource {
  final SupabaseClient supabaseClient;

  OwnerBookingRemoteDataSource(this.supabaseClient);

  // Lấy danh sách đơn đặt sân thuộc cơ sở (kèm lọc ngày và trạng thái)
  Future<List<OwnerBookingModel>> fetchOwnerBookings({
    required String venueId,
    String? date,
    String? status,
  }) async {
    try {
      // 1. Lấy danh sách court IDs thuộc venueId
      List<String> courtIds = [];
      try {
        final courtsResponse = await supabaseClient
            .from('courts')
            .select('id')
            .eq('venue_id', venueId);

        courtIds = (courtsResponse as List)
            .map((c) => c['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      } catch (_) {}

      // 2. Query bookings có chứa booking_slots thuộc cơ sở này
      dynamic response;
      try {
        response = await supabaseClient
            .from('bookings')
            .select('*, booking_slots(*, courts(*, venues(*)))')
            .order('created_at', ascending: false);
      } catch (e) {
        debugPrint("Lỗi truy vấn bookings: $e");
        response = [];
      }

      final List<dynamic> list = response is List ? response : [];

      // Lọc các booking liên quan đến venue này
      final filteredList = list.where((item) {
        final itemVenueId = item['venue_id']?.toString();
        if (itemVenueId == venueId) return true;

        final slots = item['booking_slots'] as List?;
        if (slots != null && slots.isNotEmpty) {
          for (final s in slots) {
            final cId = s['court_id']?.toString();
            if (cId != null && courtIds.contains(cId)) return true;

            final c = s['courts'] as Map<String, dynamic>?;
            if (c != null && c['venue_id']?.toString() == venueId) {
              return true;
            }
          }
        }
        return false;
      }).toList();

      final result = filteredList.map((json) {
        return OwnerBookingModel.fromJson(json as Map<String, dynamic>);
      }).toList();

      return result;
    } catch (e) {
      debugPrint("Lỗi fetchOwnerBookings: $e");
      return [];
    }
  }

  // Cập nhật trạng thái đơn (pending -> confirmed, playing, completed, cancelled)
  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
    String? cancellationReason,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus,
      'booking_status': newStatus,
    };
    if (cancellationReason != null) {
      updateData['cancellation_reason'] = cancellationReason;
      updateData['note'] = cancellationReason;
    }

    try {
      await supabaseClient.from('bookings').update(updateData).eq('id', bookingId);
    } catch (_) {
      try {
        await supabaseClient.from('bookings').update({'status': newStatus}).eq('id', bookingId);
      } catch (e) {
        debugPrint("Lỗi updateBookingStatus: $e");
      }
    }
  }

  // Cập nhật trạng thái thanh toán (unpaid -> deposit_paid, paid, refunded)
  Future<void> updatePaymentStatus({
    required String bookingId,
    required String newPaymentStatus,
  }) async {
    try {
      await supabaseClient.from('bookings').update({
        'payment_status': newPaymentStatus,
      }).eq('id', bookingId);
    } catch (_) {
      // Bảng bookings có thể không có cột payment_status -> Thử cập nhật vào payments
      try {
        await supabaseClient.from('payments').update({
          'status': newPaymentStatus == 'paid' ? 'SUCCESS' : newPaymentStatus.toUpperCase(),
        }).eq('booking_id', bookingId);
      } catch (e) {
        debugPrint("Lỗi updatePaymentStatus: $e");
      }
    }
  }

  // Hủy đơn đặt sân và giải phóng slot
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    // 1. Cập nhật booking status = 'cancelled'
    try {
      await supabaseClient.from('bookings').update({
        'status': 'cancelled',
        'booking_status': 'cancelled',
        'payment_status': 'refunded',
        'cancellation_reason': reason,
        'note': reason,
      }).eq('id', bookingId);
    } catch (_) {
      try {
        await supabaseClient.from('bookings').update({
          'status': 'cancelled',
          'cancellation_reason': reason,
        }).eq('id', bookingId);
      } catch (_) {
        try {
          await supabaseClient.from('bookings').update({
            'status': 'cancelled',
            'note': reason,
          }).eq('id', bookingId);
        } catch (_) {
          await supabaseClient.from('bookings').update({
            'status': 'cancelled',
          }).eq('id', bookingId);
        }
      }
    }
  }

  // Tạo đơn đặt sân trực tiếp tại quầy cho khách vãng lai (Offline Walk-in Booking)
  Future<OwnerBookingModel> createWalkInBooking({
    required String venueId,
    required String courtId,
    required String bookingDate,
    required List<int> slotIndexes,
    required String customerName,
    required String customerPhone,
    required double totalPrice,
    required double depositAmount,
    String? notes,
  }) async {
    final user = supabaseClient.auth.currentUser;

    // 1. Xóa tạm thời các lock trong court_locks (nếu có) để tránh xung đột
    try {
      for (final slot in slotIndexes) {
        await supabaseClient
            .from('court_locks')
            .delete()
            .eq('court_id', courtId)
            .eq('booking_date', bookingDate)
            .eq('slot_index', slot);
      }
    } catch (_) {}

    // 2. Insert vào bảng bookings (chỉ dùng các cột chuẩn)
    final Map<String, dynamic> bookingPayload = {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount': totalPrice,
      'status': 'confirmed',
      'note': notes,
    };
    if (user != null) {
      bookingPayload['user_id'] = user.id;
    }

    final bookingInsert = await supabaseClient
        .from('bookings')
        .insert(bookingPayload)
        .select()
        .single();

    final bookingId = bookingInsert['id'].toString();

    // 3. Batch insert vào bảng booking_slots
    final List<Map<String, dynamic>> slotsToInsert = slotIndexes.map((slot) {
      return {
        'booking_id': bookingId,
        'court_id': courtId,
        'booking_date': bookingDate,
        'slot_index': slot,
      };
    }).toList();

    await supabaseClient.from('booking_slots').insert(slotsToInsert);

    // 4. Nếu có thanh toán/đặt cọc tại quầy -> Tạo bản ghi payments
    try {
      if (depositAmount > 0) {
        final paymentRef = 'WALKIN${DateTime.now().millisecondsSinceEpoch % 1000000}';
        await supabaseClient.from('payments').insert({
          'booking_id': bookingId,
          'payment_method': 'Tiền mặt tại quầy',
          'amount': depositAmount,
          'status': 'SUCCESS',
          'payment_reference': paymentRef,
          'paid_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}

    // 5. Query lại toàn bộ booking để trả về model đầy đủ
    final fullBooking = await supabaseClient
        .from('bookings')
        .select('*, booking_slots(*, courts(*, venues(*)))')
        .eq('id', bookingId)
        .single();

    return OwnerBookingModel.fromJson(fullBooking);
  }
}
