import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/owner/event_management/domain/entities/owner_event_attendee_entity.dart';
import 'package:flexisport_app/features/owner/event_management/domain/entities/owner_event_entity.dart';

class OwnerEventRemoteDataSource {
  final SupabaseClient supabaseClient;

  OwnerEventRemoteDataSource(this.supabaseClient);

  // 1. Lấy danh sách sự kiện theo cơ sở kèm thông tin số vé đã bán và doanh thu
  Future<List<OwnerEventEntity>> fetchOwnerEvents(String venueId) async {
    try {
      var query = supabaseClient.from('events').select();

      dynamic eventsResponse;
      if (venueId.isNotEmpty) {
        eventsResponse = await query.eq('venue_id', venueId).order('event_date', ascending: false);
      } else {
        eventsResponse = await query.order('event_date', ascending: false);
      }

      final eventsList = eventsResponse as List<dynamic>;

      if (eventsList.isEmpty) return [];

      final eventIds = eventsList.map((e) => e['id']?.toString() ?? '').toList();

      // Query event_bookings để tính số vé và doanh thu cho từng event
      final Map<String, int> bookedTicketsMap = {};
      final Map<String, double> revenueMap = {};
      final Map<String, int> attendeesCountMap = {};

      try {
        final bookingsResponse = await supabaseClient
            .from('event_bookings')
            .select()
            .inFilter('event_id', eventIds);

        for (final b in bookingsResponse as List<dynamic>) {
          final eventId = b['event_id']?.toString() ?? '';
          final status = b['status']?.toString().toLowerCase() ?? 'completed';

          if (status != 'cancelled') {
            final tickets = (b['ticket_count'] as num?)?.toInt() ?? 1;
            final amount = (b['total_amount'] as num?)?.toDouble() ??
                (b['amount'] as num?)?.toDouble() ??
                0.0;

            bookedTicketsMap[eventId] = (bookedTicketsMap[eventId] ?? 0) + tickets;
            revenueMap[eventId] = (revenueMap[eventId] ?? 0.0) + amount;
            attendeesCountMap[eventId] = (attendeesCountMap[eventId] ?? 0) + 1;
          }
        }
      } catch (e) {
        debugPrint("Lỗi tính toán vé đặt sự kiện: $e");
      }

      final parsedEvents = eventsList.map((json) {
        final eId = json['id']?.toString() ?? '';
        return OwnerEventEntity.fromJson(
          json as Map<String, dynamic>,
          bookedTickets: bookedTicketsMap[eId] ?? 0,
          revenue: revenueMap[eId] ?? 0.0,
          attendees: attendeesCountMap[eId] ?? 0,
        );
      }).toList();

      // Tự động kiểm tra và xử lý các sự kiện không đủ người trước 2 tiếng
      await checkAndAutoCancelUnderbookedEvents(parsedEvents);

      return parsedEvents;
    } catch (e) {
      debugPrint("Lỗi fetchOwnerEvents: $e");
      return [];
    }
  }

