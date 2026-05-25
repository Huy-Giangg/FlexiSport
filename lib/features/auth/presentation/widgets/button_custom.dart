import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ButtonCustom extends StatelessWidget {
  final String title;
  final VoidCallback ontap;
  const ButtonCustom({super.key, required this.title, required this.ontap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.primary,
            ),
            onPressed: (){
              ontap();
            },
              child: Text(title, style: TextStyle(fontSize: 18, color: AppColors.surface))
             ),
        )
      ],
    );
  }
}
