import 'package:flexisport_app/features/profile/domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    required super.birthYear,
    required super.gender,
    required super.height,
    required super.weight,
  });

  // Chuyển từ JSON (Map) lấy từ cơ sở dữ liệu sang Model
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      birthYear: (json['birth_year'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Chuyển từ Model sang JSON (Map) để lưu trữ lên cơ sở dữ liệu
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'birth_year': birthYear,
      'gender': gender,
      'height': height,
      'weight': weight,
    };
  }

  // Tiện ích giúp sao chép đối tượng với một vài thay đổi thuộc tính
  ProfileModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    int? birthYear,
    String? gender,
    double? height,
    double? weight,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}
