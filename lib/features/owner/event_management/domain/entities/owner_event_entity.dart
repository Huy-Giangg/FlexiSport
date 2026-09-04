class OwnerEventEntity {
  final String id;
  final String venueId;
  final String title;
  final String description;
  final String? bannerUrl;
  final String eventDate; // YYYY-MM-DD
  final bool isActive;
  final double ticketPrice;
  final int maxTickets;
  final int minTickets; // Số vé tối thiểu để tổ chức
  final String sportType;
  final String level;
  final String startTime;
  final String endTime;
  final String courtName;
  final int bookedTicketsCount;
  final double totalRevenue;
  final int attendeesCount;

  const OwnerEventEntity({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    this.bannerUrl,
    required this.eventDate,
    required this.isActive,
    required this.ticketPrice,
    required this.maxTickets,
    this.minTickets = 2,
    required this.sportType,
    required this.level,
    required this.startTime,
    required this.endTime,
    required this.courtName,
    this.bookedTicketsCount = 0,
    this.totalRevenue = 0.0,
    this.attendeesCount = 0,
  });

  bool get isSoldOut => bookedTicketsCount >= maxTickets && maxTickets > 0;
  bool get isUnderbooked => bookedTicketsCount < minTickets;

  DateTime? get startDateTime {
    if (eventDate.isEmpty) return null;
    try {
      final clean = eventDate.split('T')[0].split(' ')[0].trim();
      final parts = clean.split('-');
      if (parts.length != 3) return null;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      int startH = 6;
      int startM = 0;
      final tParts = startTime.split(':');
      if (tParts.length >= 2) {
        startH = int.tryParse(tParts[0]) ?? 6;
        startM = int.tryParse(tParts[1]) ?? 0;
      }
      return DateTime(year, month, day, startH, startM);
    } catch (_) {
      return null;
    }
  }

  // Còn dưới 2 tiếng trước giờ thi đấu
  bool get isWithinCancellationWindow {
    final start = startDateTime;
    if (start == null) return false;
    final diffInMinutes = start.difference(DateTime.now()).inMinutes;
    return diffInMinutes <= 120 && diffInMinutes >= 0;
  }

  // Đủ điều kiện tự động hủy do thiếu người trước 2 tiếng
  bool get shouldAutoCancel {
    final start = startDateTime;
    if (start == null) return false;
    final diffInMinutes = start.difference(DateTime.now()).inMinutes;
    return isActive && !hasPassed && diffInMinutes <= 120 && bookedTicketsCount < minTickets;
  }

  bool get hasPassed {
    if (eventDate.isEmpty) return false;
    try {
      final clean = eventDate.split('T')[0].split(' ')[0].trim();
      final parts = clean.split('-');
      if (parts.length != 3) return false;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      int endH = 22;
      int endM = 0;
      final tParts = endTime.split(':');
      if (tParts.length >= 2) {
        endH = int.tryParse(tParts[0]) ?? 22;
        endM = int.tryParse(tParts[1]) ?? 0;
      }

      final endDateTime = DateTime(year, month, day, endH, endM);
      return DateTime.now().isAfter(endDateTime);
    } catch (_) {
      return false;
    }
  }

  static String _cleanDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.split('T')[0].split(' ')[0].trim();
  }

  static String _cleanTime(String? raw, {String fallback = '15:00'}) {
    if (raw == null || raw.isEmpty) return fallback;
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      return "$h:$m";
    }
    return raw;
  }

  OwnerEventEntity copyWith({
    String? id,
    String? venueId,
    String? title,
    String? description,
    String? bannerUrl,
    String? eventDate,
    bool? isActive,
    double? ticketPrice,
    int? maxTickets,
    int? minTickets,
    String? sportType,
    String? level,
    String? startTime,
    String? endTime,
    String? courtName,
    int? bookedTicketsCount,
    double? totalRevenue,
    int? attendeesCount,
  }) {
    return OwnerEventEntity(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      title: title ?? this.title,
      description: description ?? this.description,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      eventDate: eventDate ?? this.eventDate,
      isActive: isActive ?? this.isActive,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      maxTickets: maxTickets ?? this.maxTickets,
      minTickets: minTickets ?? this.minTickets,
      sportType: sportType ?? this.sportType,
      level: level ?? this.level,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      courtName: courtName ?? this.courtName,
      bookedTicketsCount: bookedTicketsCount ?? this.bookedTicketsCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      attendeesCount: attendeesCount ?? this.attendeesCount,
    );
  }

  factory OwnerEventEntity.fromJson(
    Map<String, dynamic> json, {
    int bookedTickets = 0,
    double revenue = 0.0,
    int attendees = 0,
  }) {
    final maxT = (json['max_tickets'] as num?)?.toInt() ?? 10;
    final minT = (json['min_tickets'] as num?)?.toInt() ?? 2;

    return OwnerEventEntity(
      id: json['id']?.toString() ?? '',
      venueId: json['venue_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      bannerUrl: json['banner_url']?.toString(),
      eventDate: _cleanDate(json['event_date']?.toString()),
      isActive: json['is_active'] as bool? ?? true,
      ticketPrice: (json['ticket_price'] as num?)?.toDouble() ?? 0.0,
      maxTickets: maxT,
      minTickets: minT.clamp(1, maxT > 0 ? maxT : 10),
      sportType: json['sport_type']?.toString() ?? 'Pickleball',
      level: json['level']?.toString() ?? 'Mọi trình độ',
      startTime: _cleanTime(json['start_time']?.toString(), fallback: '15:00'),
      endTime: _cleanTime(json['end_time']?.toString(), fallback: '18:00'),
      courtName: json['court_name']?.toString() ?? 'Sân thi đấu',
      bookedTicketsCount: bookedTickets,
      totalRevenue: revenue,
      attendeesCount: attendees,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
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
