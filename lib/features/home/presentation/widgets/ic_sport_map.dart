import 'package:flutter/material.dart';

class IcSportMap extends StatelessWidget {
  final title;
  final imgPath;
  const IcSportMap({super.key, this.title, this.imgPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
            imgPath,
            height: 36,
            width: 36,
          ),
        const SizedBox(width: 8,),
        Text(title)
      ],
    );
  }
}