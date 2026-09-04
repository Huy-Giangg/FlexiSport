import 'dart:async';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/customer/home/presentation/widgets/header_widget.dart';
import 'package:flexisport_app/features/customer/home/presentation/widgets/ic_sport.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/sport_field_card.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/stadium_shimmer.dart';
import 'package:flexisport_app/features/customer/ai_chat/presentation/widgets/ai_chat_fab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  StreamSubscription<AuthState>? _authSubscription;
  User? _currentUser;
  late final TextEditingController _searchController;

  Map<String, String> listIcon = {
    'Pickleball': 'assets/images/icon_sport/ic_pickleball.png',
    'Cầu lông': 'assets/images/icon_sport/ic_badminton.png',
    'Bóng đá': 'assets/images/icon_sport/ic_football.png',
    'Tennis': 'assets/images/icon_sport/ic_tennis.png',
    'B.chuyền': 'assets/images/icon_sport/ic_voleball.png',
    'Bóng rổ': 'assets/images/icon_sport/ic_basketball.png',
    'Golf': 'assets/images/icon_sport/ic_golf.png',
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _currentUser = Supabase.instance.client.auth.currentUser;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (mounted) {
        setState(() {
          _currentUser = data.session?.user;
        });
      }
    });

    final sportsComplexProvider = context.read<SportsComplexProvider>();
    Future.microtask(() {
      sportsComplexProvider.fetchStadiums();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SportsComplexProvider>();
    final entries = listIcon.entries.toList();
    final double topPadding = MediaQuery.of(context).padding.top;

    bool isSelected = false;

    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: topPadding + 175,
        displacement: 20,
        onRefresh: () async {
          await provider.fetchStadiums();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Collapsible Persistent Header (AppBar co giãn tự động khi cuộn)
            SliverPersistentHeader(
              pinned: true,
              delegate: HomeHeaderDelegate(
                topPadding: topPadding,
                currentUser: _currentUser,
                searchController: _searchController,
                searchQuery: provider.searchQuery,
                showFavoritesOnly: provider.showFavoritesOnly,
                onFavoriteFilterToggled: provider.toggleShowFavoritesOnly,
              ),
            ),

            // 2. Nội dung bộ lọc nhanh, icon môn học và thanh banner mô tả (Sẽ cuộn lên và ẩn dưới Header)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 35),
                  // Thẻ lọc nhanh các sân gần tôi
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Ink(
                  //       child: Container(
                  //         decoration: BoxDecoration(
                  //           borderRadius: BorderRadius.circular(8),
                  //           color: AppColors.primaryLightBg,
                  //         ),
                  //         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  //         child: const Text("Cầu lông gần tôi"),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Ink(
                  //       child: Container(
                  //         decoration: BoxDecoration(
                  //           borderRadius: BorderRadius.circular(8),
                  //           color: AppColors.primaryLightBg,
                  //         ),
                  //         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  //         child: const Text("Pickleball gần tôi"),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Ink(
                  //       child: Container(
                  //         decoration: BoxDecoration(
                  //           borderRadius: BorderRadius.circular(8),
                  //           color: AppColors.primaryLightBg,
                  //         ),
                  //         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  //         child: const Text("Xé vé gần tôi"),
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  //const SizedBox(height: 8,),
                  // Danh sách ngang các bộ môn thể thao
                  SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: listIcon.length,
                      itemBuilder: (context, index) {
                        final nameSport = entries[index].key;
                        final imgPath = entries[index].value;
                        return SizedBox(
                          width: 80,
                          child: IcSport(
                            title: nameSport,
                            imgPath: imgPath,
                            isSelected: provider.selectedSport == nameSport,
                            onTap: () {
                              provider.selectSport(nameSport);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8,),

                  // Banner mô tả tìm kiếm trống
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLightBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.redAccent, size: 28,),
                              const SizedBox(width: 8),
                              const Text(
                                "Tìm sân trống, sự kiện xé vé, ghép đội",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
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
            ),

            // 3. Trạng thái danh sách sân
            if (provider.isLoading && provider.stadiums.isEmpty)
              const SliverToBoxAdapter(child: StadiumShimmerList())
            else if (provider.errorMessage != null && provider.stadiums.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 56,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            provider.fetchStadiums();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("Thử lại"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              if (provider.filteredStadiums.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            provider.showFavoritesOnly
                                ? Icons.favorite_border_rounded
                                : Icons.search_off_rounded,
                            size: 56,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.showFavoritesOnly
                                ? "Danh sách sân yêu thích trống. \nHãy nhấn nút trái tim trên các sân để thêm!"
                                : "Không tìm thấy kết quả cho \"${provider.searchQuery}\"",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final stadium = provider.filteredStadiums[index];
                      return SportFieldCard(sportsComplexEntity: stadium);
                    }, childCount: provider.filteredStadiums.length),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: const AiChatFab(),
    );
  }
}
