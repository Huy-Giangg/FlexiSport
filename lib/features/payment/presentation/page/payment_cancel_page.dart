import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';

class PaymentCancelPage extends StatelessWidget {
  const PaymentCancelPage({super.key});

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
      body: Column(children: [
          Expanded(child: Image.asset("assets/images/clock_error.png", width: 200, height: 200,),),

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
                  context.read<MainPageProvider>().showNavbar();
                  context.go("/profile");
                },
                child: const Text(
                  "XEM LỊCH ĐÃ HỦY",
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
