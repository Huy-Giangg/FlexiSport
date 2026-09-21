import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

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

  String _preferredLocation = 'Hà Nội: Bắc Từ Liêm';
  List<String> _favoriteSports = ['Cầu lông', 'Bóng đá'];
  List<String> _goals = ['Giao lưu & kết nối', 'Luyện tập rèn luyện'];
  List<String> _playFrequency = ['Khi có thời gian rảnh', 'Chiều', 'Tối'];

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

          if (data['location'] != null && data['location'].toString().trim().isNotEmpty) {
            _preferredLocation = data['location'].toString();
          } else if (data['preferred_location'] != null && data['preferred_location'].toString().trim().isNotEmpty) {
            _preferredLocation = data['preferred_location'].toString();
          }

          if (data['favorite_sports'] != null) {
            final sports = data['favorite_sports'];
            if (sports is List && sports.isNotEmpty) {
              _favoriteSports = sports.map((e) => e.toString()).toList();
            } else if (sports is String && sports.trim().isNotEmpty) {
              _favoriteSports = sports.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            }
          }

          if (data['goals'] != null) {
            final g = data['goals'];
            if (g is List && g.isNotEmpty) {
              _goals = g.map((e) => e.toString()).toList();
            } else if (g is String && g.trim().isNotEmpty) {
              _goals = g.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            }
          }

          if (data['play_frequency'] != null) {
            final f = data['play_frequency'];
            if (f is List && f.isNotEmpty) {
              _playFrequency = f.map((e) => e.toString()).toList();
            } else if (f is String && f.trim().isNotEmpty) {
              _playFrequency = f.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            }
          }
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
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: Container(
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
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          title: Text(
            "Thông tin cá nhân",
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryContainer,
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
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
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
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          "Thông tin cá nhân",
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: GoogleFonts.lexend(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user?.email ?? '',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMyProfile)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
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
                              color: AppColors.primaryLightBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCard("Điện thoại", _phone, Icons.phone_outlined),
                      Container(width: 1, height: 28, color: Colors.grey.shade200),
                      _buildInfoCard("Năm sinh", _birthYear, Icons.cake_outlined),
                      Container(width: 1, height: 28, color: Colors.grey.shade200),
                      _buildInfoCard("Giới tính", _gender, Icons.person_outline_rounded),
                    ],
                  ),
                ],
              ),
            ),

            // Card 1: Thông tin thể chất
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Thông tin thể chất",
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.straighten_rounded, color: Colors.grey.shade500, size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Chiều cao",
                                    style: GoogleFonts.lexend(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _height > 0 ? "${_height.toStringAsFixed(1).replaceAll('.0', '')} cm" : "Chưa cập nhật",
                                style: GoogleFonts.lexend(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.monitor_weight_outlined, color: Colors.grey.shade500, size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Cân nặng",
                                    style: GoogleFonts.lexend(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _weight > 0 ? "${_weight.toStringAsFixed(1).replaceAll('.0', '')} kg" : "Chưa cập nhật",
                                style: GoogleFonts.lexend(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card 2: Cá nhân hóa
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cá nhân hóa",
                              style: GoogleFonts.lexend(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                            ),
                            Text(
                              "Sở thích và thói quen rèn luyện thể thao",
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // 1. Vị trí yêu thích
                  _buildPersonalizationSection(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFFE53935),
                    iconBg: const Color(0xFFFFEBEE),
                    title: "Vị trí yêu thích",
                    content: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFFE53935)),
                          const SizedBox(width: 6),
                          Text(
                            _preferredLocation,
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Môn thể thao
                  _buildPersonalizationSection(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    iconBg: const Color(0xFFE8F5E9),
                    title: "Môn thể thao",
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _favoriteSports.map((sport) {
                        return _buildTagBadge(
                          label: sport,
                          icon: _getSportIcon(sport),
                          bg: const Color(0xFFF0FDF4),
                          textColor: const Color(0xFF15803D),
                          borderColor: const Color(0xFFBBF7D0),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Mục tiêu
                  _buildPersonalizationSection(
                    icon: Icons.track_changes_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                    title: "Mục tiêu",
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _goals.map((goal) {
                        IconData goalIcon = Icons.stars_rounded;
                        final gLower = goal.toLowerCase();
                        if (gLower.contains('giao lưu') || gLower.contains('kết nối')) {
                          goalIcon = Icons.people_alt_rounded;
                        } else if (gLower.contains('luyện tập') || gLower.contains('sức khỏe') || gLower.contains('thể lực')) {
                          goalIcon = Icons.fitness_center_rounded;
                        }
                        return _buildTagBadge(
                          label: goal,
                          icon: goalIcon,
                          bg: const Color(0xFFFFFBEB),
                          textColor: const Color(0xFFB45309),
                          borderColor: const Color(0xFFFDE68A),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Tần suất chơi
                  _buildPersonalizationSection(
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFEDE9FE),
                    title: "Tần suất chơi",
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _playFrequency.map((freq) {
                        IconData freqIcon = Icons.schedule_rounded;
                        final fLower = freq.toLowerCase();
                        if (fLower.contains('rảnh')) {
                          freqIcon = Icons.auto_awesome_rounded;
                        } else if (fLower.contains('chiều')) {
                          freqIcon = Icons.wb_sunny_rounded;
                        } else if (fLower.contains('tối')) {
                          freqIcon = Icons.nightlight_round;
                        } else if (fLower.contains('sáng')) {
                          freqIcon = Icons.wb_twilight_rounded;
                        }
                        final cleanLabel = freq
                            .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '')
                            .trim();
                        return _buildTagBadge(
                          label: cleanLabel.isNotEmpty ? cleanLabel : freq,
                          icon: freqIcon,
                          bg: const Color(0xFFF5F3FF),
                          textColor: const Color(0xFF6D28D9),
                          borderColor: const Color(0xFFDDD6FE),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizationSection({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          content,
        ],
      ),
    );
  }

  Widget _buildTagBadge({
    required String label,
    IconData? icon,
    required Color bg,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('cầu lông')) return Icons.sports_tennis_rounded;
    if (s.contains('bóng đá')) return Icons.sports_soccer_rounded;
    if (s.contains('pickleball')) return Icons.sports_baseball_rounded;
    if (s.contains('tennis')) return Icons.sports_tennis_outlined;
    if (s.contains('bóng rổ')) return Icons.sports_basketball_rounded;
    if (s.contains('bóng chuyền')) return Icons.sports_volleyball_rounded;
    return Icons.sports_score_rounded;
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
      ],
    );
  }
}
