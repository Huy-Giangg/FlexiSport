import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TabInfoWidget extends StatelessWidget {
  const TabInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Giới thiệu chung",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Sân đạt tiêu chuẩn chất lượng cao với mặt sân phẳng, độ nhám chuẩn giúp bám giày tốt và hạn chế chấn thương. Hệ thống đèn LED chiếu sáng chống chói phục vụ hoàn hảo cho các trận đấu vào buổi tối.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.secondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Thông tin chi tiết",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(Icons.layers, "Loại mặt sân", "Sơn Acrylic chuẩn quốc tế"),
        _buildInfoRow(Icons.lightbulb, "Chiếu sáng", "Hệ thống đèn LED 1000W"),
        _buildInfoRow(Icons.security, "An ninh", "Camera giám sát 24/7"),
        _buildInfoRow(Icons.directions_car, "Bãi đỗ xe", "Miễn phí ô tô & xe máy"),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLightBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
