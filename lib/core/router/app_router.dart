import 'package:flexisport_app/features/auth/presentation/pages/forgetpass_page.dart';
import 'package:flexisport_app/features/auth/presentation/pages/login_page.dart';
import 'package:flexisport_app/features/auth/presentation/pages/register_page.dart';
import 'package:flexisport_app/features/booking/presentation/pages/visual_booking_page.dart';
import 'package:flexisport_app/features/home/presentation/page/home_page.dart';
import 'package:flexisport_app/features/home/presentation/page/main_page.dart';
import 'package:flexisport_app/features/home/presentation/page/map_page.dart';
import 'package:flexisport_app/features/sports_complex/presentation/page/home_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainPage(child: child);
        },
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginPage(),
          ),

          GoRoute(
            path: '/register',
            name: 'register',
            builder: (context, state) => const RegisterPage(),
          ),

          GoRoute(
            path: '/forgetpass',
            name: 'forgetpass',
            builder: (context, state) => const ForgetpassPage(),
          ),

          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const Home(),
          ),

          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapPage(),
          ),

          GoRoute(
            path: '/homepage',
            name: 'homepage',
            builder: (context, state) => const HomePage(),
          ),

          GoRoute(
            path: '/bookingpage',
            name: 'bookingpage',
            builder: (context, state) {
              final venueId = state.uri.queryParameters['venueId'] ?? '';
              return VisualBookingPage(venueId: venueId);
            },
          ),
        ],
      ),
    ],
  );
}
