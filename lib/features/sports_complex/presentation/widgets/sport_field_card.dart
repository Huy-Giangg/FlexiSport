import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/booking_visual_card.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/sport_show_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SportFieldCard extends StatelessWidget {
  final SportsComplexEntity sportsComplexEntity;

  const SportFieldCard({super.key, required this.sportsComplexEntity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showSportDetail(context);
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/banner/san2.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),

                  Positioned(
                    left: 8,
                    top: 8,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                sportsComplexEntity.rating.toString(),
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Đơn ngày",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Sự kiện",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    right: 8,
                    top: 8,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: Offset(5, 5),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/heart.png',
                            color: AppColors.primaryContainer,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: Offset(5, 5),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/location.png',
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 70, width: 70),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sportsComplexEntity.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                  
                        style: TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: Text(
                        
                          sportsComplexEntity.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                                          
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Row(
                        children: [
                          Image.asset('assets/images/clock.png', scale: 1.4),
                          const SizedBox(width: 4),
                          Text(
                            "${sportsComplexEntity.open_time} - ${sportsComplexEntity.close_time}",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  InkWell(
                    onTap: () {
                      showBookingDialog(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
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

                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSportDetail(BuildContext context) {
    final mainPageProvider = context.read<MainPageProvider>();
    mainPageProvider.hideNavbar();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SportShowDetail(sportsComplexEntity: sportsComplexEntity);
      },
    ).whenComplete(() {
      mainPageProvider.showNavbar();
    });
  }

  void showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // bấm ra ngoài để tắt
      builder: (context) {
        return BookingVisualCard(venueId: sportsComplexEntity.id);
      },
    );
  }
}
