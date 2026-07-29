import 'dart:ui' as ui;
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/home/presentation/widgets/ic_sport_map.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/sport_show_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Map<String, String> listIcon = {
    'Sân pickleball': 'assets/images/icon_sport/ic_pickleball.png',
    'Sân cầu lông': 'assets/images/icon_sport/ic_badminton.png',
    'Sân bóng đá': 'assets/images/icon_sport/ic_football.png',
    'Sân tennis': 'assets/images/icon_sport/ic_tennis.png',
    'Sân b.chuyền': 'assets/images/icon_sport/ic_voleball.png',
    'Sân bóng rổ': 'assets/images/icon_sport/ic_basketball.png',
    'Sân golf': 'assets/images/icon_sport/ic_golf.png',
  };

  final Map<String, String> sportFilterMap = {
    'Sân pickleball': 'pickleball',
    'Sân cầu lông': 'cầu lông',
    'Sân bóng đá': 'bóng đá',
    'Sân tennis': 'tennis',
    'Sân b.chuyền': 'bóng chuyền',
    'Sân bóng rổ': 'bóng rổ',
    'Sân golf': 'golf',
  };

  // 📍 Tọa độ mặc định (Hà Nội)
  static const LatLng _defaultLocation = LatLng(21.0538, 105.7355);

  // 🎮 Bộ điều khiển bản đồ
  GoogleMapController? mapController;

  // 🎨 Cache các custom icons từ assets
  final Map<String, BitmapDescriptor> _markerIcons = {};

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SportsComplexProvider>().fetchStadiums();
    });
  }

  Future<void> _loadMarkerIcons() async {
    final Map<String, String> iconPaths = {
      'pickleball': 'assets/images/icon_sport_map/ic_pickleball.png',
      'cầu lông': 'assets/images/icon_sport_map/ic_badminton.png',
      'bóng đá': 'assets/images/icon_sport_map/ic_football.png',
      'tennis': 'assets/images/icon_sport_map/ic_tennis.png',
      'bóng chuyền': 'assets/images/icon_sport_map/ic_voleball.png',
      'bóng rổ': 'assets/images/icon_sport_map/ic_basketball.png',
      'golf': 'assets/images/icon_sport_map/ic_golf.png',
    };

    final Map<String, Color> sportColors = {
      'pickleball': Colors.orange,
      'cầu lông': Colors.blue,
      'bóng đá': Colors.green,
      'tennis': Colors.purple,
      'bóng chuyền': Colors.amber,
      'bóng rổ': Colors.red,
      'golf': Colors.teal,
    };

    for (var entry in iconPaths.entries) {
      try {
        final ui.Image img = await _loadAssetImage(entry.value);
        final color = sportColors[entry.key] ?? Colors.redAccent;
        
        final BitmapDescriptor pinMarker = await _createLocationPinMarker(img, color);
        
        if (mounted) {
          setState(() {
            _markerIcons[entry.key] = pinMarker;
          });
        }
      } catch (e) {
        debugPrint('Lỗi tải/tạo marker pin cho ${entry.key}: $e');
      }
    }
  }

  Future<ui.Image> _loadAssetImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 100, // Kích thước load ảnh thô
      targetHeight: 100,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  Future<BitmapDescriptor> _createLocationPinMarker(ui.Image image, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(100, 100);
    
    // 1. Vẽ hình giọt nước (Location Pin)
    final path = Path();
    path.moveTo(50, 95); // Điểm nhọn phía dưới
    path.cubicTo(20, 65, 15, 50, 15, 35); // Cong bên trái
    path.arcToPoint(const Offset(85, 35), radius: const Radius.circular(35), clockwise: true); // Vòng tròn trên
    path.cubicTo(85, 50, 80, 65, 50, 95); // Cong bên phải
    path.close();
    
    // Tô màu nền cho Pin bản đồ
    final pinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, pinPaint);
    
    // Vẽ viền trắng tinh tế cho Pin
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(path, borderPaint);
    
    // 2. Vẽ vòng tròn trắng nhỏ ở trung tâm để chứa hình icon
    final whiteCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(50, 35), 23, whiteCirclePaint);
    
    // 3. Vẽ hình ảnh Flaticon (đã resize) vào giữa vòng tròn trắng
    const double imageSize = 34.0;
    final Rect destRect = Rect.fromLTWH(
      50 - imageSize / 2,
      35 - imageSize / 2,
      imageSize,
      imageSize,
    );
    
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destRect,
      Paint(),
    );
    
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  BitmapDescriptor _getMarkerIcon(String name, String? sportsType) {
    final lowercaseName = name.toLowerCase();
    final lowercaseType = sportsType?.toLowerCase() ?? '';
    
    if (lowercaseName.contains('pickleball') || lowercaseType.contains('pickleball')) return _markerIcons['pickleball'] ?? BitmapDescriptor.defaultMarker;
    if (lowercaseName.contains('cầu lông') || lowercaseName.contains('badminton') || lowercaseType.contains('cầu lông') || lowercaseType.contains('badminton')) return _markerIcons['cầu lông'] ?? BitmapDescriptor.defaultMarker;
    if (lowercaseName.contains('bóng đá') || lowercaseName.contains('football') || lowercaseName.contains('soccer') || lowercaseType.contains('bóng đá') || lowercaseType.contains('football') || lowercaseType.contains('soccer')) return _markerIcons['bóng đá'] ?? BitmapDescriptor.defaultMarker;
    if (lowercaseName.contains('tennis') || lowercaseType.contains('tennis')) return _markerIcons['tennis'] ?? BitmapDescriptor.defaultMarker;
    if (lowercaseName.contains('bóng chuyền') || lowercaseName.contains('volleyball') || lowercaseType.contains('bóng chuyền') || lowercaseType.contains('b.chuyền') || lowercaseType.contains('volleyball')) return _markerIcons['bóng chuyền'] ?? BitmapDescriptor.defaultMarker;
    if (lowercaseName.contains('bóng rổ') || lowercaseName.contains('basketball') || lowercaseType.contains('bóng rổ') || lowercaseType.contains('basketball')) return _markerIcons['bóng rổ'] ?? BitmapDescriptor.defaultMarker;
    if (lowercaseName.contains('golf') || lowercaseType.contains('golf')) return _markerIcons['golf'] ?? BitmapDescriptor.defaultMarker;
    
    return BitmapDescriptor.defaultMarker;
  }

  void _showVenueDetails(SportsComplexEntity venue) {
    final mainPageProvider = context.read<MainPageProvider>();
    mainPageProvider.hideNavbar();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SportShowDetail(sportsComplexEntity: venue);
      },
    ).whenComplete(() {
      mainPageProvider.showNavbar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SportsComplexProvider>();
    final stadiums = provider.filteredStadiums;
    final selectedSport = provider.selectedSport;
    final entries = listIcon.entries.toList();

    // Tạo markers từ dữ liệu stadiums lấy từ database
    final Set<Marker> markers = stadiums
        .where((s) => s.latitude != null && s.longitude != null)
        .map((s) {
          return Marker(
            markerId: MarkerId(s.id),
            position: LatLng(s.latitude!, s.longitude!),
            onTap: () {
              _showVenueDetails(s);
            },
            icon: _getMarkerIcon(s.name, s.sportsType),
          );
        })
        .toSet();

    // Thêm marker giọt nước đỏ tại vị trí mặc định
    markers.add(
      const Marker(
        markerId: MarkerId('default_user_location_pin'),
        position: _defaultLocation,
        infoWindow: InfoWindow(title: 'Vị trí mặc định'),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 13.5,
            ),
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Search Bar
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
                      onChanged: (value) {
                        provider.setSearchQuery(value);
                      },
                      decoration: InputDecoration(
                        prefixIcon: Image.asset(
                          'assets/images/ic_alobo-removebg.png',
                        ),
                        contentPadding: const EdgeInsets.all(10),
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

          // Horizontal Sports Filter
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
                  final filterValue = sportFilterMap[nameSport] ?? '';
                  final isSelected = selectedSport == filterValue;

                  return GestureDetector(
                    onTap: () {
                      provider.selectSport(filterValue);
                    },
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(0),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF006D38) : Colors.white, // Màu xanh nhạt khi chọn
                        border: isSelected
                            ? Border.all(color: const Color(0xFF006D38), width: 1.5)
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: IcSportMap(title: nameSport, textStyle: TextStyle(color: isSelected? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold),),
                    ),
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
