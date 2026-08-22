import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TabRulesWidget extends StatelessWidget {
  const TabRulesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = [
      {
        'title': 'Quy định đặt & huỷ sân',
        'content': 'Vui lòng đặt cọc trước 50% chi phí để giữ sân. Hỗ trợ huỷ hoặc dời lịch miễn phí trước thời gian bắt đầu ít nhất 12 tiếng. Sau thời gian này sẽ không được hoàn cọc.',
      },
      {
        'title': 'Quy định trang phục',
        'content': 'Khách hàng sử dụng giày thể thao đế bằng (giày tennis, pickleball, cầu lông). Không sử dụng giày cao gót, giày đinh hoặc giày đế cứng gây trầy xước mặt sân.',
      },
      {
        'title': 'Giữ gìn vệ sinh chung',
        'content': 'Bỏ rác đúng nơi quy định. Không mang đồ ăn có mùi, thức uống có cồn hoặc hút thuốc lá bên trong khu vực mặt sân thi đấu.',
      },
      {
        'title': 'Thời gian ra vào sân',
        'content': 'Vui lòng đến trước giờ đặt 5-10 phút để chuẩn bị. Bàn giao sân đúng giờ để không làm ảnh hưởng đến ca đấu tiếp theo.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final item = rules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  item['content']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
