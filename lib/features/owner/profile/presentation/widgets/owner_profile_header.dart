import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerProfileHeader extends StatelessWidget {
  final User? user;
  final Map<String, dynamic>? profileData;
  final VoidCallback onEditProfile;

  const OwnerProfileHeader({
    super.key,
    required this.user,
    this.profileData,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = profileData?['name']?.toString().isNotEmpty == true
        ? profileData!['name'].toString()
        : (user?.userMetadata?['full_name'] as String? ??
            user?.userMetadata?['name'] as String? ??
            user?.email?.split('@').first ??
            'Chủ cơ sở');

    final email = user?.email ?? 'Chưa cập nhật email';
    final phone = profileData?['phone']?.toString().isNotEmpty == true
        ? profileData!['phone'].toString()
        : (user?.userMetadata?['phone'] as String? ?? 'Chưa cập nhật SĐT');

    final avatarUrl = profileData?['avatar_url'] as String?;
    final initialLetter = displayName.isNotEmpty ? displayName.trim()[0].toUpperCase() : 'C';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF006D38),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildInitialAvatar(initialLetter),
                            )
                          : _buildInitialAvatar(initialLetter),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2A62C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Owner info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: GoogleFonts.lexend(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_iphone_rounded, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Badge: Đối tác chủ sân
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2A62C).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2A62C).withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, size: 13, color: Color(0xFFE2A62C)),
                          const SizedBox(width: 4),
                          Text(
                            "Đối tác Chủ sân VIP",
                            style: GoogleFonts.lexend(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE2A62C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Edit profile icon button
              IconButton(
                onPressed: onEditProfile,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                ),
                tooltip: "Chỉnh sửa thông tin",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(String letter) {
    return Container(
      color: Colors.white.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.lexend(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
