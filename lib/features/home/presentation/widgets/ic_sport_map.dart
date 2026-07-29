import 'package:flutter/material.dart';

class IcSportMap extends StatelessWidget {
  final String title;
  final TextStyle? textStyle;

  const IcSportMap({super.key, required this.title, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Text(title, style: textStyle)],
    );
  }
}
