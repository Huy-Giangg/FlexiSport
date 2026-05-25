import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  final Widget child;
  const MainPage({super.key, required this.child});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _getIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/register')) return 2;
    if (location.startsWith('/home')) return 3;
    if (location.startsWith('/home')) return 4;
    return 0;
  }

  void _onTabChange(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/register');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);
    final isVisible = context.watch<MainPageProvider>().isVisible;

    return Scaffold(
      body: widget.child,

      bottomNavigationBar: isVisible ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: GNav(
          selectedIndex: currentIndex,
          onTabChange: _onTabChange,
          tabBackgroundColor: AppColors.primary.withOpacity(0.9),
          color: Colors.grey,
          activeColor: Colors.white,
          gap: 8,

          tabs: const [
            GButton(
              icon: Icons.home,
              text: 'Trang chủ',
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              iconSize: 24,
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              iconActiveColor: Colors.white,
            ),
            GButton(
              icon: Icons.map,
              text: 'Bản đồ',
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              iconSize: 24,
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              iconActiveColor: Colors.white,
            ),
            GButton(
              icon: Icons.explore,
              text: 'Khám phá',
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              iconSize: 24,
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              iconActiveColor: Colors.white,
            ),
            GButton(
              icon: Icons.whatshot_sharp,
              text: 'Nổi bật',
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              iconSize: 24,
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              iconActiveColor: Colors.white,
            ),
            GButton(
              icon: Icons.person,
              text: 'Tài khoản',
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              iconSize: 24,
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              iconActiveColor: Colors.white,
            ),
          ],
        ),
      ) : null,
    );
  }
}

