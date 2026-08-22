import 'package:flutter/material.dart';

class PlayerAvatarStack extends StatelessWidget {
  final List<String> imageUrls;
  final double avatarRadius;
  final double overlapFraction;

  const PlayerAvatarStack({
    super.key,
    required this.imageUrls,
    this.avatarRadius = 16.0,
    this.overlapFraction = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: avatarRadius * 2,
      child: Stack(
        children: List.generate(imageUrls.length, (index) {
          final imageUrl = imageUrls[index];
          final offset = index * (avatarRadius * 2 * (1 - overlapFraction));

          return Positioned(
            left: offset,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius - 1, // trừ viền
                backgroundImage: imageUrl.isNotEmpty 
                    ? NetworkImage(imageUrl) 
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                child: imageUrl.isEmpty 
                    ? const Icon(Icons.person, size: 16) 
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
