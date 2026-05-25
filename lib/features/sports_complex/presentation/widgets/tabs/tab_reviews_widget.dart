import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TabReviewsWidget extends StatelessWidget {
  const TabReviewsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = [
      {
        'name': 'Nguyễn Văn A',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=John',
        'rating': 5,
        'date': '12/05/2026',
        'content': 'Sân quá đẹp, mặt sân êm và bóng nảy chuẩn. Đèn sáng nhưng không bị chói mắt. Sẽ ghé lại thường xuyên!',
      },
      {
        'name': 'Trần Thị B',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=Jane',
        'rating': 5,
        'date': '10/05/2026',
        'content': 'Chủ sân nhiệt tình, có đầy đủ nước uống và dịch vụ cho thuê vợt xịn. Bãi gửi xe siêu rộng rãi.',
      },
      {
        'name': 'Lê Hoàng C',
        'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=Bob',
        'rating': 5,
        'date': '08/05/2026',
        'content': 'Giá hợp lý so với mặt bằng chung. Không gian mát mẻ, sạch sẽ. Đánh giá 5 sao cho chất lượng dịch vụ.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final item = reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLightBg,
                    backgroundImage: NetworkImage(item['avatar'] as String),
                    onBackgroundImageError: (exception, stackTrace) {},
                    child: Text(
                      (item['name'] as String)[0],
                      style: const TextStyle(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Text(
                          item['date'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (starIndex) => Icon(
                        Icons.star,
                        size: 14,
                        color: starIndex < (item['rating'] as int)
                            ? Colors.amber
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item['content'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
