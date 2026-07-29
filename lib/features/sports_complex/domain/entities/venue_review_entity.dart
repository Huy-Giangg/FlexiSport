class VenueReviewEntity {
  final String id;
  final String bookingId;
  final String venueId;
  final String userId;
  final double rating;
  final String content;
  final DateTime createdAt;
  final String userName; // Tên hiển thị người dùng từ bảng profiles

  VenueReviewEntity({
    required this.id,
    required this.bookingId,
    required this.venueId,
    required this.userId,
    required this.rating,
    required this.content,
    required this.createdAt,
    required this.userName,
  });
}
