import 'package:flutter/material.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class OwnerAnalyticsPage extends StatelessWidget {
  const OwnerAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        backgroundColor: AppColors.background,
      ),
      body: const Center(
        child: Text(
          'Màn hình Báo cáo doanh thu & tỷ lệ lấp đầy sân',
          style: TextStyle(fontSize: 16, color: AppColors.onBackground),
        ),
      ),
    );
  }
}
