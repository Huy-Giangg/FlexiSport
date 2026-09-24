import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingTransactionResult {
  final String bookingId;
  final String paymentReference;

  BookingTransactionResult({
    required this.bookingId,
    required this.paymentReference,
  });
}

class PaymentRemoteDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates booking and payment entries on Supabase inside a transaction.
  /// Returns the bookingId and unique paymentReference.
  Future<BookingTransactionResult> createBookingTransaction({
    required String? userId,
    required double totalAmount,
    required String name,
    required String phone,
    required String note,
    required List<Map<String, dynamic>> slots,
    String? lockToken,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_user_id': (userId == 'guest_user' || userId == null || userId.isEmpty) ? null : userId,
        'p_total_amount': totalAmount,
        'p_customer_name': name,
        'p_customer_phone': phone,
        'p_note': note,
        'p_slots': slots,
        'p_lock_token': lockToken,
      };

      dynamic response;
      try {
        response = await _supabase.rpc('create_booking_transaction', params: params);
      } catch (rpcErr) {
        // Chỉ fallback nếu DB đang dùng hàm cũ chưa hỗ trợ tham số p_lock_token
        if (rpcErr.toString().contains('p_lock_token') || rpcErr.toString().contains('PGRST202')) {
          params.remove('p_lock_token');
          response = await _supabase.rpc('create_booking_transaction', params: params);
        } else {
          rethrow;
        }
      }

      if (response == null) {
        throw Exception("Không thể khởi tạo giao dịch thanh toán.");
      }

      final data = Map<String, dynamic>.from(response as Map);
      return BookingTransactionResult(
        bookingId: data['booking_id'].toString(),
        paymentReference: data['payment_reference'].toString(),
      );
    } catch (e) {
      throw Exception("Lỗi khi tạo giao dịch thanh toán: $e");
    }
  }

  /// Cancels booking on Supabase when payment countdown expires or user exits.
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase.rpc('cancel_expired_booking', params: {
        'p_booking_id': bookingId,
      });
    } catch (e) {
      debugPrint("Lỗi RPC cancel_expired_booking: $e");
    }

    // Dự phòng trực tiếp từ client để đảm bảo 100% giải phóng booking và slots ngay lập tức
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId)
          .eq('status', 'pending_payment');

      await _supabase
          .from('booking_slots')
          .delete()
          .eq('booking_id', bookingId);

      await _supabase
          .from('payments')
          .update({'status': 'FAILED'})
          .eq('booking_id', bookingId)
          .eq('status', 'PENDING');
    } catch (e2) {
      debugPrint("Lỗi fallback cancelBooking client: $e2");
    }
  }
}
