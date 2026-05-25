import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class InputTextCustom extends StatelessWidget {
  final String hintext;
  final String title;
  final String? Function(String?)? validator;
  final TextEditingController textEditingController;
  const InputTextCustom({super.key, required this.hintext, required this.title, required this.validator, required this.textEditingController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10,),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),

      

        const SizedBox(height: 12),
        TextFormField(
          controller: textEditingController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),

            hintText: hintext,
          
          ),
        validator: validator,
        
        ),
      ],
    );
  }
}