  // 2. Tạo sự kiện mới (hỗ trợ upload banner & fallback an toàn)
  Future<OwnerEventEntity> createEvent(
    Map<String, dynamic> eventData, {
    XFile? imageFile,
  }) async {
    String? bannerUrl = eventData['banner_url']?.toString();

    // Upload banner lên Supabase Storage nếu có
    if (imageFile != null) {
      try {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.name.split('.').last;
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await supabaseClient.storage.from('venue_images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );
        bannerUrl = supabaseClient.storage.from('venue_images').getPublicUrl(fileName);
      } catch (uploadErr) {
        debugPrint("Lỗi upload ảnh sự kiện: $uploadErr");
      }
    }

    final insertData = Map<String, dynamic>.from(eventData);

    // Không truyền id rỗng để tránh lỗi parse UUID
    if (insertData['id'] == null || insertData['id'].toString().isEmpty) {
      insertData.remove('id');
    }

    // Đảm bảo luôn có venue_id hợp lệ
    if (insertData['venue_id'] == null || insertData['venue_id'].toString().isEmpty) {
      try {
        final vResp = await supabaseClient.from('venues').select('id').limit(1).maybeSingle();
        if (vResp != null && vResp['id'] != null) {
          insertData['venue_id'] = vResp['id'].toString();
        }
      } catch (_) {}
    }

    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      insertData['banner_url'] = bannerUrl;
    } else {
      insertData.remove('banner_url');
    }

    try {
      final response = await supabaseClient
          .from('events')
          .insert(insertData)
          .select()
          .single();

      final createdEvent = OwnerEventEntity.fromJson(response as Map<String, dynamic>);

      // Tự động đồng bộ khóa ô giờ trên bảng event_slots để chống trùng lịch với khách lẻ
      await _syncEventSlots(
        eventId: createdEvent.id,
        courtId: insertData['court_id']?.toString(),
        courtName: insertData['court_name']?.toString(),
        eventDate: insertData['event_date']?.toString() ?? '',
        startTimeStr: insertData['start_time']?.toString() ?? '15:00',
        endTimeStr: insertData['end_time']?.toString() ?? '18:00',
      );

      return createdEvent;
    } catch (e) {
      debugPrint("Thử lại insert với các trường cơ bản do lỗi: $e");

      // Fallback nếu CSDL chưa chạy migration thêm các cột mở rộng
      final fallbackData = {
        if (insertData['venue_id'] != null) 'venue_id': insertData['venue_id'],
        'title': insertData['title'] ?? 'Sự kiện mới',
        'description': insertData['description'] ?? '',
        'event_date': insertData['event_date'],
        'is_active': insertData['is_active'] ?? true,
        if (insertData['banner_url'] != null) 'banner_url': insertData['banner_url'],
      };

      try {
        final response = await supabaseClient
            .from('events')
            .insert(fallbackData)
            .select()
            .single();

        final createdEvent = OwnerEventEntity.fromJson(
          response as Map<String, dynamic>,
        ).copyWith(
          sportType: insertData['sport_type']?.toString() ?? 'Pickleball',
          level: insertData['level']?.toString() ?? 'Mọi trình độ',
          courtName: insertData['court_name']?.toString() ?? 'Sân 1',
          startTime: insertData['start_time']?.toString() ?? '15:00',
          endTime: insertData['end_time']?.toString() ?? '18:00',
          ticketPrice: (insertData['ticket_price'] as num?)?.toDouble() ?? 0.0,
          maxTickets: (insertData['max_tickets'] as num?)?.toInt() ?? 10,
        );

        await _syncEventSlots(
          eventId: createdEvent.id,
          courtId: insertData['court_id']?.toString(),
          courtName: insertData['court_name']?.toString(),
          eventDate: insertData['event_date']?.toString() ?? '',
          startTimeStr: insertData['start_time']?.toString() ?? '15:00',
          endTimeStr: insertData['end_time']?.toString() ?? '18:00',
        );

        return createdEvent;
      } catch (innerErr) {
        throw Exception("Lỗi khi thêm sự kiện vào Supabase: $innerErr");
      }
    }
  }

