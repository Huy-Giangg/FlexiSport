class OwnerEventAttendeeEntity {
  final String id;
  final String eventId;
  final String? userId;
  final String customerName;
  final String customerPhone;
  final int ticketCount;
  final double totalAmount;
  final String status; // 'confirmed', 'paid', 'completed', 'cancelled'
  final String? note;
  final DateTime createdAt;

  const OwnerEventAttendeeEntity({
    required this.id,
    required this.eventId,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.ticketCount,
    required this.totalAmount,
    required this.status,
    this.note,
    required this.createdAt,
  });

  bool get isPaid => status == 'completed' || status == 'paid' || status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  factory OwnerEventAttendeeEntity.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    return OwnerEventAttendeeEntity(
      id: json['id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['name']?.toString() ?? 'Khách tham gia',
      customerPhone: json['customer_phone']?.toString() ?? json['phone']?.toString() ?? 'Chưa có SĐT',
      ticketCount: (json['ticket_count'] as num?)?.toInt() ?? 1,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString().toLowerCase() ?? 'confirmed',
      note: json['note']?.toString() ?? json['notes']?.toString(),
      createdAt: parsedDate,
    );
  }
}
