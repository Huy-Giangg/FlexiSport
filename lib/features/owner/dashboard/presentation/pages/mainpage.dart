import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainPageOwner extends StatefulWidget {
  final String? shellLocation;
  final Widget child;
  const MainPageOwner({super.key, this.shellLocation, required this.child});

  @override
  State<MainPageOwner> createState() => _MainPageOwnerState();
}

class _MainPageOwnerState extends State<MainPageOwner> {
  int _getIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/owner/courts')) return 1;
    if (location.startsWith('/owner/bookings')) return 2;
    if (location.startsWith('/owner/events')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTabChange(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/dashboard');
        break;
      case 2:
        context.go('/dashboard');
        break;
      case 3:
        context.go('/dashboard');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    String location = widget.shellLocation ?? '';
    if (location.isEmpty) {
      try {
        location = GoRouterState.of(context).uri.toString();
      } catch (_) {
        location = '/dashboard';
      }
    }
    final currentIndex = _getIndex(location);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
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
              icon: Icons.dashboard,
              text: 'Tổng quan',
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
              icon: Icons.stadium_rounded,
              text: 'Sân',
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
              icon: Icons.calendar_today_rounded,
              text: 'Đặt sân',
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
              icon: Icons.event,
              text: 'Sự kiện',
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
      ),
    );
  }
}