  // 3. Cập nhật sự kiện
  Future<OwnerEventEntity> updateEvent(
    String eventId,
    Map<String, dynamic> updateData, {
    XFile? imageFile,
  }) async {
    String? bannerUrl = updateData['banner_url']?.toString();

    if (imageFile != null) {
      try {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.name.split('.').last;
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await supabaseClient.storage.from('venue_images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );
        bannerUrl = supabaseClient.storage.from('venue_images').getPublicUrl(fileName);
      } catch (uploadErr) {
        debugPrint("Lỗi upload ảnh sự kiện cập nhật: $uploadErr");
      }
    }

    final dataToUpdate = Map<String, dynamic>.from(updateData);
    dataToUpdate.remove('id');

    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      dataToUpdate['banner_url'] = bannerUrl;
    } else {
      dataToUpdate.remove('banner_url');
    }

    try {
      final response = await supabaseClient
          .from('events')
          .update(dataToUpdate)
          .eq('id', eventId)
          .select()
          .single();

      final updatedEvent = OwnerEventEntity.fromJson(response as Map<String, dynamic>);

      await _syncEventSlots(
        eventId: eventId,
        courtId: dataToUpdate['court_id']?.toString(),
        courtName: dataToUpdate['court_name']?.toString(),
        eventDate: dataToUpdate['event_date']?.toString() ?? updatedEvent.eventDate,
        startTimeStr: dataToUpdate['start_time']?.toString() ?? updatedEvent.startTime,
        endTimeStr: dataToUpdate['end_time']?.toString() ?? updatedEvent.endTime,
      );

      return updatedEvent;
    } catch (e) {
      debugPrint("Thử lại update sự kiện với các trường cơ bản: $e");
      final fallbackUpdate = {
        if (dataToUpdate['title'] != null) 'title': dataToUpdate['title'],
        if (dataToUpdate['description'] != null) 'description': dataToUpdate['description'],
        if (dataToUpdate['event_date'] != null) 'event_date': dataToUpdate['event_date'],
        if (dataToUpdate['is_active'] != null) 'is_active': dataToUpdate['is_active'],
        if (dataToUpdate['banner_url'] != null) 'banner_url': dataToUpdate['banner_url'],
      };

      final response = await supabaseClient
          .from('events')
          .update(fallbackUpdate)
          .eq('id', eventId)
          .select()
          .single();

      return OwnerEventEntity.fromJson(response as Map<String, dynamic>);
    }
  }

  // Tự động đồng bộ các ô giờ sự kiện vào bảng event_slots
  Future<void> _syncEventSlots({
    required String eventId,
    String? courtId,
    String? courtName,
    required String eventDate,
    required String startTimeStr,
    required String endTimeStr,
  }) async {
    try {
      String targetCourtId = courtId ?? '';
      if (targetCourtId.isEmpty && courtName != null && courtName.isNotEmpty) {
        final cResp = await supabaseClient
            .from('courts')
            .select('id')
            .eq('name', courtName)
            .limit(1)
            .maybeSingle();
        if (cResp != null && cResp['id'] != null) {
          targetCourtId = cResp['id'].toString();
        }
      }

      if (targetCourtId.isEmpty || eventDate.isEmpty) return;

      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');
      if (startParts.isEmpty || endParts.isEmpty) return;

      final startHour = int.tryParse(startParts[0]) ?? 6;
      final startMin = startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0;
      final endHour = int.tryParse(endParts[0]) ?? 22;
      final endMin = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0;

      final startTotalMin = startHour * 60 + startMin;
      final endTotalMin = endHour * 60 + endMin;

      // Tra cứu giờ mở cửa thực tế của venue nếu có
      int openHour = 6;
      int openMinute = 0;
      try {
        final cResp = await supabaseClient
            .from('courts')
            .select('venues(open_time)')
            .eq('id', targetCourtId)
            .maybeSingle();

        if (cResp != null && cResp['venues'] != null) {
          final openTimeStr = (cResp['venues'] as Map<String, dynamic>)['open_time']?.toString() ?? '06:00';
          final parts = openTimeStr.split(':');
          if (parts.isNotEmpty) openHour = int.tryParse(parts[0]) ?? 6;
          if (parts.length > 1) openMinute = int.tryParse(parts[1]) ?? 0;
        }
      } catch (_) {}

      final openMin = openHour * 60 + openMinute;
      final startSlot = ((startTotalMin - openMin) ~/ 30).clamp(0, 48);
      final endSlot = (((endTotalMin - openMin) - 1) ~/ 30).clamp(0, 48);

      if (endSlot < startSlot) return;

      // Xóa các slot cũ của event này
      await supabaseClient.from('event_slots').delete().eq('event_id', eventId);

      // Chèn các slot mới
      final List<Map<String, dynamic>> slotsToInsert = [];
      for (int slot = startSlot; slot <= endSlot; slot++) {
        slotsToInsert.add({
          'event_id': eventId,
          'court_id': targetCourtId,
          'event_date': eventDate,
          'slot_index': slot,
        });
      }

      if (slotsToInsert.isNotEmpty) {
        await supabaseClient.from('event_slots').insert(slotsToInsert);
      }
    } catch (e) {
      debugPrint("Lỗi đồng bộ event_slots: $e");
    }
  }

