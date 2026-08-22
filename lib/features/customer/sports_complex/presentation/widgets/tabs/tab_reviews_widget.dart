import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/customer/sports_complex/data/models/sports_complex_model.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabReviewsWidget extends StatefulWidget {
  final String venueId;
  const TabReviewsWidget({super.key, required this.venueId});

  @override
  State<TabReviewsWidget> createState() => _TabReviewsWidgetState();
}

class _TabReviewsWidgetState extends State<TabReviewsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<SportsComplexProvider>();
        provider.fetchVenueReviews(widget.venueId);
      }
    });
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SportsComplexProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thống kê điểm số trung bình
          _buildRatingSummary(provider),
          const SizedBox(height: 20),

          // 3. Tiêu đề bình luận cộng đồng
          const Text(
            "Bình luận từ cộng đồng",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 12),

          // 4. Danh sách các bình luận
          if (provider.isReviewsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (provider.currentVenueReviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Chưa có đánh giá nào cho sân này.\nHãy trở thành người đầu tiên đánh giá!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.currentVenueReviews.length,
              itemBuilder: (context, index) {
                final review = provider.currentVenueReviews[index];
                return _buildReviewCard(review);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(SportsComplexProvider provider) {
    // Tìm điểm số của cơ sở hiện tại
    final currentVenue = provider.stadiums.firstWhere(
      (s) => s.id == widget.venueId,
      orElse: () => provider.stadiums.isEmpty
          ? SportsComplexModel(
              id: widget.venueId,
              name: '',
              address: '',
              logoUrl: '',
              rating: 5.0,
              open_time: '',
              close_time: '',
            )
          : provider.stadiums.first as SportsComplexModel,
    );

    final double avgRating = currentVenue.rating;
    final int totalReviews = provider.currentVenueReviews.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      size: 18,
                      color: index < avgRating.round()
                          ? Colors.amber
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$totalReviews đánh giá thực tế",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 80,
            width: 1,
            color: AppColors.surfaceVariant,
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: List.generate(5, (index) {
                  final starNum = 5 - index;
                  final count = provider.currentVenueReviews
                      .where((r) => r.rating.round() == starNum)
                      .length;
                  final double percent = totalReviews > 0 ? count / totalReviews : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          "$starNum",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 10, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 20,
                          child: Text(
                            "$count",
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildReviewCard(dynamic review) {
    final avatarSeed = review.userId.hashCode.toString();
    final String initial = review.userName.isNotEmpty 
        ? review.userName[0].toUpperCase() 
        : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
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
                radius: 16,
                backgroundColor: AppColors.primaryLightBg,
                backgroundImage: NetworkImage(
                  'https://api.dicebear.com/7.x/avataaars/png?seed=$avatarSeed',
                ),
                onBackgroundImageError: (exception, stackTrace) {},
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
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
                    size: 13,
                    color: starIndex < review.rating.round()
                        ? Colors.amber
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
