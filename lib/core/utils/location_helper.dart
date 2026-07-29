import 'dart:math';

class LocationHelper {
  // 📍 Tọa độ mặc định (Hà Nội)
  static const double defaultLatitude = 21.0538;
  static const double defaultLongitude = 105.7355;

  /// Tính khoảng cách giữa hai tọa độ (theo km) sử dụng công thức Haversine
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Bán kính Trái Đất (km)

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2)).clamp(0.0, 1.0);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Tính khoảng cách từ vị trí mặc định đến tọa độ của sân
  static double calculateDistanceFromDefault(double? targetLat, double? targetLon) {
    if (targetLat == null || targetLon == null) return 0.0;
    return calculateDistance(defaultLatitude, defaultLongitude, targetLat, targetLon);
  }

  /// Định dạng khoảng cách hiển thị đẹp mắt (VD: "850 m" hoặc "2.3 km")
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1.0) {
      int meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
