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
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_booking_transaction',
        params: {
          'p_user_id': userId == 'guest_user' ? null : userId,
          'p_total_amount': totalAmount,
          'p_customer_name': name,
          'p_customer_phone': phone,
          'p_note': note,
          'p_slots': slots, // JSON Array formatted slots
        },
      );

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

  /// Cancels booking on Supabase when payment countdown expires.
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase.rpc('cancel_expired_booking', params: {
        'p_booking_id': bookingId,
      });
    } catch (e) {
      // Ignore or log error on cancel
      print("Lỗi khi hủy booking hết hạn: $e");
    }
  }
}
