class EventEntity {
  final String id;
  final String venueId;
  final String title;
  final String description;
  final String? bannerUrl;
  final String eventDate;
  final bool isActive;
  final double ticketPrice;
  final int maxTickets;
  final int minTickets;
  final String sportType;
  final String level;
  final String startTime;
  final String endTime;
  final String courtName;

  EventEntity({
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
  });
}
