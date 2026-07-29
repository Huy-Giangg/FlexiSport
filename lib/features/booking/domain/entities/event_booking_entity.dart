import 'package:flexisport_app/features/booking/domain/entities/event_entity.dart';

class EventBookingEntity {
  final String id;
  final String eventId;
  final String? userId;
  final int ticketCount;
  final double totalAmount;
  final String status;
  final String customerName;
  final String customerPhone;
  final String? note;
  final String createdAt;
  final EventEntity? event;

  EventBookingEntity({
    required this.id,
    required this.eventId,
    this.userId,
    required this.ticketCount,
    required this.totalAmount,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    this.note,
    required this.createdAt,
    this.event,
  });
}
