import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/booking_visual_card.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/tabs/tab_images_widget.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/tabs/tab_info_widget.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/tabs/tab_reviews_widget.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/tabs/tab_rules_widget.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/tabs/tab_services_widget.dart';
import 'package:flutter/material.dart';

class SportShowDetail extends StatelessWidget {
  final SportsComplexEntity sportsComplexEntity;
  const SportShowDetail({super.key, required this.sportsComplexEntity});

  void showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // bấm ra ngoài để tắt
      builder: (context) {
        return BookingVisualCard(venueId: sportsComplexEntity.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // mở ban đầu 50%
      minChildSize: 0.5, // kéo xuống thấp nhất 50%
      maxChildSize: 1.0, // kéo lên full màn hình
      expand: false,
      builder: (context, scrollController) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    // Đặt chiều cao cho Image để dễ canh Positioned
                    Image.asset(
                      'assets/images/banner/san1.jpg',
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

                    // Dành khoảng trống cho cái thẻ Positioned đè xuống
                    const SizedBox(height: 160),

                    // Phần TabBar & TabBarView cần có chiều cao cố định
                    Container(
                      height:
                          MediaQuery.of(context).size.height *
                          0.6, // Chiều cao cố định tránh lỗi unbounded height
                      child: DefaultTabController(
                        length: 5,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: AppColors.primaryBlack,

                              indicatorColor: AppColors.primaryContainer,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              tabs: [
                                Tab(text: "Thông tin"),
                                Tab(text: "Dịch vụ"),
                                Tab(text: "Hình ảnh"),
                                Tab(text: "Điều khoản & quy định"),
                                Tab(text: "Đánh giá"),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  TabInfoWidget(),
                                  TabServicesWidget(),
                                  TabImagesWidget(
                                    stadiumId: sportsComplexEntity.id,
                                  ),
                                  
                                  TabRulesWidget(),
                                  TabReviewsWidget(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Positioned(
                  top:
                      220, // Nằm đè lên một phần của Image và khoảng trống SizedBox ở trên
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: Offset(0, 5),
                          blurRadius: 10,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              height: 80,
                              width: 80,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 60,
                                    width: 60,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  Text(
                                    sportsComplexEntity.name,
                                    style: TextStyle(
                                      color: AppColors.primaryBlack,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        width: 1,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/icon_sport/ic_pickleball.png',
                                          height: 16,
                                          width: 16,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.sports_tennis,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Pickleball",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/icon/location.png',
                              height: 20,
                              width: 20,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sportsComplexEntity.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/icon/clock.png',
                              height: 20,
                              width: 20,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${sportsComplexEntity.open_time} - ${sportsComplexEntity.close_time}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/icon/phone.png',
                              height: 20,
                              width: 20,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Liên hệ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 196,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade700,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/icon/star.png'),

                          const SizedBox(width: 4),

                          Text(
                            "5.0 (3 đánh giá)",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 140,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Image.asset(
                          'assets/images/location.png',
                          scale: 0.8,
                          color: AppColors.primaryContainer,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Image.asset(
                          'assets/images/heart.png',
                          scale: 0.8,
                          color: AppColors.primaryContainer,
                        ),
                      ),

                      const SizedBox(width: 12),

                      InkWell(
                        onTap: () {
                          showBookingDialog(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Đặt lịch",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
