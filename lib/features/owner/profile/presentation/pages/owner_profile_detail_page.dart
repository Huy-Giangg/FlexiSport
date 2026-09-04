import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/profile/presentation/widgets/bank_settings_dialog.dart';

class OwnerProfileDetailPage extends StatefulWidget {
  const OwnerProfileDetailPage({super.key});

  @override
  State<OwnerProfileDetailPage> createState() => _OwnerProfileDetailPageState();
}

class _OwnerProfileDetailPageState extends State<OwnerProfileDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profileData = data;
        });
      }
    } catch (_) {}
  }

  void _showEditVenueSheet(BuildContext context, OwnerCourtProvider provider) {
    final venue = provider.selectedVenue;
    if (venue == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    final currentPhone =
        _profileData?['phone']?.toString() ??
        user?.userMetadata?['phone'] as String? ??
        '';

    final nameController = TextEditingController(text: venue.name);
    final phoneController = TextEditingController(text: currentPhone);
    final addressController = TextEditingController(text: venue.address);
    final sportTypeController = TextEditingController(
      text: venue.sportsType ?? "Bóng rổ",
    );
    final openTimeController = TextEditingController(text: venue.openTime);
    final closeTimeController = TextEditingController(text: venue.closeTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D38).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF006D38),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Chỉnh sửa thông tin sân",
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B1C19),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  labelText: "Tên cơ sở thể thao",
                  prefixIcon: const Icon(
                    Icons.stadium_outlined,
                    color: Color(0xFF006D38),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sportTypeController,
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  labelText: "Loại hình sân",
                  prefixIcon: const Icon(
                    Icons.sports_basketball_outlined,
                    color: Color(0xFF006D38),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  labelText: "Số điện thoại liên hệ",
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF006D38),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  labelText: "Địa chỉ sân",
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF006D38),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: openTimeController,
                      style: GoogleFonts.lexend(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Giờ mở cửa",
                        hintText: "05:00",
                        prefixIcon: const Icon(
                          Icons.access_time,
                          color: Color(0xFF006D38),
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: closeTimeController,
                      style: GoogleFonts.lexend(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Giờ đóng cửa",
                        hintText: "22:00",
                        prefixIcon: const Icon(
                          Icons.access_time_filled,
                          color: Color(0xFF006D38),
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final updatedPhone = phoneController.text.trim();
                    if (user != null && updatedPhone.isNotEmpty) {
                      try {
                        await Supabase.instance.client.from('profiles').upsert({
                          'id': user.id,
                          'phone': updatedPhone,
                          'updated_at': DateTime.now().toIso8601String(),
                        });
                        await _loadProfile();
                      } catch (_) {}
                    }

                    final success = await provider.updateVenueInfo(
                      name: nameController.text.trim(),
                      address: addressController.text.trim(),
                      openTime: openTimeController.text.trim(),
                      closeTime: closeTimeController.text.trim(),
                      sportsType: sportTypeController.text.trim(),
                      bankName: venue.bankName,
                      accountNumber: venue.accountNumber,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? "Đã cập nhật thông tin sân thành công!"
                                : "Cập nhật thất bại",
                            style: GoogleFonts.lexend(),
                          ),
                          backgroundColor: success
                              ? const Color(0xFF006D38)
                              : Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D38),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Lưu thông tin",
                    style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final courtProvider = context.watch<OwnerCourtProvider>();
    final selectedVenue = courtProvider.selectedVenue;

    final venueName =
        selectedVenue?.name ??
        _profileData?['name']?.toString() ??
        (user?.userMetadata?['full_name'] as String? ??
            'Sân Thể Thao Hoàng Nam');

    final phone = _profileData?['phone']?.toString().isNotEmpty == true
        ? _profileData!['phone'].toString()
        : (user?.userMetadata?['phone'] as String? ?? '0987 654 321');

    final email =
        user?.email ??
        _profileData?['email']?.toString() ??
        'hoangnamsan@gmail.com';
    final address =
        selectedVenue?.address ?? 'CLB Thể thao Xuân La, Quận Tây Hồ, Hà Nội';
    final openTime = selectedVenue?.openTime ?? '05:00';
    final closeTime = selectedVenue?.closeTime ?? '22:00';
    final sportsType =
        selectedVenue?.sportsType ?? 'Sân bóng đá mini, Sân cầu lông';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Header màu xanh với nút Back & Tiêu đề "Hồ sơ chủ sân"
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF006D38)),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/owner/profile');
                          }
                        },
                      ),
                    ),
                    Text(
                      "Hồ sơ chủ sân",
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Nội dung cuộn với thẻ Profile & TabBar
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Card Header Hồ sơ (Venue Avatar, Badge đã xác thực, Contact info)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar sân với nút Camera tròn
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,

                                image: const DecorationImage(
                                  image: AssetImage("assets/images/logo.png"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Thông tin cơ sở & Liên hệ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venueName,
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B1C19),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Badge Đã xác thực
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F4EA),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 13,
                                      color: Color(0xFF006D38),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Đã xác thực",
                                      style: GoogleFonts.lexend(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF006D38),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Số điện thoại
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      phone,
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Email
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Địa chỉ vắn tắt
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      address.contains(',')
                                          ? address.split(',').last.trim()
                                          : address,
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Tab Bar (Thông tin cơ bản | Giấy phép kinh doanh | Tài khoản ngân hàng)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF006D38),
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      indicatorColor: const Color(0xFF006D38),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: "Thông tin cơ bản"),
                        Tab(text: "Giấy phép KD"),
                        Tab(text: "Tài khoản NH"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. TabBar Content (Chỉ xem - không nhấn vào từng dòng)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: [
                      // TAB 1: Thông tin cơ bản (Chỉ xem)
                      _buildBasicInfoTab(
                        venueName: venueName,
                        sportsType: sportsType,
                        address: address,
                        phone: phone,
                        email: email,
                        openCloseTime: "$openTime - $closeTime",
                        description:
                            "Sân đạt chuẩn, mặt cỏ nhân tạo mới, thoáng mát, có chỗ để xe rộng rãi.",
                      ),

                      // TAB 2: Giấy phép kinh doanh
                      _buildBusinessLicenseTab(venueName),

                      // TAB 3: Tài khoản ngân hàng
                      _buildBankTab(selectedVenue, courtProvider),
                    ][_tabController.index],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 5. Nút cố định "Chỉnh sửa thông tin"
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  if (_tabController.index == 2 && selectedVenue != null) {
                    BankSettingsDialog.show(
                      context,
                      selectedVenue,
                      courtProvider,
                    );
                  } else {
                    _showEditVenueSheet(context, courtProvider);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF006D38), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  "Chỉnh sửa thông tin",
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006D38),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab({
    required String venueName,
    required String sportsType,
    required String address,
    required String phone,
    required String email,
    required String openCloseTime,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.stadium_outlined,
            iconColor: const Color(0xFF006D38),
            label: "Tên sân",
            value: venueName,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFF10B981),
            label: "Loại hình sân",
            value: sportsType,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF059669),
            label: "Địa chỉ",
            value: address,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            iconColor: const Color(0xFF16A34A),
            label: "Số điện thoại",
            value: phone,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.mail_outline_rounded,
            iconColor: const Color(0xFF0D9488),
            label: "Email",
            value: email,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF0284C7),
            label: "Giờ hoạt động",
            value: openCloseTime,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessLicenseTab(String venueName) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D38).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF006D38),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Giấy phép kinh doanh thể thao",
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Hồ sơ đã được đội ngũ FlexiSport phê duyệt",
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailKeyValue("Mã số ĐKKD:", "0108938291"),
          _buildDetailKeyValue("Tên đơn vị:", venueName),
          _buildDetailKeyValue(
            "Người đại diện pháp luật:",
            _profileData?['name']?.toString() ?? "Hoàng Nam",
          ),
          _buildDetailKeyValue("Mã số thuế:", "0108938291-001"),
          _buildDetailKeyValue(
            "Trạng thái:",
            "Đã xác thực hợp lệ",
            valueColor: const Color(0xFF006D38),
          ),
          const SizedBox(height: 12),
          Text(
            "Ảnh chứng nhận đủ điều kiện hoạt động TDTT:",
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Color(0xFF006D38),
                  size: 36,
                ),
                const SizedBox(height: 6),
                Text(
                  "Giấy chứng nhận hoạt động hợp chuẩn",
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankTab(dynamic venue, OwnerCourtProvider courtProvider) {
    final bankName = venue?.bankName ?? "MB Bank (Ngân hàng Quân Đội)";
    final accountNumber = venue?.accountNumber ?? "999988886666";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D38).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF006D38),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tài khoản nhận tiền cọc sân",
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Tiền cọc từ người chơi sẽ được chuyển trực tiếp vào đây",
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailKeyValue("Ngân hàng:", bankName),
          _buildDetailKeyValue("Số tài khoản:", accountNumber),
          _buildDetailKeyValue(
            "Chủ tài khoản:",
            _profileData?['name']?.toString() ?? "HOANG NAM",
          ),
          _buildDetailKeyValue(
            "Hình thức nhận tiền:",
            "Thanh toán QR VietQR tự động",
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                if (venue != null) {
                  BankSettingsDialog.show(context, venue, courtProvider);
                }
              },
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(
                "Cấu hình lại tài khoản ngân hàng",
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D38),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailKeyValue(String key, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              key,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1B1C19),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Row thông tin CHỈ XEM (View-only, không có sự kiện tap)
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B1C19),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 48, color: Color(0xFFF3F4F6));
  }
}
