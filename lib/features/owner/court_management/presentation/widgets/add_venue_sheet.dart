import 'dart:io';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AddVenueSheet extends StatefulWidget {
  final Future<bool> Function({
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    XFile? imageFile,
  }) onSave;

  const AddVenueSheet({
    super.key,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<bool> Function({
      required String name,
      required String address,
      required String openTime,
      required String closeTime,
      String? sportsType,
      XFile? imageFile,
    }) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVenueSheet(onSave: onSave),
    );
  }

  @override
  State<AddVenueSheet> createState() => _AddVenueSheetState();
}

class _AddVenueSheetState extends State<AddVenueSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _streetDetailController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isSubmitting = false;

  // Giờ mở / đóng cửa
  String _selectedOpenTime = '06:00';
  String _selectedCloseTime = '22:00';

  final List<String> _timeSlots = [
    '05:00', '05:30', '06:00', '06:30', '07:00', '07:30',
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30', '21:00', '21:30', '22:00', '22:30',
    '23:00', '23:30', '00:00',
  ];

  // Môn thể thao chính
  String _selectedSportType = 'Pickleball';
  final List<String> _sportTypes = [
    'Pickleball',
    'Cầu lông',
    'Bóng đá',
    'Tennis',
    'Bóng rổ',
    'Bóng chuyền',
    'Golf',
    'Đa năng',
  ];

  // --- DỮ LIỆU ĐỊA GIỚI HÀNH CHÍNH VIỆT NAM ---
  String _selectedProvince = 'Hà Nội';
  String _selectedDistrict = 'Ba Đình';
  String _selectedWard = 'Thụy Khuê';

  final Map<String, Map<String, List<String>>> _vietnamAddressData = {
    'Hà Nội': {
      'Ba Đình': ['Thụy Khuê', 'Cống Vị', 'Điện Biên', 'Đội Cấn', 'Giảng Võ', 'Kim Mã', 'Liễu Giai', 'Ngọc Hà', 'Ngọc Khánh', 'Nguyễn Trung Trực', 'Phúc Xá', 'Quán Thánh', 'Thành Công', 'Trúc Bạch', 'Vĩnh Phúc'],
      'Cầu Giấy': ['Dịch Vọng', 'Dịch Vọng Hậu', 'Mai Dịch', 'Nghĩa Đô', 'Nghĩa Tân', 'Quan Hoa', 'Trung Hòa', 'Yên Hòa'],
      'Đống Đa': ['Cát Linh', 'Hàng Bột', 'Khâm Thiên', 'Khương Thượng', 'Kim Liên', 'Láng Hạ', 'Láng Thượng', 'Nam Đồng', 'Ô Chợ Dừa', 'Phương Liệt', 'Phương Mai', 'Quang Trung', 'Quốc Tử Giám', 'Thịnh Quang', 'Thổ Quan', 'Trung Liệt', 'Trung Tự', 'Văn Miếu'],
      'Tây Hồ': ['Bưởi', 'Nhật Tân', 'Phú Thượng', 'Quảng An', 'Thụy Khuê', 'Tứ Liên', 'Xuân La', 'Yên Phụ'],
      'Thanh Xuân': ['Hạ Đình', 'Khương Đình', 'Khương Mai', 'Khương Trung', 'Kim Giang', 'Nhân Chính', 'Thanh Xuân Bắc', 'Thanh Xuân Nam', 'Thanh Xuân Trung', 'Thượng Đình'],
      'Hoàn Kiếm': ['Cửa Đông', 'Cửa Nam', 'Chương Dương', 'Đồng Xuân', 'Hàng Bạc', 'Hàng Bài', 'Hàng Bồ', 'Hàng Bông', 'Hàng Buồm', 'Hàng Đào', 'Hàng Gai', 'Hàng Mã', 'Hàng Trống', 'Lý Thường Kiệt', 'Phan Chu Trinh', 'Phúc Tân', 'Tràng Tiền', 'Trần Hưng Đạo'],
      'Hai Bà Trưng': ['Bạch Đằng', 'Bách Khoa', 'Bạch Mai', 'Cầu Dền', 'Đồng Nhân', 'Đồng Tâm', 'Lê Đại Hành', 'Minh Khai', 'Nguyễn Du', 'Phạm Đình Hổ', 'Phố Huế', 'Quỳnh Lôi', 'Quỳnh Mai', 'Thanh Nhàn', 'Trương Định', 'Vĩnh Tuy'],
      'Nam Từ Liêm': ['Cầu Diễn', 'Đại Mỗ', 'Mễ Trì', 'Mỹ Đình 1', 'Mỹ Đình 2', 'Phú Đô', 'Tây Mỗ', 'Phương Canh', 'Xuân Phương', 'Trung Văn'],
      'Bắc Từ Liêm': ['Cổ Nhuế 1', 'Cổ Nhuế 2', 'Đông Ngạc', 'Đức Thắng', 'Liên Mạc', 'Minh Khai', 'Phú Diễn', 'Phúc Diễn', 'Tây Tựu', 'Thượng Cát', 'Thụy Phương', 'Xuân Đỉnh', 'Xuân Tảo'],
      'Hà Đông': ['Biên Giang', 'Đồng Mai', 'Dương Nội', 'Hà Cầu', 'Kiến Hưng', 'La Khê', 'Mộ Lao', 'Nguyễn Trãi', 'Phú La', 'Phúc La', 'Quang Trung', 'Vạn Phúc', 'Văn Quán', 'Yên Nghĩa', 'Yết Kiêu'],
      'Long Biên': ['Bồ Đề', 'Cự Khối', 'Đức Giang', 'Gia Thụy', 'Giang Biên', 'Long Biên', 'Ngọc Lâm', 'Ngọc Thụy', 'Phúc Đồng', 'Phúc Lợi', 'Sài Đồng', 'Thạch Bàn', 'Thượng Thanh', 'Việt Hưng'],
      'Hoàng Mai': ['Đại Kim', 'Định Công', 'Giáp Bát', 'Hoàng Liệt', 'Hoàng Văn Thụ', 'Lĩnh Nam', 'Mai Động', 'Tân Mai', 'Thịnh Liệt', 'Trần Phú', 'Tương Mai', 'Vĩnh Hưng', 'Yên Sở'],
    },
    'TP. Hồ Chí Minh': {
      'Quận 1': ['Bến Nghé', 'Bến Thành', 'Cầu Kho', 'Cầu Ông Lãnh', 'Cô Giang', 'Đa Kao', 'Nguyễn Cư Trinh', 'Nguyễn Thái Bình', 'Phạm Ngũ Lão', 'Tân Định'],
      'Quận 3': ['Phường 1', 'Phường 2', 'Phường 3', 'Phường 4', 'Phường 5', 'Phường 9', 'Phường 10', 'Phường 11', 'Phường 12', 'Phường 14', 'Võ Thị Sáu'],
      'Quận 7': ['Tân Thuận Đông', 'Tân Thuận Tây', 'Tân Kiểng', 'Tân Hưng', 'Bình Thuận', 'Tân Quy', 'Phú Thuận', 'Tân Phú', 'Tân Phong', 'Phú Mỹ'],
      'Bình Thạnh': ['Phường 1', 'Phường 2', 'Phường 3', 'Phường 5', 'Phường 6', 'Phường 7', 'Phường 11', 'Phường 12', 'Phường 13', 'Phường 14', 'Phường 15', 'Phường 17', 'Phường 19', 'Phường 21', 'Phường 22', 'Phường 24', 'Phường 25', 'Phường 26', 'Phường 27', 'Phường 28'],
      'TP. Thủ Đức': ['Hiệp Bình Chánh', 'Hiệp Bình Phước', 'Linh Chiểu', 'Linh Đông', 'Linh Tây', 'Linh Trung', 'Linh Xuân', 'Bình Thọ', 'Tam Bình', 'Tam Phú', 'Trường Thọ', 'Thảo Điền', 'An Phú', 'An Khánh', 'Bình Trưng Đông', 'Bình Trưng Tây'],
      'Tân Bình': ['Phường 1', 'Phường 2', 'Phường 3', 'Phường 4', 'Phường 5', 'Phường 6', 'Phường 7', 'Phường 8', 'Phường 9', 'Phường 10', 'Phường 11', 'Phường 12', 'Phường 13', 'Phường 14', 'Phường 15'],
      'Gò Vấp': ['Phường 1', 'Phường 3', 'Phường 4', 'Phường 5', 'Phường 6', 'Phường 7', 'Phường 8', 'Phường 9', 'Phường 10', 'Phường 11', 'Phường 12', 'Phường 13', 'Phường 14', 'Phường 15', 'Phường 16', 'Phường 17'],
      'Phú Nhuận': ['Phường 1', 'Phường 2', 'Phường 3', 'Phường 4', 'Phường 5', 'Phường 7', 'Phường 8', 'Phường 9', 'Phường 10', 'Phường 11', 'Phường 13', 'Phường 15', 'Phường 17'],
    },
    'Đà Nẵng': {
      'Hải Châu': ['Hải Châu 1', 'Hải Châu 2', 'Thạch Thang', 'Thanh Bình', 'Thuận Phước', 'Hòa Thuận Đông', 'Hòa Thuận Tây', 'Nam Dương', 'Phước Ninh', 'Bình Hiên', 'Bình Thuận', 'Hòa Cường Bắc', 'Hòa Cường Nam'],
      'Thanh Khê': ['Tam Thuận', 'Thanh Khê Tây', 'Thanh Khê Đông', 'Xuân Hà', 'Tân Chính', 'Chính Gián', 'Vĩnh Trung', 'Thạc Gián', 'An Khê', 'Hòa Khê'],
      'Sơn Trà': ['An Hải Bắc', 'An Hải Đông', 'An Hải Tây', 'Mân Thái', 'Nại Hiên Đông', 'Phước Mỹ', 'Thọ Quang'],
      'Ngũ Hành Sơn': ['Mỹ An', 'Khuê Mỹ', 'Hòa Quý', 'Hòa Hải'],
      'Cẩm Lệ': ['Khuê Trung', 'Hòa Thọ Đông', 'Hòa Thọ Tây', 'Hòa An', 'Hòa Phát', 'Hòa Xuân'],
    },
    'Hải Phòng': {
      'Hồng Bàng': ['Hoàng Văn Thụ', 'Minh Khai', 'Phan Bội Châu', 'Quán Toan', 'Sở Dầu', 'Thượng Lý', 'Trại Chuối'],
      'Ngô Quyền': ['Cầu Đất', 'Cầu Tre', 'Đằng Giang', 'Đông Khê', 'Lạc Viên', 'Lạch Tray', 'Lê Lợi', 'Máy Chai', 'Máy Tơ', 'Vạn Mỹ'],
      'Lê Chân': ['An Biên', 'An Dương', 'Cát Dài', 'Đông Hải', 'Dư Hàng', 'Dư Hàng Kênh', 'Hàng Kênh', 'Hồ Nam', 'Kênh Dương', 'Lam Sơn', 'Niệm Nghĩa', 'Nghĩa Xá', 'Trần Nguyên Hãn', 'Vĩnh Niệm'],
    },
    'Cần Thơ': {
      'Ninh Kiều': ['An Bình', 'An Cư', 'An Hòa', 'An Khánh', 'An Nghiệp', 'An Phú', 'Cái Khế', 'Hưng Lợi', 'Tân An', 'Thới Bình', 'Xuân Khánh'],
      'Cái Răng': ['Ba Láng', 'Hưng Phú', 'Hưng Thạnh', 'Lê Bình', 'Phú Thứ', 'Tân Phú'],
      'Bình Thủy': ['An Thới', 'Bình Thủy', 'Bùi Hữu Nghĩa', 'Long Hòa', 'Long Tuyền', 'Thới An Đông', 'Trà An', 'Trà Nóc'],
    },
    'Bình Dương': {
      'Thủ Dầu Một': ['Chánh Mỹ', 'Chánh Nghĩa', 'Định Hòa', 'Hiệp An', 'Hiệp Thành', 'Hòa Phú', 'Phú Cường', 'Phú Hòa', 'Phú Lợi', 'Phú Mỹ', 'Phú Tân', 'Phú Thọ', 'Tân An', 'Tương Bình Hiệp'],
      'Dĩ An': ['An Bình', 'Bình An', 'Bình Thắng', 'Dĩ An', 'Đông Hòa', 'Tân Bình', 'Tân Đông Hiệp'],
      'Thuận An': ['An Phú', 'An Thạnh', 'Bình Chuẩn', 'Bình Hòa', 'Bình Nhâm', 'Hưng Định', 'Lái Thiêu', 'Thuận Giao', 'Vĩnh Phú'],
    },
  };

  @override
  void initState() {
    super.initState();
    _initAddressState();
  }

  void _initAddressState() {
    final districts = _vietnamAddressData[_selectedProvince]?.keys.toList() ?? [];
    if (districts.isNotEmpty && !districts.contains(_selectedDistrict)) {
      _selectedDistrict = districts.first;
    }
    final wards = _vietnamAddressData[_selectedProvince]?[_selectedDistrict] ?? [];
    if (wards.isNotEmpty && !wards.contains(_selectedWard)) {
      _selectedWard = wards.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetDetailController.dispose();
    super.dispose();
  }

  // Chọn ảnh từ thiết bị
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Chọn hình ảnh cơ sở / sân",
                style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: Text("Chọn từ Thư viện", style: GoogleFonts.lexend(fontSize: 14)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0288D1)),
                ),
                title: Text("Chụp ảnh mới", style: GoogleFonts.lexend(fontSize: 14)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: Text("Xóa ảnh đã chọn", style: GoogleFonts.lexend(fontSize: 14, color: Colors.red)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() => _selectedImage = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildFullAddress() {
    final street = _streetDetailController.text.trim();
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (_selectedWard.isNotEmpty) parts.add("Phường $_selectedWard");
    if (_selectedDistrict.isNotEmpty) parts.add("Quận $_selectedDistrict");
    if (_selectedProvince.isNotEmpty) parts.add(_selectedProvince);
    return parts.join(', ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final fullAddress = _buildFullAddress();
    if (fullAddress.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng nhập địa chỉ chi tiết", style: GoogleFonts.lexend()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.onSave(
      name: _nameController.text.trim(),
      address: fullAddress,
      openTime: _selectedOpenTime,
      closeTime: _selectedCloseTime,
      sportsType: _selectedSportType,
      imageFile: _selectedImage,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableDistricts = _vietnamAddressData[_selectedProvince]?.keys.toList() ?? [];
    final availableWards = _vietnamAddressData[_selectedProvince]?[_selectedDistrict] ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_business_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Thêm cụm sân mới",
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. KHU VỰC UPLOAD HÌNH ẢNH CƠ SỞ
              Text(
                "Hình ảnh đại diện cơ sở / sân",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showImagePickerModal,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null ? AppColors.primary : Colors.grey.shade300,
                      width: _selectedImage != null ? 1.5 : 1,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tải lên hình ảnh sân (Tùy chọn)",
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Chạm để chọn từ thư viện hoặc chụp ảnh",
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. TÊN CỤM SÂN
              Text(
                "Tên cơ sở / cụm sân *",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Ví dụ: FlexiSport Ba Đình Complex",
                  hintStyle: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.stadium_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên cụm sân' : null,
              ),
              const SizedBox(height: 16),

              // 3. MÔN THỂ THAO CHÍNH
              Text(
                "Môn thể thao chính",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedSportType,
                style: GoogleFonts.lexend(fontSize: 14, color: AppColors.onBackground),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.sports_tennis_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: _sportTypes.map((sport) {
                  return DropdownMenuItem(
                    value: sport,
                    child: Text(sport),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSportType = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // 4. BỘ CHỌN ĐỊA CHỈ CHUYÊN NGHIỆP (TỈNH/TP -> QUẬN/HUYỆN -> PHƯỜNG/XÃ)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Địa chỉ cơ sở (Chọn theo danh mục)",
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tỉnh / Thành phố
                    Text(
                      "Tỉnh / Thành phố",
                      style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      key: ValueKey('province_$_selectedProvince'),
                      initialValue: _selectedProvince,
                      isExpanded: true,
                      style: GoogleFonts.lexend(fontSize: 13, color: AppColors.onBackground),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: _vietnamAddressData.keys.map((prov) {
                        return DropdownMenuItem(value: prov, child: Text(prov));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != _selectedProvince) {
                          setState(() {
                            _selectedProvince = val;
                            final districts = _vietnamAddressData[val]?.keys.toList() ?? [];
                            _selectedDistrict = districts.isNotEmpty ? districts.first : '';
                            final wards = _vietnamAddressData[val]?[_selectedDistrict] ?? [];
                            _selectedWard = wards.isNotEmpty ? wards.first : '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Quận / Huyện & Phường / Xã (2 cột)
                    Row(
                      children: [
                        // Quận / Huyện
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quận / Huyện",
                                style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                key: ValueKey('district_${_selectedProvince}_$_selectedDistrict'),
                                initialValue: availableDistricts.contains(_selectedDistrict) ? _selectedDistrict : (availableDistricts.isNotEmpty ? availableDistricts.first : null),
                                isExpanded: true,
                                style: GoogleFonts.lexend(fontSize: 13, color: AppColors.onBackground),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                items: availableDistricts.map((dist) {
                                  return DropdownMenuItem(value: dist, child: Text(dist));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null && val != _selectedDistrict) {
                                    setState(() {
                                      _selectedDistrict = val;
                                      final wards = _vietnamAddressData[_selectedProvince]?[val] ?? [];
                                      _selectedWard = wards.isNotEmpty ? wards.first : '';
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Phường / Xã
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Phường / Xã",
                                style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                key: ValueKey('ward_${_selectedProvince}_${_selectedDistrict}_$_selectedWard'),
                                initialValue: availableWards.contains(_selectedWard) ? _selectedWard : (availableWards.isNotEmpty ? availableWards.first : null),
                                isExpanded: true,
                                style: GoogleFonts.lexend(fontSize: 13, color: AppColors.onBackground),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                items: availableWards.map((w) {
                                  return DropdownMenuItem(value: w, child: Text(w));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedWard = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Số nhà, tên đường chi tiết
                    Text(
                      "Số nhà, tên đường, khu vực chi tiết *",
                      style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _streetDetailController,
                      style: GoogleFonts.lexend(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Ví dụ: Số 15 Hoàng Hoa Thám / KĐT Mỹ Đình 2",
                        hintStyle: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nhập số nhà / tên đường' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. KHUNG GIỜ MỞ / ĐÓNG CỬA (CHỌN DANH SÁCH GIỜ CỐ ĐỊNH)
              Text(
                "Khung giờ hoạt động",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Giờ mở cửa
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Giờ mở cửa",
                          style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          key: ValueKey('open_time_$_selectedOpenTime'),
                          initialValue: _selectedOpenTime,
                          style: GoogleFonts.lexend(fontSize: 14, color: AppColors.onBackground),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _timeSlots.map((time) {
                            return DropdownMenuItem(value: time, child: Text(time));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedOpenTime = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Giờ đóng cửa
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Giờ đóng cửa",
                          style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          key: ValueKey('close_time_$_selectedCloseTime'),
                          initialValue: _selectedCloseTime,
                          style: GoogleFonts.lexend(fontSize: 14, color: AppColors.onBackground),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _timeSlots.map((time) {
                            return DropdownMenuItem(value: time, child: Text(time));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCloseTime = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "Hủy",
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Thêm cơ sở",
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
