import 'package:flexisport_app/features/customer/booking/data/models/event_model.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_booking_entity.dart';

class EventBookingModel extends EventBookingEntity {
  EventBookingModel({
    required super.id,
    required super.eventId,
    super.userId,
    required super.ticketCount,
    required super.totalAmount,
    required super.status,
    required super.customerName,
    required super.customerPhone,
    super.note,
    required super.createdAt,
    super.event,
  });

  factory EventBookingModel.fromJson(Map<String, dynamic> json) {
    return EventBookingModel(
      id: json['id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      ticketCount: json['ticket_count'] as int? ?? 1,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      event: json['events'] != null ? EventModel.fromJson(json['events'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'ticket_count': ticketCount,
      'total_amount': totalAmount,
      'status': status,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'note': note,
      'created_at': createdAt,
    };
  }
}
