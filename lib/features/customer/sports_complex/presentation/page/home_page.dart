import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/sport_field_card.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/widgets/stadium_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    final sportsComplexProvider = context.read<SportsComplexProvider>();
    Future.microtask(() {
      sportsComplexProvider.fetchStadiums();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SportsComplexProvider>();

    // 1. Chỉ hiển thị Shimmer xương khi đang tải và chưa có dữ liệu nào (kể cả cache)
    if (provider.isLoading && provider.stadiums.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Stadiums"),
        ),
        body: const SingleChildScrollView(
          child: StadiumShimmerList(),
        ),
      );
    }

    // 2. Chỉ hiển thị giao diện báo lỗi khi không thể tải API và cũng không có dữ liệu cache
    if (provider.errorMessage != null && provider.stadiums.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Stadiums"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.fetchStadiums();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Thử lại"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Hiển thị danh sách sân (hoặc từ cache hoặc từ API mới nhất)
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stadiums"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchStadiums();
        },
        child: provider.stadiums.isEmpty
            ? const Center(
                child: Text("Không có sân nào khả dụng!"),
              )
            : ListView.builder(
                itemCount: provider.stadiums.length,
                itemBuilder: (context, index) {
                  final stadium = provider.stadiums[index];
                  return SportFieldCard(sportsComplexEntity: stadium);
                },
              ),
      ),
    );
  }
}