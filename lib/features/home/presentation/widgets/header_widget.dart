import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class BuildHeader extends StatelessWidget {
  const BuildHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 38),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // logo
              Image.asset(
                'assets/images/logo.png',
                height: 100,
                width: 100,
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thứ sáu, 01/05/2026",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // Size(chiều rộng, chiều cao)
                          minimumSize: const Size(140, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {},
                        child: Text("Đăng nhập"),
                      ),

                      const SizedBox(width: 12),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // Size(chiều rộng, chiều cao)
                          minimumSize: const Size(140, 40),
                          side: BorderSide(width: 1, color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),

                          backgroundColor: Colors.transparent,
                        ),
                        onPressed: () {},
                        child: Text(
                          "Đăng kí",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          bottom: -22,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Image.asset(
                        'assets/images/ic_alobo-removebg.png',
                      ),
                      contentPadding: EdgeInsets.all(10),
                      border: InputBorder.none,
                      hintText: "Tìm kiếm",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: Icon(
                        Icons.search,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.favorite_border,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
