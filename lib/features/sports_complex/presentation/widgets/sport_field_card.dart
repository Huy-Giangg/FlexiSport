import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/core/utils/location_helper.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/booking_visual_card.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/sport_show_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SportFieldCard extends StatelessWidget {
  final SportsComplexEntity sportsComplexEntity;

  const SportFieldCard({super.key, required this.sportsComplexEntity});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SportsComplexProvider>();
    final isFavorite = provider.favoriteStadiumIds.contains(
      sportsComplexEntity.id,
    );

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
                    child: _buildLogoImage(sportsComplexEntity.logoUrl),
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
                        const SizedBox(width: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_run,
                                size: 14,
                                color: Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                LocationHelper.formatDistance(
                                  LocationHelper.calculateDistanceFromDefault(
                                    sportsComplexEntity.latitude,
                                    sportsComplexEntity.longitude,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
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
                        GestureDetector(
                          onTap: () {
                            context
                                .read<SportsComplexProvider>()
                                .toggleFavorite(sportsComplexEntity.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? Colors.red
                                  : AppColors.primaryContainer,
                              size: 20,
                            ),
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
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Text(
                          sportsComplexEntity.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        
                          style: TextStyle(
                            color: AppColors.primaryContainer,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
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

  Widget _buildLogoImage(String logoUrl) {
    if (logoUrl.isEmpty) {
      return _buildPlaceholder();
    }
    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return Image.asset(
      logoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      width: double.infinity,
      child: const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }
}
