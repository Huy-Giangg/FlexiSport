import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  EventModel({
    required super.id,
    required super.venueId,
    required super.title,
    required super.description,
    super.bannerUrl,
    required super.eventDate,
    required super.isActive,
    required super.ticketPrice,
    required super.maxTickets,
    super.minTickets = 2,
    required super.sportType,
    required super.level,
    required super.startTime,
    required super.endTime,
    required super.courtName,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final maxT = (json['max_tickets'] as num?)?.toInt() ?? 10;
    int minT = (json['min_tickets'] as num?)?.toInt() ?? 0;

    final rawDesc = json['description']?.toString() ?? '';
    if (minT <= 0) {
      final match = RegExp(r'\[min_tickets:\s*(\d+)\]').firstMatch(rawDesc);
      if (match != null) {
        minT = int.tryParse(match.group(1) ?? '') ?? 2;
      } else {
        minT = 2;
      }
    }
    final cleanDesc = rawDesc.replaceAll(RegExp(r'\s*\[min_tickets:\s*\d+\]'), '').trim();

    return EventModel(
      id: json['id']?.toString() ?? '',
      venueId: json['venue_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: cleanDesc,
      bannerUrl: json['banner_url']?.toString(),
      eventDate: json['event_date']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? false,
      ticketPrice: (json['ticket_price'] as num?)?.toDouble() ?? 0.0,
      maxTickets: maxT,
      minTickets: minT.clamp(1, maxT > 0 ? maxT : 10),
      sportType: json['sport_type']?.toString() ?? 'Pickleball',
      level: json['level']?.toString() ?? 'Mọi trình độ',
      startTime: json['start_time']?.toString() ?? '15:00',
      endTime: json['end_time']?.toString() ?? '18:00',
      courtName: json['court_name']?.toString() ?? 'Sân 1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'title': title,
      'description': description,
      'banner_url': bannerUrl,
      'event_date': eventDate,
      'is_active': isActive,
      'ticket_price': ticketPrice,
      'max_tickets': maxTickets,
      'min_tickets': minTickets,
      'sport_type': sportType,
      'level': level,
      'start_time': startTime,
      'end_time': endTime,
      'court_name': courtName,
    };
  }
}
