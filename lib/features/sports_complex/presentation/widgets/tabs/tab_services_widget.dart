import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TabServicesWidget extends StatelessWidget {
  const TabServicesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'name': 'Thuê vợt Pickleball', 'price': '30.000 đ / buổi', 'icon': Icons.sports_tennis},
      {'name': 'Bóng tập chất lượng', 'price': '10.000 đ / quả', 'icon': Icons.sports_baseball},
      {'name': 'Nước suối & Nước khoáng', 'price': '10.000 đ - 20.000 đ', 'icon': Icons.local_drink},
      {'name': 'Thuê giày thể thao', 'price': '40.000 đ / buổi', 'icon': Icons.roller_skating},
      {'name': 'Tủ đồ cá nhân (Locker)', 'price': 'Miễn phí', 'icon': Icons.lock},
      {'name': 'Phòng tắm & Thay đồ', 'price': 'Miễn phí', 'icon': Icons.shower},
      {'name': 'Wifi tốc độ cao', 'price': 'Miễn phí', 'icon': Icons.wifi},
      {'name': 'Hỗ trợ y tế cơ bản', 'price': 'Miễn phí', 'icon': Icons.medical_services},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item['price'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: item['price'] == 'Miễn phí'
                      ? AppColors.primary
                      : Colors.orange.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
