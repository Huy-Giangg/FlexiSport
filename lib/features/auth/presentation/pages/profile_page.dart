import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/auth/services/auth_services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _selectedLanguage = "Tiếng Việt";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user =
            snapshot.data?.session?.user ??
            Supabase.instance.client.auth.currentUser;

        return Scaffold(
          
          body: Column(
            children: [
              // Green Header background
              Container(
                height: 120,
                width: double.infinity,
                color: const Color(0xFF006D38),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 20,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Card
                          user == null
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Circular Avatar with ALOBO Logo
                                      ClipRRect(
                                        child: Image.asset(
                                          "assets/images/logo.png",
                                          width: 90,
                                          height: 90,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // User Info and Login/Register Buttons
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "FlexiSport - Đặt lịch online sân thể thao",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              "Tạo tài khoản để nhận nhiều ưu đãi hơn",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFFE2A62C),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                // Login Button
                                                ElevatedButton(
                                                  onPressed: () {
                                                    context
                                                        .read<
                                                          MainPageProvider
                                                        >()
                                                        .hideNavbar();
                                                    context.push('/login').then(
                                                      (_) {
                                                        context
                                                            .read<
                                                              MainPageProvider
                                                            >()
                                                            .showNavbar();
                                                      },
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF006D38),
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize: const Size(
                                                      90,
                                                      36,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                        ),
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "Đăng nhập",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                // Register Button
                                                OutlinedButton(
                                                  onPressed: () {
                                                    context
                                                        .read<
                                                          MainPageProvider
                                                        >()
                                                        .hideNavbar();
                                                    context
                                                        .push('/register')
                                                        .then((_) {
                                                          context
                                                              .read<
                                                                MainPageProvider
                                                              >()
                                                              .showNavbar();
                                                        });
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.black87,
                                                    side: const BorderSide(
                                                      color: Colors.black26,
                                                    ),
                                                    minimumSize: const Size(
                                                      90,
                                                      36,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "Đăng ký",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : InkWell(
                                  onTap: () {
                                    context
                                        .read<MainPageProvider>()
                                        .hideNavbar();

                                    context
                                        .push('/ProfileDetailPage', extra: user)
                                        .then((_) {
                                          context
                                              .read<MainPageProvider>()
                                              .showNavbar();
                                        });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                            (user.userMetadata?['full_name']
                                                        as String? ??
                                                    user.userMetadata?['name']
                                                        as String? ??
                                                    user.email ??
                                                    'U')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // User Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.userMetadata?['full_name']
                                                        as String? ??
                                                    user.userMetadata?['name']
                                                        as String? ??
                                                    'Người dùng',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                user.email ?? '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                "Thành viên FlexiSport",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF006D38),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Color(0xFF006D38),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                          const SizedBox(height: 24),

                          // Hoạt động Section
                          const Text(
                            "Hoạt động",
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildListTile(
                              icon: Icons.calendar_month_outlined,
                              title: "Danh sách lịch đã đặt",
                              onTap: () {
                                context.read<MainPageProvider>().hideNavbar();
                                context.push('/BookedCourtPage').then((_) {
                                  if (context.mounted) {
                                    context.read<MainPageProvider>().showNavbar();
                                  }
                                });
                              },
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildListTile(
                                  icon: Icons.info_outline_rounded,
                                  title: "Thông tin phiên bản: 2.9.0",
                                  onTap: () => _showVersionDialog(context),
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 50,
                                  color: Color(0xFFEEEEEE),
                                ),
                                _buildListTile(
                                  icon: Icons.security_outlined,
                                  title: "Điều khoản và chính sách",
                                  onTap: () => _showTermsAndPolicies(context),
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 50,
                                  color: Color(0xFFEEEEEE),
                                ),
                                _buildListTile(
                                  icon: Icons.new_releases_outlined,
                                  title: "Ứng dụng có gì mới",
                                  onTap: () => _showWhatsNew(context),
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 50,
                                  color: Color(0xFFEEEEEE),
                                ),
                                _buildListTile(
                                  icon: Icons.language_outlined,
                                  title: "Ngôn ngữ - $_selectedLanguage",
                                  onTap: () => _showLanguageSelection(context),
                                ),
                                if (user != null) ...[
                                  const Divider(
                                    height: 1,
                                    indent: 50,
                                    color: Color(0xFFEEEEEE),
                                  ),
                                  _buildListTile(
                                    icon: Icons.logout_rounded,
                                    title: "Đăng xuất",
                                    onTap: () async {
                                      await AuthService().signOut();
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF006D38), size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.black38,
        size: 14,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                            color: Colors.black.withOpacity(0.1),
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
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.sports_soccer,
                            size: 64,
                            color: Color(0xFF006D38),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "FlexiSport",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Phiên bản 2.9.0",
                        style: TextStyle(
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
                    const Text(
                      "Chi tiết bản cập nhật:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF006D38),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildVersionDetailItem(
                      icon: Icons.auto_awesome_rounded,
                      text: "Tối ưu hóa giao diện đặt sân, thân thiện và hiện đại hơn.",
                    ),
                    _buildVersionDetailItem(
                      icon: Icons.bolt_rounded,
                      text: "Tăng tốc độ phản hồi ứng dụng và giảm độ trễ khi tải dữ liệu.",
                    ),
                    _buildVersionDetailItem(
                      icon: Icons.sports_tennis_rounded,
                      text: "Cải tiến tính năng ghép cặp & chi tiết lịch thi đấu.",
                    ),
                    _buildVersionDetailItem(
                      icon: Icons.security_rounded,
                      text: "Tăng cường bảo mật thông tin người dùng và tài khoản.",
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        "© 2026 FlexiSport. All rights reserved.",
                        style: TextStyle(
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
                        child: const Text(
                          "Đóng",
                          style: TextStyle(
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

  Widget _buildVersionDetailItem({required IconData icon, required String text}) {
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
              style: const TextStyle(
                fontSize: 13,
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
                    // Handle bar
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
                    // Title and Close button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Điều khoản & Chính sách",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006D38),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Tab Bar
                    const TabBar(
                      labelColor: Color(0xFF006D38),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF006D38),
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(text: "Điều khoản dịch vụ"),
                        Tab(text: "Chính sách bảo mật"),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    // Tab Content
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
          "1. Quy định chung",
          "Chào mừng bạn đến với FlexiSport. Bằng việc đăng ký tài khoản và sử dụng ứng dụng của chúng tôi, bạn xác nhận đã đọc, hiểu và hoàn toàn đồng ý tuân thủ các điều khoản dịch vụ này. Nếu không đồng ý, vui lòng ngưng sử dụng dịch vụ.",
        ),
        _buildPolicySection(
          "2. Tài khoản người dùng",
          "Bạn chịu trách nhiệm bảo mật thông tin đăng nhập tài khoản của mình. Mọi hoạt động được thực hiện qua tài khoản của bạn sẽ được xem là do bạn thực hiện. Hãy thông báo ngay cho chúng tôi nếu phát hiện dấu hiệu truy cập trái phép.",
        ),
        _buildPolicySection(
          "3. Đặt sân và Thanh toán",
          "FlexiSport hỗ trợ kết nối người dùng và các sân thể thao. Người dùng có trách nhiệm kiểm tra kỹ các thông tin về sân đấu, khung giờ, chi phí dịch vụ trước khi bấm xác nhận. Việc thanh toán được thực hiện trực tiếp hoặc qua cổng thanh toán liên kết theo quy định của từng sân.",
        ),
        _buildPolicySection(
          "4. Chính sách huỷ đặt lịch",
          "Mỗi cơ sở sân thể thao có chính sách huỷ và hoàn tiền riêng. Bạn cần tìm hiểu kỹ thông tin này trước khi thực hiện đặt sân. FlexiSport sẽ hỗ trợ liên lạc giải quyết tranh chấp dựa trên chính sách đã được công khai của sân đó.",
        ),
        _buildPolicySection(
          "5. Quy định sử dụng và ứng xử",
          "Người dùng cần tuân thủ tuyệt đối các quy định nội bộ của sân đấu. Nghiêm cấm các hành vi gây mất an ninh trật tự, hủy hoại tài sản của sân đấu, hoặc sử dụng chất cấm tại khu vực sân đấu. Mọi vi phạm có thể dẫn tới khóa tài khoản vĩnh viễn.",
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
          "1. Thu thập thông tin",
          "Chúng tôi thu thập các thông tin cá nhân cần thiết bao gồm: họ tên, số điện thoại, địa chỉ email, và vị trí GPS (khi được cấp quyền) để hỗ trợ tìm kiếm và định vị các sân đấu gần bạn nhất.",
        ),
        _buildPolicySection(
          "2. Sử dụng thông tin của bạn",
          "Thông tin của bạn được sử dụng nhằm mục đích: xác thực tài khoản, thực hiện quy trình đặt sân và thông báo, cải thiện chất lượng dịch vụ ứng dụng, hỗ trợ khách hàng và giải quyết các khiếu nại phát sinh.",
        ),
        _buildPolicySection(
          "3. Bảo mật dữ liệu",
          "Chúng tôi cam kết sử dụng các tiêu chuẩn bảo mật hiện đại nhằm mã hóa dữ liệu cá nhân, phòng ngừa truy cập, rò rỉ hoặc chỉnh sửa trái phép. Tuy nhiên, không có phương thức truyền tải qua internet nào an toàn 100%.",
        ),
        _buildPolicySection(
          "4. Chia sẻ thông tin với bên thứ ba",
          "Chúng tôi chỉ chia sẻ những thông tin cần thiết nhất (như họ tên và số điện thoại liên lạc) cho chủ sân đấu mà bạn đặt để phục vụ việc nhận diện và xác minh check-in tại sân. Chúng tôi không bao giờ bán thông tin của bạn cho bên thứ ba.",
        ),
        _buildPolicySection(
          "5. Quyền lợi của người dùng",
          "Bạn có toàn quyền truy cập, chỉnh sửa hoặc yêu cầu xóa bỏ thông tin tài khoản của mình bất kỳ lúc nào thông qua phần cấu hình tài khoản hoặc liên hệ trực tiếp với bộ phận chăm sóc khách hàng của FlexiSport.",
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006D38),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
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
                  // Handle bar
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
                  // Title and Close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Ứng dụng có gì mới?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006D38),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Promo / Release Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F9F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF006D38).withOpacity(0.1),
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
                                  children: const [
                                    Text(
                                      "Chào mừng tới phiên bản 2.9.0!",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF006D38),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Cùng khám phá các cải tiến vượt trội giúp trải nghiệm thể thao của bạn trở nên trọn vẹn hơn.",
                                      style: TextStyle(
                                        fontSize: 12.5,
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
                        const SizedBox(height: 24),
                        // List of New Features
                        _buildFeatureUpdateItem(
                          icon: Icons.sports_soccer_rounded,
                          title: "Đặt sân nhanh & Định vị thông minh",
                          description:
                              "Tích hợp hệ thống bản đồ thông minh giúp định vị các sân bóng đá, cầu lông, tennis gần nhất. Đặt sân và giữ chỗ trực tuyến chỉ với vài chạm.",
                        ),
                        _buildFeatureUpdateItem(
                          icon: Icons.groups_rounded,
                          title: "Ghép cặp trận đấu (Matchmaking)",
                          description:
                              "Tính năng kết nối và tìm kiếm đồng đội hoặc đối thủ cùng trình độ. Tạo trận đấu giao lưu, tuyển thành viên cho câu lạc bộ cực kỳ đơn giản.",
                        ),
                        _buildFeatureUpdateItem(
                          icon: Icons.notifications_active_rounded,
                          title: "Nhắc lịch & Cập nhật thời gian thực",
                          description:
                              "Hệ thống thông báo đẩy thông minh nhắc nhở giờ thi đấu, lịch đặt sân sắp diễn ra hoặc các cập nhật quan trọng từ đối tác cung cấp sân.",
                        ),
                        _buildFeatureUpdateItem(
                          icon: Icons.discount_rounded,
                          title: "Mã ưu đãi hấp dẫn",
                          description:
                              "Khám phá các chương trình khuyến mãi độc quyền từ các cụm sân đối tác lớn, giúp tối ưu chi phí đặt lịch của bạn.",
                        ),
                        const SizedBox(height: 16),
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
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF006D38).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF006D38),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              const Text(
                "Chọn ngôn ngữ / Select Language",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006D38),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFEEEEEE)),
              ListTile(
                leading: const Text("🇻🇳", style: TextStyle(fontSize: 24)),
                title: const Text(
                  "Tiếng Việt",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: _selectedLanguage == "Tiếng Việt"
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF006D38))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = "Tiếng Việt";
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đã đổi ngôn ngữ sang Tiếng Việt"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 16, endIndent: 16),
              ListTile(
                leading: const Text("🇬🇧", style: TextStyle(fontSize: 24)),
                title: const Text(
                  "English",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: _selectedLanguage == "English"
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF006D38))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = "English";
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Changed language to English (Demo)"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
