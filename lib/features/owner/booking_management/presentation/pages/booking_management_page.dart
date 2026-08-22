import 'package:flutter/material.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';

class BookingManagementPage extends StatelessWidget {
  const BookingManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đặt sân'),
        backgroundColor: AppColors.background,
      ),
      body: const Center(
        child: Text(
          'Màn hình Xem & Duyệt danh sách đơn đặt sân',
          style: TextStyle(fontSize: 16, color: AppColors.onBackground),
        ),
      ),
    );
  }
}
