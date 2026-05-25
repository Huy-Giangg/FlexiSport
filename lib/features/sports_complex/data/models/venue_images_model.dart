import 'package:flexisport_app/features/sports_complex/domain/entities/venue_images_entity.dart';

class VenueImageModel extends VenueImageEntity {
  const VenueImageModel({
    required super.id,
    required super.venueId,
    required super.imageUrl,
  });

  // Chuyển đổi từ Map (kết quả truy vấn DB/API) sang Model
  factory VenueImageModel.fromJson(Map<String, dynamic> json) {
    return VenueImageModel(
      id: json['id'] as String,
      venueId: json['venue_id'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  // Chuyển đổi từ Model sang Map để lưu trữ hoặc gửi đi
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'image_url': imageUrl,
    };
  }

  // Phương thức hỗ trợ chuyển đổi nhanh từ Model sang Entity (nếu cần)
  VenueImageEntity toEntity() => VenueImageEntity(
        id: id,
        venueId: venueId,
        imageUrl: imageUrl,
      );
}