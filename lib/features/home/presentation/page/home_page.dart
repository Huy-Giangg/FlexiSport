import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/home/presentation/widgets/header_widget.dart';
import 'package:flexisport_app/features/home/presentation/widgets/ic_sport.dart';
import 'package:flexisport_app/features/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/sport_field_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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

    Future.microtask(() {
      context.read<SportsComplexProvider>().fetchStadiums();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SportsComplexProvider>();
    final entries = listIcon.entries.toList();

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Stadiums")),
        body: Center(
          child: Text(
            provider.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BuildHeader(),

            const SizedBox(height: 42),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Ink(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primaryLightBg,
                    ),
                    padding: const EdgeInsets.all(12),

                    child: Text("Cầu lông gần tôi"),
                  ),
                ),

                const SizedBox(width: 12),

                Ink(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primaryLightBg,
                    ),
                    padding: const EdgeInsets.all(12),

                    child: Text("Pickleball gần tôi"),
                  ),
                ),

                const SizedBox(width: 12),

                Ink(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primaryLightBg,
                    ),
                    padding: const EdgeInsets.all(12),

                    child: Text("Xé vé gần tôi"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 80,
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: listIcon.length,

                itemBuilder: (context, index) {
                  final nameSport = entries[index].key;
                  final imgPath = entries[index].value;
                  return SizedBox(
                    width: 80,
                    child: IcSport(title: nameSport, imgPath: imgPath),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    "Tìm sân trống, sự kiện xé vé, ghép đội",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 40),
                  Icon(Icons.tune, color: AppColors.primaryContainer, size: 24),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 500,
              child: ListView.builder(
                itemCount: provider.stadiums.length,
                itemBuilder: (context, index) {
                  final stadium = provider.stadiums[index];

                  return SportFieldCard(sportsComplexEntity: stadium);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
