import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDetailPage extends StatefulWidget {
  final User? user;
  final String? userId;
  const ProfileDetailPage({super.key, this.user, this.userId});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  bool _isLoading = true;
  String _name = 'Người dùng';
  String _phone = 'Chưa cập nhật';
  String _birthYear = 'Chưa cập nhật';
  String _gender = 'Chưa cập nhật';
  double _height = 0.0;
  double _weight = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final targetId = widget.userId ?? widget.user?.id;
    if (targetId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      if (widget.user != null) {
        _name = widget.user!.userMetadata?['full_name'] as String? ??
                widget.user!.userMetadata?['name'] as String? ??
                'Người dùng';
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', targetId)
          .maybeSingle();

      if (data != null) {
        setState(() {
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            _name = data['name'].toString();
          }
          _phone = data['phone']?.toString() ?? 'Chưa cập nhật';
          if (_phone.trim().isEmpty) {
            _phone = 'Chưa cập nhật';
          }
          
          final birth = data['birth_year'] as int? ?? 0;
          _birthYear = birth > 0 ? birth.toString() : 'Chưa cập nhật';
          
          _gender = data['gender']?.toString() ?? 'Chưa cập nhật';
          if (_gender.trim().isEmpty) {
            _gender = 'Chưa cập nhật';
          }
          
          _height = (data['height'] as num?)?.toDouble() ?? 0.0;
          _weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin chi tiết cá nhân: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF006D38),
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          title: const Text("Thông tin cá nhân", style: TextStyle(color: Colors.white, fontSize: 18)),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF006D38),
          ),
        ),
      );
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final targetId = widget.userId ?? widget.user?.id;
    final isMyProfile = targetId == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D38),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          "Thông tin cá nhân",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF006D38),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMyProfile)
                          InkWell(
                            onTap: () async {
                              final updated = await context.push('/ProfileEditPage', extra: widget.user);
                              if (updated == true) {
                                _loadProfileData();
                              }
                            },
                            child: Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_document, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoCard("Điện thoại", _phone, Icons.phone),
                        _buildInfoCard("Năm sinh", _birthYear, Icons.cake_rounded),
                        _buildInfoCard("Giới tính", _gender, Icons.transgender),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1)),
              ],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Thông tin thể chất",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.straighten_outlined,
                                color: Colors.grey,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Chiều cao",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          Text(
                            _height > 0 ? "$_height cm" : "Chưa cập nhật",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Column(
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.monitor_weight_rounded,
                                color: Colors.grey,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Cân nặng",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          Text(
                            _weight > 0 ? "$_weight kg" : "Chưa cập nhật",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Cá nhân hóa",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.location_on_sharp),
                    SizedBox(width: 4),
                    Text(
                      "Vị trí yêu thích",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text("        Hà Nội: Bắc Từ Liêm"),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.emoji_events),
                    SizedBox(width: 4),
                    Text(
                      "Môn thể thao",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text("        Cầu lông, Bóng đá"),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.track_changes_rounded),
                    SizedBox(width: 4),
                    Text(
                      "Mục tiêu",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text("        Giao lưu & kết nối, luyện tập"),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 4),
                    Text(
                      "Tần suất chơi",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text("        🌟Khi có thời gian rảnh, 🌤️Chiều, 🌙Tối"),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
