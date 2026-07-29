import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/services/notification_service.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  final Widget child;
  final String? shellLocation;
  const MainPage({super.key, required this.child, this.shellLocation});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Đăng ký thông báo ngay lập tức nếu đã đăng nhập sẵn
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      NotificationService.instance.subscribeToMatchmakingRequests(currentUser.id);
      NotificationService.instance.syncMatchReminders(currentUser.id);
    }

    // Lắng nghe thay đổi trạng thái đăng nhập
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        NotificationService.instance.subscribeToMatchmakingRequests(user.id);
        NotificationService.instance.syncMatchReminders(user.id);
      } else {
        NotificationService.instance.unsubscribeFromMatchmakingRequests();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  int _getIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/discover')) return 2;
    if (location.startsWith('/MatchmakingBoardPage')) return 3;
    if (location.startsWith('/profile')) return 4;
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
        context.go('/discover');
        break;
      case 3:
        context.go('/MatchmakingBoardPage');
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
        location = '/home';
      }
    }
    final currentIndex = _getIndex(location);
    final isVisible = context.watch<MainPageProvider>().isVisible;

    return Scaffold(
      body: widget.child,

      bottomNavigationBar: isVisible
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.white,

                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
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
                    icon: Icons.group_add_rounded,
                    text: 'Ghép kèo',
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
            )
          : null,
    );
  }
}
