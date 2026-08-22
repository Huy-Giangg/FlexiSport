import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class IcSport extends StatelessWidget {
  final String title;
  final String imgPath;
  final bool isSelected;
  final VoidCallback onTap;

  const IcSport({
    super.key,
    required this.title,
    required this.imgPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF43A047) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: isSelected
                  ? null
                  : BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
              alignment: Alignment.center,
              child: Image.asset(
                imgPath,
                height: 40,
                width: 40,
                color: isSelected ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.onPrimaryContainer,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
