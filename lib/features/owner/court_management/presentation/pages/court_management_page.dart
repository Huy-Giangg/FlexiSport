import 'package:flutter/material.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class CourtManagementPage extends StatelessWidget {
  const CourtManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý cụm sân'),
        backgroundColor: AppColors.background,
      ),
      body: const Center(
        child: Text(
          'Màn hình Quản lý cụm sân & danh sách sân con',
          style: TextStyle(fontSize: 16, color: AppColors.onBackground),
        ),
      ),
    );
  }
}
