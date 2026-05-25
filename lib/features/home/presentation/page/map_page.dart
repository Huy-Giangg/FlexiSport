import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/home/presentation/widgets/ic_sport.dart';
import 'package:flexisport_app/features/home/presentation/widgets/ic_sport_map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Map<String, String> listIcon = {
    'Sân pickleball': 'assets/images/icon_sport/ic_pickleball.png',
    'Sân cầu lông': 'assets/images/icon_sport/ic_badminton.png',
    'Sân bóng đá': 'assets/images/icon_sport/ic_football.png',
    'Sân tennis': 'assets/images/icon_sport/ic_tennis.png',
    'Sân b.chuyền': 'assets/images/icon_sport/ic_voleball.png',
    'Sân bóng rổ': 'assets/images/icon_sport/ic_basketball.png',
    'Sân golf': 'assets/images/icon_sport/ic_golf.png',
  };

  // 📍 Tọa độ của sân bóng (Ví dụ: Sân Thống Nhất)
  static const LatLng _sanBongLocation = LatLng(10.7613, 106.6622);

  // 🎮 Bộ điều khiển bản đồ
  late GoogleMapController mapController;

  // 🚩 Tập hợp các điểm đánh dấu trên bản đồ
  final Set<Marker> _markers = {
    Marker(
      markerId: MarkerId('san_bong_01'),
      position: _sanBongLocation,
      infoWindow: InfoWindow(
        title: 'Sân Bóng Đá Mini',
        snippet: 'Địa chỉ: 123 Đường ABC, Quận 1',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      ), // Màu xanh lá cho sân bóng
    ),
  };

  @override
  Widget build(BuildContext context) {
    final entries = listIcon.entries.toList();
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            // Cấu hình ban đầu
            initialCameraPosition: CameraPosition(
              target: _sanBongLocation,
              zoom: 16.0, // Độ phóng to (từ 1 - 20)
            ),
            // Hiển thị các điểm đánh dấu
            markers: _markers,
            // Khi bản đồ sẵn sàng
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            // Bật nút "Vị trí của tôi" (nếu đã xin quyền)
            myLocationEnabled: true,
          ),

          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: Image.asset(
                          'assets/images/ic_alobo-removebg.png',
                        ),
                        contentPadding: EdgeInsets.all(10),
                        border: InputBorder.none,
                        hintText: "Tìm kiếm sân quanh đây",
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: Icon(
                          Icons.search,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 90,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 66,
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: listIcon.length,

                itemBuilder: (context, index) {
                  final nameSport = entries[index].key;
                  final imgPath = entries[index].value;
                  return Container(
                    width: 160,
                    padding: const EdgeInsets.all(0),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5)
                        )
                      ]
                    ),
                    child: IcSportMap(title: nameSport, imgPath: imgPath),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