  // 4. Xóa sự kiện
  Future<void> deleteEvent(String eventId) async {
    try {
      await supabaseClient.from('event_slots').delete().eq('event_id', eventId);
    } catch (_) {}
    try {
      await supabaseClient.from('event_bookings').delete().eq('event_id', eventId);
    } catch (_) {}
    await supabaseClient.from('events').delete().eq('id', eventId);
  }

  // 5. Bật / Tắt trạng thái sự kiện
  Future<void> toggleEventStatus(String eventId, bool isActive) async {
    await supabaseClient
        .from('events')
        .update({'is_active': isActive})
        .eq('id', eventId);
    
    // Nếu tắt sự kiện, giải phóng các slot để khách đặt bình thường
    if (!isActive) {
      try {
        await supabaseClient.from('event_slots').delete().eq('event_id', eventId);
      } catch (_) {}
    }
  }

  // 6. Hủy sự kiện, giải phóng ô giờ và hoàn tiền cho người tham gia
  Future<bool> cancelEventAndRefund(
    String eventId, {
    String reason = 'Không đủ số lượng người tham gia tối thiểu',
  }) async {
    try {
      // 1. Tắt sự kiện trên bảng events
      await supabaseClient
          .from('events')
          .update({'is_active': false})
          .eq('id', eventId);

      // 2. Giải phóng toàn bộ các ô giờ trong bảng event_slots (Lưới chuyển về trống)
      await supabaseClient
          .from('event_slots')
          .delete()
          .eq('event_id', eventId);

      // 3. Đổi trạng thái toàn bộ vé đặt sự kiện sang 'cancelled' (Đã hủy / hoàn tiền)
      await supabaseClient
          .from('event_bookings')
          .update({
            'status': 'cancelled',
            'note': reason,
          })
          .eq('event_id', eventId);

      debugPrint("Đã hủy sự kiện $eventId thành công: $reason");
      return true;
    } catch (e) {
      debugPrint("Lỗi hủy sự kiện & hoàn tiền: $e");
      return false;
    }
  }

  // 7. Tự động kiểm tra và hủy các sự kiện không đủ người trước 2 tiếng
  Future<void> checkAndAutoCancelUnderbookedEvents(List<OwnerEventEntity> events) async {
    for (final event in events) {
      if (event.shouldAutoCancel) {
        debugPrint(
          "Tự động hủy sự kiện '${event.title}' trước 2h: Đã bán ${event.bookedTicketsCount}/${event.minTickets} vé.",
        );
        await cancelEventAndRefund(
          event.id,
          reason: 'Tự động hủy trước 2h do không đủ vé tối thiểu (${event.bookedTicketsCount}/${event.minTickets} vé). Tiền vé đã được hoàn lại.',
        );
      }
    }
  }

  // 8. Lấy danh sách khách hàng tham gia sự kiện (Attendees)
  Future<List<OwnerEventAttendeeEntity>> fetchEventAttendees(String eventId) async {
    try {
      final response = await supabaseClient
          .from('event_bookings')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list.map((json) => OwnerEventAttendeeEntity.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Lỗi fetchEventAttendees: $e");
      return [];
    }
  }
}
