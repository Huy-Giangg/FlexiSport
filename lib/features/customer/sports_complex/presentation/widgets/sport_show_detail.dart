import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/core/utils/location_helper.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_images_widget.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_info_widget.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_reviews_widget.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_rules_widget.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/tabs/tab_services_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SportShowDetail extends StatelessWidget {
  final SportsComplexEntity sportsComplexEntity;
  const SportShowDetail({super.key, required this.sportsComplexEntity});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // mở ban đầu 50%
      minChildSize: 0.5, // kéo xuống thấp nhất 50%
      maxChildSize: 1.0, // kéo lên full màn hình
      expand: false,
      builder: (context, scrollController) {
        final provider = context.watch<SportsComplexProvider>();
        final isFavorite = provider.favoriteStadiumIds.contains(
          sportsComplexEntity.id,
        );

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
                    _buildLogoImage(sportsComplexEntity.logoUrl),

                    // Dành khoảng trống cho cái thẻ Positioned đè xuống
                    const SizedBox(height: 190),

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
                                  TabReviewsWidget(
                                    venueId: sportsComplexEntity.id,
                                  ),
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
                      130, // Nằm đè lên một phần của Image và khoảng trống SizedBox ở trên
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
                                  Row(
                                    children: [
                                      Text(
                                        sportsComplexEntity.name,
                                        style: TextStyle(
                                          color: AppColors.primaryBlack,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent.shade700,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              sportsComplexEntity.rating
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  _buildSportTag(
                                    sportsComplexEntity.sportsType,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sportsComplexEntity.address,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Khoảng cách: ${LocationHelper.formatDistance(LocationHelper.calculateDistanceFromDefault(sportsComplexEntity.latitude, sportsComplexEntity.longitude))}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
                                "0354676200",
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
                  top: 50,
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

                      const SizedBox(width: 12),

                      GestureDetector(
                        onTap: () {
                          context.read<SportsComplexProvider>().toggleFavorite(
                            sportsComplexEntity.id,
                          );
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
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? Colors.red
                                : AppColors.primaryContainer,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      InkWell(
                        onTap: () {
                          Navigator.pop(context, 'book');
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

  Widget _buildLogoImage(String logoUrl) {
    if (logoUrl.isEmpty) {
      return _buildPlaceholder();
    }
    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return Image.asset(
      logoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 200,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 52, color: Colors.grey.shade500),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSportTag(String? sportsType) {
    final sportInfo = _getSportInfo(sportsType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sportInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: sportInfo.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sportInfo.iconPath.isNotEmpty)
            Image.asset(
              sportInfo.iconPath,
              height: 16,
              width: 16,
              errorBuilder: (context, error, stackTrace) => Icon(
                sportInfo.fallbackIcon,
                size: 16,
                color: sportInfo.color,
              ),
            )
          else
            Icon(sportInfo.fallbackIcon, size: 16, color: sportInfo.color),
          const SizedBox(width: 4),
          Text(
            sportInfo.name,
            style: TextStyle(fontSize: 12, color: sportInfo.color),
          ),
        ],
      ),
    );
  }

  _SportInfo _getSportInfo(String? sportsType) {
    final type = sportsType?.trim() ?? '';
    final lowercaseType = type.toLowerCase();

    if (lowercaseType.contains('pickleball')) {
      return _SportInfo(
        name: type.isNotEmpty ? type : 'Pickleball',
        iconPath: 'assets/images/icon_sport/ic_pickleball.png',
        fallbackIcon: Icons.sports_tennis,
        color: Colors.blueAccent,
      );
    } else if (lowercaseType.contains('cầu lông') ||
        lowercaseType.contains('badminton')) {
      return _SportInfo(
        name: type.isNotEmpty ? type : 'Cầu lông',
        iconPath: 'assets/images/icon_sport/ic_badminton.png',
        fallbackIcon: Icons.sports_tennis,
        color: Colors.greenAccent,
      );
    } else if (lowercaseType.contains('bóng đá') ||
        lowercaseType.contains('football') ||
        lowercaseType.contains('soccer')) {
      return _SportInfo(
        name: type.isNotEmpty ? type : 'Bóng đá',
        iconPath: 'assets/images/icon_sport/ic_football.png',
        fallbackIcon: Icons.sports_soccer,
        color: Colors.green,
      );
    } else if (lowercaseType.contains('tennis')) {
      return _SportInfo(
        name: type.isNotEmpty ? type : 'Tennis',
        iconPath: 'assets/images/icon_sport/ic_tennis.png',
        fallbackIcon: Icons.sports_tennis,
        color: Colors.brown,
      );
    } else if (lowercaseType.contains('chuyền') ||
        lowercaseType.contains('volleyball')) {
      return _SportInfo(
        name: type.isNotEmpty ? type : 'Bóng chuyền',
        iconPath: 'assets/images/icon_sport/ic_voleball.png',
        fallbackIcon: Icons.sports_volleyball,
        color: Colors.yellow,
      );
    } else if (lowercaseType.contains('bóng rổ') ||
        lowercaseType.contains('basketball')) {
      return _SportInfo(
        name: type.isNotEmpty ? type : 'Bóng rổ',
        iconPath: 'assets/images/icon_sport/ic_basketball.png',
        fallbackIcon: Icons.sports_basketball,
        color: Colors.brown,
      );
    } else if (lowercaseType.contains('golf')) {
      return _SportInfo(
        name: type.isNotEmpty ? type : 'Golf',
        iconPath: 'assets/images/icon_sport/ic_golf.png',
        fallbackIcon: Icons.sports_golf,
        color: Colors.teal,
      );
    }

    return _SportInfo(
      name: type.isNotEmpty ? type : 'Thể thao',
      iconPath: '',
      fallbackIcon: Icons.sports,
      color: Colors.blueAccent,
    );
  }
}

class _SportInfo {
  final String name;
  final String iconPath;
  final IconData fallbackIcon;
  final Color color;

  _SportInfo({
    required this.name,
    required this.iconPath,
    required this.fallbackIcon,
    required this.color,
  });
}
