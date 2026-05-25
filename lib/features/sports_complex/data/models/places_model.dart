class PlaceModel {
  final String name;
  final String address;
  final double lat;
  final double lng;

  PlaceModel({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  // Hàm chuyển đổi từ JSON sang Object
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      name: json['name'] ?? '',
      address: json['vicinity'] ?? '',
      lat: json['geometry']['location']['lat'],
      lng: json['geometry']['location']['lng'],
    );
  }
}