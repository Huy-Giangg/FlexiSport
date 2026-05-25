import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class IcSport extends StatelessWidget {
  final title;
  final imgPath;
  const IcSport({super.key, required this.title, this.imgPath});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            side: BorderSide(width: 1, color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(8),
            ),
          ),
          onPressed: () {},
          icon: Image.asset(
            imgPath,
            height: 40,
            width: 40,
          ),
        ),
    
        Text(title, style: TextStyle(fontSize: 12, color: AppColors.onPrimaryContainer),)
      ],
    );
  }
}
