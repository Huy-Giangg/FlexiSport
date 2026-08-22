import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0FFF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D38),
        title: Text(
          "Thanh toán",
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/calendar.png",
                    width: 200,
                    height: 200,
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "Đặt lịch thành công",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Lịch đặt của bạn đã được gửi tới chủ sân.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Vui lòng kiểm tra trạng thái lịch đặt tại tab "Tài Khoản" cho tới khi chủ sân xác nhận lịch đặt của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF1EC391),
              ),
              onPressed: () {
                context.read<MainPageProvider>().hideNavbar();
                context.push('/BookedCourtPage?from=payment_success').then((_) {
                  if (context.mounted) {
                    context.read<MainPageProvider>().showNavbar();
                  }
                });
              },
              child: const Text(
                "XEM LỊCH ĐẶT",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.all(12),
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFFE3B02C),
              ),
              onPressed: () {
                context.read<MainPageProvider>().showNavbar();
                context.go("/home");
              },
              child: const Text(
                "QUAY VỀ",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
