import 'dart:async';
import 'package:flexisport_app/features/auth/presentation/pages/forgetpass_page.dart';
import 'package:flexisport_app/features/auth/presentation/pages/login_page.dart';
import 'package:flexisport_app/features/auth/presentation/pages/register_page.dart';
import 'package:flexisport_app/features/customer/booking/presentation/pages/booked_court_page.dart';
import 'package:flexisport_app/features/customer/booking/presentation/pages/booked_detail_page.dart';
import 'package:flexisport_app/features/customer/booking/presentation/pages/event_booking_page.dart';
import 'package:flexisport_app/features/customer/booking/presentation/pages/event_booking_detail_page.dart';
import 'package:flexisport_app/features/customer/booking/presentation/pages/visual_booking_page.dart';
import 'package:flexisport_app/features/customer/home/presentation/page/home_page.dart';
import 'package:flexisport_app/features/customer/home/presentation/page/main_page.dart';
import 'package:flexisport_app/features/customer/home/presentation/page/map_page.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/pages/matchmaking_board_page.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/pages/create_matchmaking_page.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/pages/matchmaking_detail_page.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/pages/manage_requests_page.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/payment_cancel_page.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/payment_confirm_page.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/payment_info_page.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/payment_success_page.dart';
import 'package:flexisport_app/features/auth/presentation/pages/profile_page.dart';
import 'package:flexisport_app/features/owner/dashboard/presentation/pages/mainpage.dart';
import 'package:flexisport_app/features/owner/dashboard/presentation/pages/owner_dashboard_page.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/pages/court_management_page.dart';
import 'package:flexisport_app/features/owner/booking_management/presentation/pages/booking_management_page.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/pages/owner_event_management_page.dart';
import 'package:flexisport_app/features/owner/analytics/presentation/pages/analytics_page.dart';
import 'package:flexisport_app/features/owner/profile/presentation/pages/owner_profile_page.dart';
import 'package:flexisport_app/features/owner/profile/presentation/pages/owner_profile_detail_page.dart';
import 'package:flexisport_app/features/profile/presentation/page/profile_detail_page.dart';
import 'package:flexisport_app/features/profile/presentation/page/profile_edit_page.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/page/home_page.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/event_entity.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/event_payment_info_page.dart';
import 'package:flexisport_app/features/customer/payment/presentation/page/event_payment_confirm_page.dart';
import 'package:flexisport_app/features/customer/discover/presentation/pages/discover_page.dart';
import 'package:flexisport_app/features/customer/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final user = session?.user;

      final String? userRole = user?.userMetadata?['role'] ?? user?.appMetadata['role'];
      final currentLocation = state.uri.toString();
      final isAuthPage = currentLocation == '/login' || currentLocation == '/register' || currentLocation == '/forgetpass';

      // 1. Chưa đăng nhập:
      if (session == null) {
        // Cố truy cập trang dành riêng cho chủ sân -> Đẩy sang login
        if (currentLocation.startsWith('/dashboard') || currentLocation.startsWith('/owner')) {
          return '/login';
        }
        // Khách vãng lai -> Cho phép ở lại /home và các trang xem tự do
        return null;
      }

      // 2. Đã đăng nhập:
      // Nếu đang ở màn auth (/login, /register,...) hoặc màn hình gốc '/'
      if (isAuthPage || currentLocation == '/') {
        if (userRole == 'owner') {
          return '/dashboard'; // Điều hướng tới màn Dashboard chủ sân
        } else {
          return '/home';      // Điều hướng tới màn Home khách hàng
        }
      }

      // Nếu là Chủ sân nhưng app mở lên mặc định ở /home -> Tự động chuyển sang /dashboard
      if (userRole == 'owner' && currentLocation == '/home') {
        return '/dashboard';
      }

      // Nếu là Khách hàng nhưng cố truy cập trang chủ sân -> Đẩy về /home
      if (userRole != 'owner' && (currentLocation.startsWith('/dashboard') || currentLocation.startsWith('/owner'))) {
        return '/home';
      }

      return null;
    },
    routes: [
      // ShellRoute Khách hàng
      ShellRoute(
        builder: (context, state, child) {
          return MainPage(
            shellLocation: state.uri.toString(),
            child: child,
          );
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

          // Customer routes
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const Home(),
          ),

          GoRoute(
            path: '/discover',
            name: 'discover',
            builder: (context, state) => const DiscoverPage(),
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

          GoRoute(
            path: '/paymentinfopage',
            name: 'paymentinfopage',
            builder: (context, state) {
              final args = state.extra as PaymentInfoArgs;
              return PaymentInfoPage(args: args);
            },
          ),

          GoRoute(
            path: '/PaymentConfirmPage',
            name: 'PaymentConfirmPage',
            builder: (context, state) {
              final extra = state.extra;
              if (extra == null) {
                // Nếu bị null (khi Hot Restart), tự động quay về trang chủ thay vì crash
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/home');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF006D38))),
                );
              }
              final args = extra as PaymentConfirmArgs;
              return PaymentConfirmPage(args: args);
            },
          ),

          GoRoute(
            path: '/PaymentCancelPage',
            name: 'PaymentCancelPage',
            builder: (context, state) => const PaymentCancelPage(),
          ),

          GoRoute(
            path: '/PaymentSuccessPage',
            name: 'PaymentSuccessPage',
            builder: (context, state) => const PaymentSuccessPage(),
          ),

          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),

          GoRoute(
            path: '/ProfileDetailPage',
            name: 'ProfileDetailPage',
            builder: (context, state) {
              final user = state.extra as User?;
              return ProfileDetailPage(user: user);
            },
          ),

          GoRoute(
            path: '/ProfileEditPage',
            name: 'ProfileEditPage',
            builder: (context, state) {
              final user = state.extra as User?;
              return ProfileEditPage(user: user);
            },
          ),

          GoRoute(
            path: '/BookedCourtPage',
            name: 'BookedCourtPage',
            builder: (context, state) {
              final from = state.uri.queryParameters['from'] ?? '';
              return BookedCourtPage(from: from);
            },
          ),

          GoRoute(
            path: '/BookedDetailPage',
            name: 'BookedDetailPage',
            builder: (context, state) {
              final booking = state.extra as Map<String, dynamic>?;
              return BookedDetailPage(booking: booking);
            },
          ),

          GoRoute(
            path: '/EventBookingPage',
            name: 'EventBookingPage',
            builder: (context, state) {
              final venueId = state.uri.queryParameters['venueId'] ?? '';
              return EventBookingPage(venueId: venueId);
            },
          ),

          GoRoute(
            path: '/EventBookingDetailPage',
            name: 'EventBookingDetailPage',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return EventBookingDetailPage(
                event: args['event'] as EventEntity,
                bookedCount: args['bookedCount'] as int,
                showNavbarOnPop: args['showNavbarOnPop'] as bool? ?? false,
              );
            },
          ),

          GoRoute(
            path: '/EventPaymentInfoPage',
            name: 'EventPaymentInfoPage',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return EventPaymentInfoPage(
                event: args['event'] as EventEntity,
                ticketCount: args['ticketCount'] as int,
                totalAmount: args['totalAmount'] as double,
              );
            },
          ),

          GoRoute(
            path: '/EventPaymentConfirmPage',
            name: 'EventPaymentConfirmPage',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return EventPaymentConfirmPage(
                event: args['event'] as EventEntity,
                ticketCount: args['ticketCount'] as int,
                totalAmount: args['totalAmount'] as double,
                name: args['name'] as String,
                phone: args['phone'] as String,
                note: args['note'] as String,
              );
            },
          ),

          GoRoute(
            path: '/MatchmakingBoardPage',
            name: 'MatchmakingBoardPage',
            builder: (context, state) => const MatchmakingBoardPage(),
          ),

          GoRoute(
            path: '/CreateMatchmakingPage',
            name: 'CreateMatchmakingPage',
            builder: (context, state) {
              final bookingId = state.extra as String;
              return CreateMatchmakingPage(bookingId: bookingId);
            },
          ),

          GoRoute(
            path: '/MatchmakingDetailPage',
            name: 'MatchmakingDetailPage',
            builder: (context, state) {
              final post = state.extra as MatchmakingPost;
              return MatchmakingDetailPage(post: post);
            },
          ),

          GoRoute(
            path: '/ManageRequestsPage',
            name: 'ManageRequestsPage',
            builder: (context, state) {
              final postId = (state.extra as String?) ?? state.uri.queryParameters['postId'] ?? '';
              return ManageRequestsPage(postId: postId);
            },
          ),
        ],
      ),

      // ShellRoute Chủ sân
      ShellRoute(
        builder: (context, state, child) {
          return MainPageOwner(
            shellLocation: state.uri.toString(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const OwnerDashboardPage(),
          ),
          GoRoute(
            path: '/owner/courts',
            name: 'owner_courts',
            builder: (context, state) => const CourtManagementPage(),
          ),
          GoRoute(
            path: '/owner/bookings',
            name: 'owner_bookings',
            builder: (context, state) => const BookingManagementPage(),
          ),
          GoRoute(
            path: '/owner/calendar',
            name: 'owner_calendar',
            builder: (context, state) => const OwnerEventManagementPage(),
          ),
          GoRoute(
            path: '/owner/events',
            name: 'owner_events',
            builder: (context, state) => const OwnerEventManagementPage(),
          ),
          GoRoute(
            path: '/owner/analytics',
            name: 'owner_analytics',
            builder: (context, state) => const OwnerAnalyticsPage(),
          ),
          GoRoute(
            path: '/owner/profile',
            name: 'owner_profile',
            builder: (context, state) => const OwnerProfilePage(),
          ),
          GoRoute(
            path: '/owner/profile/detail',
            name: 'owner_profile_detail',
            builder: (context, state) => const OwnerProfileDetailPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/ai-chat',
        name: 'ai_chat',
        builder: (context, state) => const AiChatPage(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
