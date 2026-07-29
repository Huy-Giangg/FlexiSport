// Entity đại diện cho Thông tin người dùng (Profile)
class ProfileEntity {
  final String id;
  final String name;
  final String phone;
  final String email;
  final int birthYear;
  final String gender;
  final double height;
  final double weight;

  ProfileEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.birthYear,
    required this.gender,
    required this.height,
    required this.weight,
  });
}
