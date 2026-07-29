import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BookingVisualCard extends StatefulWidget {
  final String venueId;
  const BookingVisualCard({super.key, required this.venueId});

  @override
  State<BookingVisualCard> createState() => _BookingVisualCardState();
}

class _BookingVisualCardState extends State<BookingVisualCard> {
  bool _isPressedOne = false;
  bool _isPressedTwo = false;
  @override
  Widget build(BuildContext context) {
    
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 12),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Align(
              alignment: AlignmentGeometry.centerRight,
              heightFactor: 0.4,
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 32),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Text(
              "Chọn hình thức đặt",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            GestureDetector(
              onTapDown: (details) {
                setState(() {
                  _isPressedOne = true;
                });
              },

              onTapUp: (details) {
                setState(() {
                  _isPressedOne = false;
                  Navigator.pop(context);
                  context.read<MainPageProvider>().hideNavbar();
                  context.push('/bookingpage?venueId=${widget.venueId}');
                });
              },

              onTapCancel: () => setState(() => _isPressedOne = false),

              child: AnimatedScale(
                scale: _isPressedOne ? 0.95 : 1.0, // Thu nhỏ xuống 95% khi nhấn
                duration: Duration(milliseconds: 100), // Thời gian hiệu ứng
                curve: Curves.easeInOut,
                child: Container(
                  width: double.infinity,
                  // Dùng ClipRRect để nút bo góc ở góc dưới cùng bên phải không bị lem ra ngoài
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      color: Color(0xFFE4FCE0),
                      child: Stack(
                        children: [
                          // Phần nội dung Text bên trái và ở giữa
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 10.0,
                              top: 10.0,
                              right:
                                  20.0, // Trừa khoảng trống bên phải để không bị đè lên nút
                              bottom: 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  'Đặt lịch ngày trực quan',
                                  style: TextStyle(
                                    color: Color(0xFF1E8305),
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  'Đặt lịch ngày khi khách chơi nhiều khung giờ, nhiều sân.',
                                  style: TextStyle(
                                    color: Color(0xFF2C3E29).withOpacity(0.9),
                                    fontSize: 14.0,
                                    height:
                                        1.4, // Tạo khoảng cách giãn dòng cho tự nhiên
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Nút mũi tên nằm ở góc dưới cùng bên phải
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 56.0,
                              height: 40.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3CD004),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16.0),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            GestureDetector(
              onTapDown: (details) {
                setState(() {
                  _isPressedTwo = true;
                });
              },

              onTapUp: (details) {
                
                setState(() {
                  _isPressedTwo = false;

                  Navigator.pop(context);

                  context.read<MainPageProvider>().hideNavbar();

                  context.push('/EventBookingPage?venueId=${widget.venueId}');
                });
              },

              onTapCancel: () {
                setState(() {
                  _isPressedTwo = false;
                });
              },
              child: AnimatedScale(
                scale: _isPressedTwo ? 0.95 : 1.0 ,
                duration: Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                child: Container(
                  width: double.infinity,
                  // Dùng ClipRRect để nút bo góc ở góc dưới cùng bên phải không bị lem ra ngoài
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      color: Color(0xFFFCE9FC),
                      child: Stack(
                        children: [
                          // Phần nội dung Text bên trái và ở giữa
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 10.0,
                              top: 10.0,
                              right:
                                  20.0, // Trừa khoảng trống bên phải để không bị đè lên nút
                              bottom: 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                
                              children: [
                                const Text(
                                  'Đặt lịch sự kiện',
                                  style: TextStyle(
                                    color: Color(0xFFB313B2),
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  'Sự kiện giúp bạn chơi chung với người có cùng niềm đam mê, trình độ. Hay những giải đấu mang tính cạnh tranh cao, nâng cao trình độ do chủ sân tổ chức',
                                  style: TextStyle(
                                    color: Color(0xFFC436C7).withOpacity(0.9),
                                    fontSize: 14.0,
                                    height:
                                        1.4, // Tạo khoảng cách giãn dòng cho tự nhiên
                                  ),
                                ),
                              ],
                            ),
                          ),
                
                          // Nút mũi tên nằm ở góc dưới cùng bên phải
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 56.0,
                              height: 40.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE27BE5),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16.0),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
