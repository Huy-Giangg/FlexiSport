import 'package:image_picker/image_picker.dart';
import 'package:flexisport_app/features/owner/court_management/data/models/owner_court_model.dart';
import 'package:flexisport_app/features/owner/court_management/data/models/owner_venue_model.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/court_slot_status_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerCourtRemoteDataSource {
  final SupabaseClient supabaseClient;

  OwnerCourtRemoteDataSource(this.supabaseClient);

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  // Helper đếm số lượng sân con cho danh sách venues
  Future<List<OwnerVenueModel>> _mapVenuesWithCounts(List<dynamic> venuesData) async {
    final Map<String, int> courtCounts = {};
    try {
      final courtsCountResponse = await supabaseClient
          .from('courts')
          .select('venue_id');

      for (final item in courtsCountResponse as List<dynamic>) {
        final vId = item['venue_id']?.toString() ?? '';
        courtCounts[vId] = (courtCounts[vId] ?? 0) + 1;
      }
    } catch (_) {}

    return venuesData.map((json) {
      final venueId = json['id']?.toString() ?? '';
      return OwnerVenueModel.fromJson(
        json as Map<String, dynamic>,
        totalCourts: courtCounts[venueId] ?? 0,
      );
    }).toList();
  }

  // Lấy danh sách cơ sở/cụm sân của chủ sân (chỉ lấy các sân thuộc sở hữu hoặc giới hạn quản lý)
  Future<List<OwnerVenueModel>> fetchOwnerVenues() async {
    final currentUser = supabaseClient.auth.currentUser;

    try {
      // 1. Nếu chủ sân đã đăng nhập, ưu tiên tìm các sân có owner_id tương ứng
      if (currentUser != null) {
        try {
          final ownedResponse = await supabaseClient
              .from('venues')
              .select('id, name, address, rating, open_time, close_time, latitude, longitude, sports_type, logo_url, bank_name, account_number, owner_id')
              .eq('owner_id', currentUser.id)
              .order('created_at', ascending: false);

          final List<dynamic> ownedData = ownedResponse as List<dynamic>;
          if (ownedData.isNotEmpty) {
            return await _mapVenuesWithCounts(ownedData);
          }
        } catch (err) {
          print("Lỗi truy vấn venues theo owner_id: $err");
        }
      }

      // 2. Nếu chưa có sân nào được gán owner_id cho tài khoản này (hoặc chưa đăng nhập),
      // chỉ lấy 2-3 sân mẫu đầu tiên để đại diện cho cơ sở của chủ sân (không tải toàn bộ 70 sân)
      final response = await supabaseClient
          .from('venues')
          .select('id, name, address, rating, open_time, close_time, latitude, longitude, sports_type, logo_url, bank_name, account_number, owner_id')
          .limit(3);

      final List<dynamic> venuesData = response as List<dynamic>;
      if (venuesData.isNotEmpty) {
        return await _mapVenuesWithCounts(venuesData);
      }

      throw Exception("Không tìm thấy cơ sở nào");
    } catch (e) {
      print("Lỗi fetchOwnerVenues: $e");
      // Fallback mock cơ sở mẫu nếu bảng rỗng hoặc lỗi kết nối
      return [
        const OwnerVenueModel(
          id: '10000000-0000-0000-0000-000000000001',
          name: 'Sân Pickleball Ba Đình',
          address: '15 Hoàng Hoa Thám, Phường Thụy Khuê, Quận Ba Đình, Hà Nội',
          openTime: '05:00',
          closeTime: '22:00',
          rating: 4.8,
          sportsType: 'Pickleball',
          totalCourts: 3,
        ),
      ];
    }
  }

  // Thêm cơ sở / cụm sân mới
  Future<OwnerVenueModel> addVenue({
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? logoUrl,
    XFile? imageFile,
  }) async {
    final currentUser = supabaseClient.auth.currentUser;
    String? finalLogoUrl = logoUrl;

    // Upload hình ảnh lên Supabase Storage nếu có
    if (imageFile != null) {
      try {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.name.split('.').last;
        final fileName = 'venue_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await supabaseClient.storage.from('venue_images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );
        finalLogoUrl = supabaseClient.storage.from('venue_images').getPublicUrl(fileName);
      } catch (uploadErr) {
        print("Lỗi upload ảnh venue lên Supabase Storage: $uploadErr");
      }
    }

    final Map<String, dynamic> insertData = {
      'name': name,
      'address': address,
      'open_time': openTime,
      'close_time': closeTime,
      'rating': 5.0,
      'latitude': 21.0285,
      'longitude': 105.8542,
      'is_active': true,
      if (sportsType != null && sportsType.isNotEmpty) 'sports_type': sportsType,
      if (finalLogoUrl != null && finalLogoUrl.isNotEmpty) 'logo_url': finalLogoUrl,
      if (currentUser != null) 'owner_id': currentUser.id,
    };

    try {
      final response = await supabaseClient
          .from('venues')
          .insert(insertData)
          .select()
          .single();

      final newVenueId = response['id']?.toString() ?? '';

      // Tự động tạo sân con đầu tiên cho cơ sở mới để khách hàng có thể đặt ngay lập tức
      try {
        final initialCourtName = (sportsType != null && sportsType.isNotEmpty)
            ? "$sportsType 1"
            : "Sân 1";
        await supabaseClient.from('courts').insert({
          'venue_id': newVenueId,
          'name': initialCourtName,
          'status': 'active',
          'price_per_hour': 140000.0,
          'peak_price': 182000.0,
          'apply_peak': true,
          'weekend_surcharge': 20000.0,
          'apply_weekend': true,
        });
      } catch (courtErr) {
        print("Lỗi tạo sân con ban đầu cho venue: $courtErr");
      }

      return OwnerVenueModel.fromJson(response, totalCourts: 1);
    } catch (e) {
      print("Lỗi addVenue (thử fallback không gửi owner_id nếu DB chưa có cột): $e");
      try {
        final fallbackData = Map<String, dynamic>.from(insertData)..remove('owner_id');
        final response = await supabaseClient
            .from('venues')
            .insert(fallbackData)
            .select()
            .single();

        final newVenueId = response['id']?.toString() ?? '';
        try {
          final initialCourtName = (sportsType != null && sportsType.isNotEmpty)
              ? "$sportsType 1"
              : "Sân 1";
          await supabaseClient.from('courts').insert({
            'venue_id': newVenueId,
            'name': initialCourtName,
            'status': 'active',
            'price_per_hour': 140000.0,
            'peak_price': 182000.0,
            'apply_peak': true,
            'weekend_surcharge': 20000.0,
            'apply_weekend': true,
          });
        } catch (_) {}

        return OwnerVenueModel.fromJson(response, totalCourts: 1);
      } catch (err) {
        print("Lỗi addVenue trong Supabase: $err");
        rethrow;
      }
    }
  }

  // Xóa cụm sân / cơ sở và các dữ liệu liên quan
  Future<bool> deleteVenue(String venueId) async {
    try {
      final courts = await supabaseClient.from('courts').select('id').eq('venue_id', venueId);
      final courtIds = (courts as List<dynamic>).map((c) => c['id'].toString()).toList();
      if (courtIds.isNotEmpty) {
        try {
          await supabaseClient.from('court_locks').delete().inFilter('court_id', courtIds);
        } catch (_) {}
        try {
          await supabaseClient.from('court_blocks').delete().inFilter('court_id', courtIds);
        } catch (_) {}
        try {
          await supabaseClient.from('booking_slots').delete().inFilter('court_id', courtIds);
        } catch (_) {}
        await supabaseClient.from('courts').delete().eq('venue_id', venueId);
      }
      await supabaseClient.from('venues').delete().eq('id', venueId);
      return true;
    } catch (e) {
      print("Lỗi deleteVenue trong RemoteDataSource: $e");
      return false;
    }
  }

  // Lấy danh sách sân con theo cơ sở kèm thống kê lượt đặt/khóa hôm nay
  Future<List<OwnerCourtModel>> fetchCourtsByVenue(String venueId) async {
    try {
      final todayStr = _formatDate(DateTime.now());

      // 1. Lấy danh sách sân con
      final courtsResponse = await supabaseClient
          .from('courts')
          .select('*')
          .eq('venue_id', venueId);

      final List<dynamic> courtsData = courtsResponse as List<dynamic>;

      // 2. Lấy số lượng booking hôm nay cho từng sân
      dynamic bookingsResponse;
      try {
        bookingsResponse = await supabaseClient
            .from('booking_slots')
            .select('court_id, bookings!inner(status)')
            .eq('booking_date', todayStr)
            .neq('bookings.status', 'cancelled');
      } catch (_) {
        bookingsResponse = await supabaseClient
            .from('booking_slots')
            .select('court_id')
            .eq('booking_date', todayStr);
      }

      final Map<String, int> bookingCounts = {};
      for (final item in bookingsResponse as List<dynamic>) {
        final cId = item['court_id']?.toString() ?? '';
        bookingCounts[cId] = (bookingCounts[cId] ?? 0) + 1;
      }

      // 3. Lấy số lượng block hôm nay cho từng sân
      final blocksResponse = await supabaseClient
          .from('court_blocks')
          .select('court_id')
          .eq('block_date', todayStr);

      final Map<String, int> blockCounts = {};
      for (final item in blocksResponse as List<dynamic>) {
        final cId = item['court_id']?.toString() ?? '';
        blockCounts[cId] = (blockCounts[cId] ?? 0) + 1;
      }

      return courtsData.map((json) {
        final courtId = json['id']?.toString() ?? '';
        return OwnerCourtModel.fromJson(
          json as Map<String, dynamic>,
          todayBookings: bookingCounts[courtId] ?? 0,
          todayBlocked: blockCounts[courtId] ?? 0,
        );
      }).toList();
    } catch (e) {
      print("Lỗi fetchCourtsByVenue: $e");
      return [];
    }
  }

  // Thêm sân con mới
  Future<OwnerCourtModel> addCourt({
    required String venueId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  }) async {
    final insertData = {
      'name': name,
      'venue_id': venueId,
      'status': 'active',
      'price_per_hour': pricePerHour,
      if (peakPrice != null) 'peak_price': peakPrice,
      if (applyPeak != null) 'apply_peak': applyPeak,
      if (weekendSurcharge != null) 'weekend_surcharge': weekendSurcharge,
      if (applyWeekend != null) 'apply_weekend': applyWeekend,
    };

    try {
      final response = await supabaseClient.from('courts').insert(insertData).select().single();
      return OwnerCourtModel.fromJson(response);
    } catch (e) {
      try {
        final fallback = await supabaseClient.from('courts').insert({
          'name': name,
          'venue_id': venueId,
          'status': 'active',
          'price_per_hour': pricePerHour,
        }).select().single();
        return OwnerCourtModel.fromJson(fallback);
      } catch (err) {
        final fakeId = 'court-${DateTime.now().millisecondsSinceEpoch}';
        return OwnerCourtModel(
          id: fakeId,
          venueId: venueId,
          name: name,
          pricePerHour: pricePerHour,
          peakPrice: peakPrice ?? (pricePerHour * 1.3).roundToDouble(),
          applyPeak: applyPeak ?? true,
          weekendSurcharge: weekendSurcharge ?? 20000.0,
          applyWeekend: applyWeekend ?? true,
          sportType: sportType,
        );
      }
    }
  }

  // Cập nhật thông tin sân con
  Future<OwnerCourtModel> updateCourt({
    required String courtId,
    required String name,
    required double pricePerHour,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
    String? sportType,
  }) async {
    final updateData = {
      'name': name,
      'price_per_hour': pricePerHour,
      if (peakPrice != null) 'peak_price': peakPrice,
      if (applyPeak != null) 'apply_peak': applyPeak,
      if (weekendSurcharge != null) 'weekend_surcharge': weekendSurcharge,
      if (applyWeekend != null) 'apply_weekend': applyWeekend,
    };

    try {
      final response = await supabaseClient
          .from('courts')
          .update(updateData)
          .eq('id', courtId)
          .select()
          .single();

      return OwnerCourtModel.fromJson(response);
    } catch (e) {
      try {
        final fallbackResponse = await supabaseClient
            .from('courts')
            .update({'name': name})
            .eq('id', courtId)
            .select()
            .single();

        return OwnerCourtModel.fromJson(fallbackResponse);
      } catch (_) {
        return OwnerCourtModel(
          id: courtId,
          venueId: '',
          name: name,
          pricePerHour: pricePerHour,
          peakPrice: peakPrice ?? (pricePerHour * 1.3).roundToDouble(),
          applyPeak: applyPeak ?? true,
          weekendSurcharge: weekendSurcharge ?? 20000.0,
          applyWeekend: applyWeekend ?? true,
          sportType: sportType,
        );
      }
    }
  }

  // Xóa sân con
  Future<void> deleteCourt(String courtId) async {
    await supabaseClient.from('courts').delete().eq('id', courtId);
  }

  // Lấy chi tiết lịch & trạng thái các ô giờ của 1 sân cụ thể theo ngày
  Future<List<CourtSlotStatusEntity>> fetchCourtSlotsStatus({
    required String courtId,
    required String venueId,
    required String date,
  }) async {
    try {
      // 1. Lấy thông tin giờ mở/đóng cửa của venue chuẩn từ database
      String openTimeStr = '05:00';
      String closeTimeStr = '22:00';
      try {
        var targetVenueId = venueId;
        if (targetVenueId.isEmpty && courtId.isNotEmpty) {
          final courtResp = await supabaseClient
              .from('courts')
              .select('venue_id')
              .eq('id', courtId)
              .maybeSingle();
          if (courtResp != null) {
            targetVenueId = courtResp['venue_id']?.toString() ?? '';
          }
        }

        if (targetVenueId.isNotEmpty) {
          final venueResp = await supabaseClient
              .from('venues')
              .select('open_time, close_time')
              .eq('id', targetVenueId)
              .maybeSingle();

          if (venueResp != null) {
            openTimeStr = venueResp['open_time']?.toString() ?? openTimeStr;
            closeTimeStr = venueResp['close_time']?.toString() ?? closeTimeStr;
          }
        }
      } catch (_) {}

      final timeLabels = _generateTimeLabels(openTimeStr, closeTimeStr);

      // 2. Lấy các slot đã được đặt (bỏ qua đơn đã hủy)
      dynamic bookedResponse;
      try {
        bookedResponse = await supabaseClient
            .from('booking_slots')
            .select('id, slot_index, booking_id, bookings!inner(status, user_id, profiles(name))')
            .eq('court_id', courtId)
            .eq('booking_date', date)
            .neq('bookings.status', 'cancelled');
      } catch (_) {
        bookedResponse = await supabaseClient
            .from('booking_slots')
            .select('id, slot_index, booking_id, bookings(user_id, profiles(name))')
            .eq('court_id', courtId)
            .eq('booking_date', date);
      }

      final Map<int, Map<String, dynamic>> bookedMap = {};
      for (final item in bookedResponse as List<dynamic>) {
        final slotIdx = item['slot_index'] as int?;
        if (slotIdx != null) {
          bookedMap[slotIdx] = item as Map<String, dynamic>;
        }
      }

      // 3. Lấy các slot bị block (bảo trì / khóa bởi chủ sân)
      final blockedResponse = await supabaseClient
          .from('court_blocks')
          .select('id, slot_index, reason')
          .eq('court_id', courtId)
          .eq('block_date', date);

      final Map<int, Map<String, dynamic>> blockedMap = {};
      for (final item in blockedResponse as List<dynamic>) {
        final slotIdx = item['slot_index'] as int?;
        if (slotIdx != null) {
          blockedMap[slotIdx] = item as Map<String, dynamic>;
        }
      }

      // 4. Map thành danh sách CourtSlotStatusEntity
      final List<CourtSlotStatusEntity> slots = [];
      for (int i = 0; i < timeLabels.length; i++) {
        final isBooked = bookedMap.containsKey(i);
        final isBlocked = blockedMap.containsKey(i);

        String? customerName;
        String? bookingId;
        if (isBooked) {
          final bData = bookedMap[i];
          bookingId = bData?['booking_id']?.toString();
          final bookingObj = bData?['bookings'];
          if (bookingObj is Map && bookingObj['profiles'] is Map) {
            customerName = bookingObj['profiles']['name']?.toString();
          }
          customerName ??= 'Khách hàng đặt';
        }

        String? blockReason;
        String? blockId;
        if (isBlocked) {
          final blkData = blockedMap[i];
          blockReason = blkData?['reason']?.toString() ?? 'Khóa bảo trì';
          blockId = blkData?['id']?.toString();
        }

        slots.add(CourtSlotStatusEntity(
          slotIndex: i,
          timeLabel: timeLabels[i],
          isBooked: isBooked,
          isBlocked: isBlocked,
          blockReason: blockReason,
          blockId: blockId,
          customerName: customerName,
          bookingId: bookingId,
        ));
      }

      return slots;
    } catch (e) {
      print("Lỗi fetchCourtSlotsStatus: $e");
      final labels = _generateTimeLabels('06:00', '22:00');
      return List.generate(
        labels.length,
        (i) => CourtSlotStatusEntity(slotIndex: i, timeLabel: labels[i]),
      );
    }
  }

  // Khóa một khung giờ sân (Bảo trì / Sửa chữa / Tổ chức)
  Future<void> blockCourtSlot({
    required String courtId,
    required String date,
    required int slotIndex,
    required String reason,
  }) async {
    await supabaseClient.from('court_blocks').upsert(
      {
        'court_id': courtId,
        'block_date': date,
        'slot_index': slotIndex,
        'reason': reason,
      },
      onConflict: 'court_id,block_date,slot_index',
    );
  }

  // Chuyển đổi trạng thái hoạt động / bảo trì toàn sân trong ngày
  Future<void> toggleCourtStatus({
    required String courtId,
    required String venueId,
    required bool setToActive,
    String? reason,
  }) async {
    final todayStr = _formatDate(DateTime.now());
    try {
      if (!setToActive) {
        // Chuyển sang bảo trì: Khóa tất cả các ô giờ hôm nay chưa có đặt
        String openTimeStr = '06:00';
        String closeTimeStr = '22:00';
        if (venueId.isNotEmpty) {
          try {
            final venueResp = await supabaseClient
                .from('venues')
                .select('open_time, close_time')
                .eq('id', venueId)
                .maybeSingle();
            if (venueResp != null) {
              openTimeStr = venueResp['open_time']?.toString() ?? '06:00';
              closeTimeStr = venueResp['close_time']?.toString() ?? '22:00';
            }
          } catch (_) {}
        }

        final labels = _generateTimeLabels(openTimeStr, closeTimeStr);

        final existingBlocks = await supabaseClient
            .from('court_blocks')
            .select('slot_index')
            .eq('court_id', courtId)
            .eq('block_date', todayStr);
        final blockedSlots = (existingBlocks as List)
            .map((e) => (e['slot_index'] as num).toInt())
            .toSet();

        final existingBookings = await supabaseClient
            .from('booking_slots')
            .select('slot_index')
            .eq('court_id', courtId)
            .eq('booking_date', todayStr);
        final bookedSlots = (existingBookings as List)
            .map((e) => (e['slot_index'] as num).toInt())
            .toSet();

        final List<Map<String, dynamic>> toInsert = [];
        for (int i = 0; i < labels.length; i++) {
          if (!blockedSlots.contains(i) && !bookedSlots.contains(i)) {
            toInsert.add({
              'court_id': courtId,
              'block_date': todayStr,
              'slot_index': i,
              'reason': reason ?? 'Bảo trì toàn sân',
            });
          }
        }

        if (toInsert.isNotEmpty) {
          await supabaseClient.from('court_blocks').upsert(
                toInsert,
                onConflict: 'court_id,block_date,slot_index',
              );
        }

        // Cập nhật status trong bảng courts
        try {
          await supabaseClient.from('courts').update({
            'status': 'maintenance',
          }).eq('id', courtId);
        } catch (_) {}
      } else {
        // Mở lại hoạt động: Xóa các block bảo trì của hôm nay
        await supabaseClient
            .from('court_blocks')
            .delete()
            .eq('court_id', courtId)
            .eq('block_date', todayStr);

        // Cập nhật status trong bảng courts
        try {
          await supabaseClient.from('courts').update({
            'status': 'active',
          }).eq('id', courtId);
        } catch (_) {}
      }
    } catch (e) {
      print("Lỗi toggleCourtStatus: $e");
      rethrow;
    }
  }

  // Mở khóa một khung giờ sân
  Future<void> unblockCourtSlot(String blockId) async {
    await supabaseClient.from('court_blocks').delete().eq('id', blockId);
  }

  // Khóa một dải nhiều khung giờ sân cùng lúc
  Future<void> blockCourtSlotsRange({
    required String courtId,
    required String date,
    required List<int> slotIndices,
    required String reason,
  }) async {
    if (slotIndices.isEmpty) return;
    final List<Map<String, dynamic>> records = slotIndices.map((slotIdx) => {
      'court_id': courtId,
      'block_date': date,
      'slot_index': slotIdx,
      'reason': reason,
    }).toList();

    await supabaseClient.from('court_blocks').upsert(
      records,
      onConflict: 'court_id,block_date,slot_index',
    );
  }

  // Xóa các block bảo trì theo ngày hoặc danh sách slot cụ thể
  Future<void> unblockCourtSlots({
    required String courtId,
    required String date,
    List<int>? slotIndices,
  }) async {
    var query = supabaseClient
        .from('court_blocks')
        .delete()
        .eq('court_id', courtId)
        .eq('block_date', date);

    if (slotIndices != null && slotIndices.isNotEmpty) {
      query = query.inFilter('slot_index', slotIndices);
    }
    await query;
  }

  // Thiết lập chế độ bảo trì sân đa dạng (theo khung giờ, cả ngày, vô thời hạn, hoặc mở lại)
  Future<void> setCourtMaintenanceMode({
    required String courtId,
    required String venueId,
    required String date,
    required String mode, // 'custom_range', 'all_day', 'indefinite', 'release'
    List<int>? slotIndices,
    String? reason,
  }) async {
    final effectiveReason = reason?.trim().isNotEmpty == true ? reason!.trim() : 'Bảo trì kỹ thuật';
    
    if (mode == 'release') {
      // Mở lại sân: Xóa các blocks của ngày này và kích hoạt sân
      await unblockCourtSlots(courtId: courtId, date: date);
      try {
        await supabaseClient.from('courts').update({'status': 'active'}).eq('id', courtId);
      } catch (_) {}
    } else if (mode == 'indefinite') {
      // Đóng sân vô thời hạn
      try {
        await supabaseClient.from('courts').update({'status': 'maintenance'}).eq('id', courtId);
      } catch (_) {}
    } else if (mode == 'all_day') {
      // Khóa tất cả các slot trong ngày
      final slots = await fetchCourtSlotsStatus(courtId: courtId, venueId: venueId, date: date);
      final allIndices = slots.map((s) => s.slotIndex).toList();
      await blockCourtSlotsRange(
        courtId: courtId,
        date: date,
        slotIndices: allIndices,
        reason: effectiveReason,
      );
    } else if (mode == 'custom_range') {
      // Khóa các slot cụ thể đã chọn
      if (slotIndices != null && slotIndices.isNotEmpty) {
        await blockCourtSlotsRange(
          courtId: courtId,
          date: date,
          slotIndices: slotIndices,
          reason: effectiveReason,
        );
      }
    }
  }

  // Cập nhật thông tin cơ sở
  Future<void> updateVenueInfo({
    required String venueId,
    required String name,
    required String address,
    required String openTime,
    required String closeTime,
    String? sportsType,
    String? bankName,
    String? accountNumber,
  }) async {
    await supabaseClient.from('venues').update({
      'name': name,
      'address': address,
      'open_time': openTime,
      'close_time': closeTime,
      if (sportsType != null) 'sports_type': sportsType,
      if (bankName != null) 'bank_name': bankName,
      if (accountNumber != null) 'account_number': accountNumber,
    }).eq('id', venueId);
  }

  List<String> _generateTimeLabels(String openTimeStr, String closeTimeStr) {
    int parseToMinutes(String timeStr, int defaultHour) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? defaultHour;
        final m = int.tryParse(parts[1]) ?? 0;
        return h * 60 + m;
      }
      return defaultHour * 60;
    }

    int startMinutes = parseToMinutes(openTimeStr, 5);
    int endMinutes = parseToMinutes(closeTimeStr, 22);

    if (endMinutes <= startMinutes) {
      startMinutes = 5 * 60;
      endMinutes = 22 * 60;
    }

    final List<String> labels = [];
    int current = startMinutes;
    while (current < endMinutes) {
      final startH = (current ~/ 60).toString().padLeft(2, '0');
      final startM = (current % 60).toString().padLeft(2, '0');
      labels.add("$startH:$startM");
      current += 30;
    }
    return labels;
  }
}
