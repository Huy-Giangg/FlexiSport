import 'package:firebase_core/firebase_core.dart';
import 'package:flexisport_app/core/router/app_router.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/customer/booking/data/datasources/booking_remote_datasource.dart';
import 'package:flexisport_app/features/customer/booking/data/repositories/booking_repository_impl.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_courts_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/hold_slot_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/release_slot_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_active_locks_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_booked_slots_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_court_blocks_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_event_slots_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_events_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/book_event_usecase.dart';
import 'package:flexisport_app/features/customer/booking/domain/usecase/get_user_event_bookings_usecase.dart';
import 'package:flexisport_app/features/customer/booking/presentation/providers/booking_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/data/datasources/sports_complex_remote_datasource.dart';
import 'package:flexisport_app/features/customer/sports_complex/data/repositories/sports_complex_repository_impl.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/usecases/get_sports_complex_images_usecase.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/usecases/get_sports_complex_usecase.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/usecases/get_venue_reviews_usecase.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/usecases/submit_venue_review_usecase.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flexisport_app/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/config/app_config.dart';
import 'package:flexisport_app/features/customer/matchmaking/data/datasources/matchmaking_remote_datasource.dart';
import 'package:flexisport_app/features/customer/matchmaking/data/repositories/matchmaking_repository_impl.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/providers/matchmaking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Khởi tạo dịch vụ thông báo
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  // datasource
  final remoteDataSource = SportsComplexRemoteDatasource();

  // repository
  final repository = SportsComplexRepositoryImpl(remoteDataSource);

  // usecase
  final useCase = GetSportsComplexUsecase(repository);
  final imagesUseCase = GetSportsComplexImagesUsecase(repository);
  final getVenueReviewsUseCase = GetVenueReviewsUsecase(repository);
  final submitVenueReviewUseCase = SubmitVenueReviewUsecase(repository);

  final bookingDataSource = BookingRemoteDatasource(Supabase.instance.client);
  final bookingRepository = BookingRepositoryImpl(bookingDataSource);
  final getCourtsUseCase = GetCourtsUsecase(bookingRepository);
  final holdSlotUsecase = HoldSlotUsecase(bookingRepository);
  final releaseSlotUsecase = ReleaseSlotUsecase(bookingRepository);
  final getActiveLocksUsecase = GetActiveLocksUsecase(bookingRepository);
  final getBookedSlotsUsecase = GetBookedSlotsUsecase(bookingRepository);
  final getCourtBlocksUsecase = GetCourtBlocksUsecase(bookingRepository);
  final getEventSlotsUsecase = GetEventSlotsUsecase(bookingRepository);
  final getEventsUseCase = GetEventsUsecase(bookingRepository);
  final bookEventUseCase = BookEventUsecase(bookingRepository);
  final getUserEventBookingsUseCase = GetUserEventBookingsUsecase(bookingRepository);

  final matchmakingDataSource = MatchmakingRemoteDatasource(Supabase.instance.client);
  final matchmakingRepository = MatchmakingRepositoryImpl(matchmakingDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SportsComplexProvider(
            useCase,
            imagesUseCase,
            getVenueReviewsUseCase,
            submitVenueReviewUseCase,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MainPageProvider()),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(
            getCourtsUseCase,
            holdSlotUsecase,
            releaseSlotUsecase,
            getActiveLocksUsecase,
            getBookedSlotsUsecase,
            getCourtBlocksUsecase,
            getEventSlotsUsecase,
            getEventsUseCase,
            bookEventUseCase,
            getUserEventBookingsUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MatchmakingProvider(repository: matchmakingRepository),
        ),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(  
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: AppColors.primary)),
      routerConfig: AppRouter.router,
    );
  }
}
