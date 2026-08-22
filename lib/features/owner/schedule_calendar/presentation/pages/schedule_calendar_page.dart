import 'package:flutter/material.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class ScheduleCalendarPage extends StatelessWidget {
  const ScheduleCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch biểu trực quan'),
        backgroundColor: AppColors.background,
      ),
      body: const Center(
        child: Text(
          'Màn hình Lịch biểu trực quan (Calendar view) theo từng sân',
          style: TextStyle(fontSize: 16, color: AppColors.onBackground),
        ),
      ),
    );
  }
}
