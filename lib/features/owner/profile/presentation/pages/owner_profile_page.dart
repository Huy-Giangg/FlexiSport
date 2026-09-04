import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/auth/services/auth_services.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';
import 'package:flexisport_app/features/owner/profile/presentation/pages/owner_profile_detail_page.dart';

class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key});

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  Map<String, dynamic>? _profileData;
  String _selectedLanguage = "Tiếng Việt";

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              "Đăng xuất",
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản chủ sân này?",
          style: GoogleFonts.lexend(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Hủy",
              style: GoogleFonts.lexend(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService().signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              "Đăng xuất",
              style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with logo and name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF006D38),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/images/logo.png",
                          width: 64,
                          height: 64,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.sports_soccer,
                                size: 64,
                                color: Color(0xFF006D38),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "FlexiSport Owner",
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Phiên bản 2.9.0",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body with details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chi tiết bản cập nhật dành cho Chủ sân:",
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF006D38),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildVersionDetailItem(
                      icon: Icons.auto_awesome_rounded,
                      text:
                          "Tối ưu hóa giao diện quản lý sân, hiện đại và thân thiện hơn.",
                    ),
                    _buildVersionDetailItem(
                      icon: Icons.bolt_rounded,
                      text:
                          "Cập nhật realtime đơn đặt sân & thanh toán cọc tự động.",
                    ),
                    _buildVersionDetailItem(
                      icon: Icons.stadium_rounded,
                      text:
                          "Quản lý khóa ô giờ thông minh & linh hoạt theo ngày.",
                    ),
                    _buildVersionDetailItem(
                      icon: Icons.security_rounded,
                      text:
                          "Tăng cường bảo mật thông tin tài khoản và đối tác.",
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "© 2026 FlexiSport. All rights reserved.",
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006D38),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Đóng",
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionDetailItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE2A62C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lexend(
                fontSize: 12.5,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsAndPolicies(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return DefaultTabController(
              length: 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Điều khoản & Chính sách",
                            style: GoogleFonts.lexend(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF006D38),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.grey,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const TabBar(
                      labelColor: Color(0xFF006D38),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF006D38),
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(text: "Chính sách đối tác"),
                        Tab(text: "Chính sách bảo mật"),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildTermsTab(scrollController),
                          _buildPrivacyTab(scrollController),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTermsTab(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _buildPolicySection(
          "1. Quyền và nghĩa vụ của Chủ sân",
          "Chủ cơ sở cam kết đảm bảo cơ sở vật chất, mặt sân, trang thiết bị đúng với mô tả trên ứng dụng FlexiSport. Chủ sân có trách nhiệm cập nhật kịp thời trạng thái sân và lịch bảo trì để tránh trùng lịch đặt.",
        ),
        _buildPolicySection(
          "2. Quy định thanh toán & Nhận cọc",
          "Tiền đặt cọc của người chơi sẽ được chuyển trực tiếp vào tài khoản ngân hàng do chủ sân cung cấp trên hệ thống. Chủ sân có trách nhiệm xác nhận trạng thái giữ chỗ cho khách hàng ngay khi nhận được thanh toán.",
        ),
        _buildPolicySection(
          "3. Chính sách hủy sân & Hoàn cọc",
          "Chủ sân cần tuân thủ đúng khung thời gian hủy sân và tỷ lệ cọc đã cấu hình công khai trên ứng dụng. Mọi thay đổi hủy đột xuất từ phía chủ sân cần được thông báo trước cho khách hàng ít nhất 4 tiếng.",
        ),
        _buildPolicySection(
          "4. Giải quyết khiếu nại & Tranh chấp",
          "FlexiSport hỗ trợ vai trò trung gian kết nối và giải quyết tranh chấp phát sinh giữa người chơi và chủ sân dựa trên lịch sử giao dịch và bằng chứng thực tế tại sân đấu.",
        ),
      ],
    );
  }

  Widget _buildPrivacyTab(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _buildPolicySection(
          "1. Thu thập thông tin đối tác",
          "Chúng tôi thu thập các thông tin bao gồm: họ tên người đại diện, số điện thoại, thông tin cơ sở sân, giấy phép kinh doanh (nếu có) và thông tin tài khoản ngân hàng để phục vụ việc liên kết nhận cọc.",
        ),
        _buildPolicySection(
          "2. Bảo mật dữ liệu",
          "Thông tin của đối tác được bảo vệ với tiêu chuẩn mã hóa cao nhất, đảm bảo tính an toàn cho các giao dịch tài chính và thông tin định danh.",
        ),
        _buildPolicySection(
          "3. Quyền hạn của đối tác",
          "Chủ sân có quyền cập nhật, chỉnh sửa thông tin sân, cấu hình tài khoản nhận tiền hoặc yêu cầu hỗ trợ từ đội ngũ FlexiSport bất kỳ lúc nào.",
        ),
      ],
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006D38),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: Colors.black87,
              height: 1.45,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  void _showWhatsNew(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ứng dụng có gì mới?",
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF006D38),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F9F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF006D38,
                              ).withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFE2A62C),
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Chào mừng tới phiên bản 2.9.0!",
                                      style: GoogleFonts.lexend(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: const Color(0xFF006D38),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Trải nghiệm giao diện quản trị hiện đại, linh hoạt và tiện lợi hơn cho chủ cơ sở.",
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureUpdateItem(
                          icon: Icons.dashboard_customize_rounded,
                          title: "Giao diện quản lý tài khoản mới",
                          description:
                              "Tích hợp báo cáo nhanh, quản lý hồ sơ cơ sở và hệ thống quản lý lịch đặt sân thông minh.",
                        ),
                        _buildFeatureUpdateItem(
                          icon: Icons.qr_code_scanner_rounded,
                          title: "Thanh toán VietQR tiện lợi",
                          description:
                              "Khách hàng quét mã cọc tiền trực tiếp, cập nhật trạng thái đơn đặt tức thì mà không cần đối soát thủ công.",
                        ),
                        _buildFeatureUpdateItem(
                          icon: Icons.lock_clock_rounded,
                          title: "Khóa ô giờ bảo trì linh hoạt",
                          description:
                              "Dễ dàng khóa/mở các khung giờ cụ thể theo ngày để phục vụ bảo trì mặt sân hoặc sự kiện nội bộ.",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureUpdateItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF006D38).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF006D38), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Chọn ngôn ngữ / Select Language",
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF006D38),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFEEEEEE)),
              ListTile(
                leading: const Text("🇻🇳", style: TextStyle(fontSize: 24)),
                title: Text(
                  "Tiếng Việt",
                  style: GoogleFonts.lexend(
                    fontWeight: _selectedLanguage == "Tiếng Việt"
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedLanguage == "Tiếng Việt"
                        ? const Color(0xFF006D38)
                        : Colors.black87,
                  ),
                ),
                trailing: _selectedLanguage == "Tiếng Việt"
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF006D38),
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedLanguage = "Tiếng Việt");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text("🇬🇧", style: TextStyle(fontSize: 24)),
                title: Text(
                  "English",
                  style: GoogleFonts.lexend(
                    fontWeight: _selectedLanguage == "English"
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedLanguage == "English"
                        ? const Color(0xFF006D38)
                        : Colors.black87,
                  ),
                ),
                trailing: _selectedLanguage == "English"
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF006D38),
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedLanguage = "English");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTransactionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Lịch sử giao dịch nhận cọc",
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTransactionItem(
              "Khách: Nguyễn Văn A",
              "Đặt Sân 1 (18:00 - 19:30)",
              "+150.000 đ",
              "Hôm nay, 14:30",
            ),
            const Divider(height: 1),
            _buildTransactionItem(
              "Khách: Trần Đức Huy",
              "Đặt Sân 3 (19:30 - 21:00)",
              "+200.000 đ",
              "Hôm nay, 11:15",
            ),
            const Divider(height: 1),
            _buildTransactionItem(
              "Khách: Lê Minh Khoa",
              "Đặt Sân 2 (17:00 - 18:30)",
              "+150.000 đ",
              "Hôm qua, 20:00",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    String title,
    String subtitle,
    String amount,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.lexend(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006D38),
            ),
          ),
        ],
      ),
    );
  }

  void _showPromotionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Chương trình khuyến mãi",
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8B4FE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "GIAM20K - Giờ vàng thể thao",
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B21A8),
                          ),
                        ),
                        Text(
                          "Giảm 20.000đ cho khung giờ 13:00 - 16:00 ngày thường",
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showReviewsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Đánh giá từ khách hàng",
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildReviewItem(
              "Hoàng Long",
              5,
              "Mặt cỏ rất đẹp, đèn sáng rõ vào buổi tối, có chỗ để xe máy ô tô thoải mái.",
            ),
            const Divider(height: 1),
            _buildReviewItem(
              "Minh Trí",
              5,
              "Chủ sân nhiệt tình, sân sạch sẽ và có nước uống đầy đủ.",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String name, int stars, String comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  stars,
                  (index) => const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final courtProvider = context.watch<OwnerCourtProvider>();

    final ownerDisplayName =
        _profileData?['name']?.toString().isNotEmpty == true
        ? _profileData!['name'].toString()
        : (user?.userMetadata?['full_name'] as String? ??
              user?.userMetadata?['name'] as String? ??
              'Hoàng Nam');

    final ownerEmail =
        user?.email ??
        _profileData?['email']?.toString() ??
        'hoangnamsan@gmail.com';

    final initialLetter = ownerDisplayName.isNotEmpty
        ? ownerDisplayName.trim()[0].toUpperCase()
        : 'H';

    return Scaffold(
      body: Column(
        children: [
          // Gradient Header background
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryContainer,
                  AppColors.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // White body container with rounded top corners
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F9F6),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadProfile();
                    await courtProvider.loadData();
                  },
                  color: const Color(0xFF006D38),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 20,
                      bottom: 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Card
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const OwnerProfileDetailPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Circular Avatar with Initials
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: const BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initialLetter,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Owner Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ownerDisplayName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ownerEmail,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Đối tác VIP",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF006D38),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Color(0xFF006D38),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Hệ thống Section
                        const Text(
                          "Hệ thống",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006D38),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItemTile(
                                icon: Icons.info_outline_rounded,
                                title: "Thông tin phiên bản: 2.9.0",
                                onTap: () => _showVersionDialog(context),
                              ),
                              _buildDivider(),
                              _buildMenuItemTile(
                                icon: Icons.security_outlined,
                                title: "Điều khoản và chính sách",
                                onTap: () => _showTermsAndPolicies(context),
                              ),
                              _buildDivider(),
                              _buildMenuItemTile(
                                icon: Icons.new_releases_outlined,
                                title: "Ứng dụng có gì mới",
                                onTap: () => _showWhatsNew(context),
                              ),
                              _buildDivider(),
                              _buildMenuItemTile(
                                icon: Icons.language_outlined,
                                title: "Ngôn ngữ - $_selectedLanguage",
                                onTap: () => _showLanguageSelection(context),
                              ),
                              _buildDivider(),
                              _buildMenuItemTile(
                                icon: Icons.logout_rounded,
                                title: "Đăng xuất",
                                onTap: () => _showLogoutDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF006D38), size: 22),
      title: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1B1C19),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 48, color: Color(0xFFF3F4F6));
  }
}
