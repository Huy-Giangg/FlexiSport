import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/core/router/app_router.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _realtimeChannel;

  Future<void> init() async {
    // 1. Khởi tạo múi giờ
    tz.initializeTimeZones();
    // Đặt mặc định múi giờ Việt Nam
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {
      // Đề phòng lỗi cấu hình môi trường
    }

    // 2. Cấu hình ban đầu cho Android và iOS
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Tạo các Notification Channel cho Android
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'match_reminders',
          'Nhắc lịch thi đấu',
          description: 'Thông báo nhắc lịch thi đấu trước 1 tiếng',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'matchmaking_requests',
          'Yêu cầu ghép kèo',
          description: 'Thông báo khi có người mới xin tham gia kèo',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload);
        final route = data['route'] as String?;
        final postId = data['postId'] as String?;
        if (route != null && route.isNotEmpty) {
          if (route == '/ManageRequestsPage' && postId != null) {
            AppRouter.router.push(route, extra: postId);
          } else {
            AppRouter.router.push(route);
          }
        }
      } catch (e) {
        debugPrint('Lỗi xử lý click thông báo: $e');
      }
    }
  }

  Future<void> requestPermissions() async {
    // Yêu cầu quyền cho Android (phiên bản 13+)
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    
    // Yêu cầu quyền cho iOS
    final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'matchmaking_requests',
    String channelName = 'Yêu cầu ghép kèo',
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'match_reminders',
    String channelName = 'Nhắc lịch thi đấu',
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // Lên lịch
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    debugPrint('Đã lên lịch thông báo [$id] lúc: $scheduledTime');
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Đồng bộ nhắc nhở lịch thi đấu cho các đặt sân và vé sự kiện sắp diễn ra
  Future<void> syncMatchReminders(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // 1. Lấy thông tin lịch đặt sân (bookings)
      final bookingsResponse = await supabase
          .from('bookings')
          .select('*, booking_slots(*, courts(*, venues(*)))')
          .eq('user_id', userId)
          .eq('status', 'completed');
      
      final bookings = bookingsResponse as List? ?? [];
      for (var booking in bookings) {
        final slots = booking['booking_slots'] as List? ?? [];
        if (slots.isEmpty) continue;

        // Nhóm các slot theo ngày đặt sân
        final Map<String, List<int>> dateToSlots = {};
        final Map<String, String> dateToVenueName = {};
        for (var slot in slots) {
          final dateStr = slot['booking_date'] as String;
          final slotIndex = slot['slot_index'] as int;
          final venueName = slot['courts']?['venues']?['name'] as String? ?? 'Sân thể thao';
          
          dateToSlots.putIfAbsent(dateStr, () => []).add(slotIndex);
          dateToVenueName[dateStr] = venueName;
        }

        // Lập lịch thông báo nhắc nhở cho từng ngày đặt sân (lấy khung giờ bắt đầu sớm nhất)
        for (var entry in dateToSlots.entries) {
          final dateStr = entry.key;
          final indices = entry.value..sort();
          final minSlotIndex = indices.first;
          final venueName = dateToVenueName[dateStr] ?? 'Sân thể thao';

          // Cách tính giờ: Slot index 0 bắt đầu từ 06:00, mỗi slot tiếp theo cộng 30 phút
          final date = DateTime.parse(dateStr);
          final startMinutes = 6 * 60 + minSlotIndex * 30;
          final matchStart = date.add(Duration(minutes: startMinutes));
          
          final reminderTime = matchStart.subtract(const Duration(hours: 1));
          
          // Chỉ lập lịch nếu giờ trận đấu ở tương lai
          if (matchStart.isAfter(now)) {
            final notificationId = (booking['id'].toString() + dateStr).hashCode & 0x7FFFFFFF;
            
            // Format khung giờ hiển thị
            final endMinutes = 6 * 60 + (indices.last + 1) * 30;
            final startH = startMinutes ~/ 60;
            final startM = startMinutes % 60;
            final endH = endMinutes ~/ 60;
            final endM = endMinutes % 60;
            final timeRangeStr = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')} - ${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

            final title = 'Sắp đến giờ thi đấu! 🏸';
            final body = 'Trận đấu của bạn tại $venueName bắt đầu lúc $timeRangeStr ngày $dateStr. Hãy chuẩn bị ra sân nhé!';
            
            if (reminderTime.isAfter(now)) {
              await scheduleNotification(
                id: notificationId,
                title: title,
                body: body,
                scheduledTime: reminderTime,
                payload: jsonEncode({'route': '/BookedCourtPage'}),
              );
            } else {
              // Nếu trận đấu còn ít hơn 1 tiếng nữa nhưng vẫn ở tương lai, hiển thị thông báo sau 5 giây
              await scheduleNotification(
                id: notificationId,
                title: title,
                body: '$body (Trận đấu bắt đầu trong ít hơn 1 giờ nữa!)',
                scheduledTime: now.add(const Duration(seconds: 5)),
                payload: jsonEncode({'route': '/BookedCourtPage'}),
              );
            }
          }
        }
      }

      // 2. Lấy thông tin đặt vé sự kiện giao lưu (event_bookings)
      final eventsResponse = await supabase
          .from('event_bookings')
          .select('*, events(*, venues(*))')
          .eq('user_id', userId)
          .eq('status', 'completed');
      
      final eventBookings = eventsResponse as List? ?? [];
      for (var eb in eventBookings) {
        final event = eb['events'];
        if (event == null) continue;

        final eventDateStr = event['event_date'] as String;
        final startTimeStr = event['start_time'] as String; // e.g. "15:00"
        final venueName = event['venues']?['name'] as String? ?? 'Sân thể thao';
        final eventTitle = event['title'] as String;

        final matchStart = DateTime.parse('$eventDateStr $startTimeStr');
        final reminderTime = matchStart.subtract(const Duration(hours: 1));

        if (matchStart.isAfter(now)) {
          final notificationId = eb['id'].toString().hashCode & 0x7FFFFFFF;
          final notificationTitle = 'Sắp đến giờ sự kiện giao lưu! 🔥';
          final notificationBody = 'Sự kiện "$eventTitle" tại $venueName sẽ bắt đầu lúc $startTimeStr ngày $eventDateStr. Hãy chuẩn bị tham gia!';
          
          if (reminderTime.isAfter(now)) {
            await scheduleNotification(
              id: notificationId,
              title: notificationTitle,
              body: notificationBody,
              scheduledTime: reminderTime,
              payload: jsonEncode({'route': '/BookedCourtPage'}),
            );
          } else {
            await scheduleNotification(
              id: notificationId,
              title: notificationTitle,
              body: '$notificationBody (Sự kiện bắt đầu trong ít hơn 1 giờ nữa!)',
              scheduledTime: now.add(const Duration(seconds: 5)),
              payload: jsonEncode({'route': '/BookedCourtPage'}),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi đồng bộ nhắc lịch thi đấu: $e');
    }
  }

  // Đăng ký realtime nhận yêu cầu xin ghép kèo mới
  void subscribeToMatchmakingRequests(String userId) {
    if (_realtimeChannel != null) {
      unsubscribeFromMatchmakingRequests();
    }

    final supabase = Supabase.instance.client;
    
    _realtimeChannel = supabase
        .channel('public:matchmaking_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'matchmaking_requests',
          callback: (payload) async {
            try {
              final newRecord = payload.newRecord;
              final postId = newRecord['post_id'] as String;
              final requesterId = newRecord['user_id'] as String;

              // Kiểm tra xem user hiện tại có phải chủ kèo hay không
              final postResponse = await supabase
                  .from('matchmaking_posts')
                  .select('host_id')
                  .eq('id', postId)
                  .single();

              final hostId = postResponse['host_id'] as String?;
              if (hostId == userId) {
                // Lấy tên người gửi yêu cầu ghép
                final requesterResponse = await supabase
                    .from('profiles')
                    .select('name')
                    .eq('id', requesterId)
                    .single();

                final requesterName = requesterResponse['name'] as String? ?? 'Thành viên mới';

                // Hiển thị thông báo lập tức
                final notificationId = newRecord['id'].toString().hashCode & 0x7FFFFFFF;
                await showNotification(
                  id: notificationId,
                  title: 'Yêu cầu tham gia kèo mới! 🏸',
                  body: '$requesterName vừa gửi yêu cầu tham gia kèo của bạn. Hãy nhấn để duyệt ngay!',
                  payload: jsonEncode({
                    'route': '/ManageRequestsPage',
                    'postId': postId,
                  }),
                );
              }
            } catch (e) {
              debugPrint('Lỗi xử lý sự kiện realtime matchmaking_requests: $e');
            }
          },
        );

    _realtimeChannel!.subscribe();
    debugPrint('Đã đăng ký lắng nghe realtime matchmaking_requests cho user: $userId');
  }

  void unsubscribeFromMatchmakingRequests() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
      debugPrint('Đã hủy đăng ký lắng nghe realtime matchmaking_requests.');
    }
  }
}
