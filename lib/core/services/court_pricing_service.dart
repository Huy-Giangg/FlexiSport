import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flexisport_app/features/customer/booking/domain/entities/court_entity.dart';

class CourtPricingModel {
  final String courtId;
  final double normalPrice;
  final double peakPrice;
  final bool applyPeak;
  final double weekendSurcharge;
  final bool applyWeekend;

  const CourtPricingModel({
    required this.courtId,
    required this.normalPrice,
    required this.peakPrice,
    this.applyPeak = true,
    this.weekendSurcharge = 20000.0,
    this.applyWeekend = true,
  });

  Map<String, dynamic> toJson() => {
        'court_id': courtId,
        'normal_price': normalPrice,
        'peak_price': peakPrice,
        'apply_peak': applyPeak,
        'weekend_surcharge': weekendSurcharge,
        'apply_weekend': applyWeekend,
      };

  factory CourtPricingModel.fromJson(Map<String, dynamic> json) {
    final normal = (json['normal_price'] as num?)?.toDouble() ??
        (json['price_per_hour'] as num?)?.toDouble() ??
        140000.0;
    final peak = (json['peak_price'] as num?)?.toDouble() ?? (normal * 1.3).roundToDouble();
    return CourtPricingModel(
      courtId: json['court_id']?.toString() ?? json['id']?.toString() ?? '',
      normalPrice: normal,
      peakPrice: peak,
      applyPeak: json['apply_peak'] == true || json['apply_peak'] == null,
      weekendSurcharge: (json['weekend_surcharge'] as num?)?.toDouble() ?? 20000.0,
      applyWeekend: json['apply_weekend'] == true || json['apply_weekend'] == null,
    );
  }

  CourtPricingModel copyWith({
    String? courtId,
    double? normalPrice,
    double? peakPrice,
    bool? applyPeak,
    double? weekendSurcharge,
    bool? applyWeekend,
  }) {
    return CourtPricingModel(
      courtId: courtId ?? this.courtId,
      normalPrice: normalPrice ?? this.normalPrice,
      peakPrice: peakPrice ?? this.peakPrice,
      applyPeak: applyPeak ?? this.applyPeak,
      weekendSurcharge: weekendSurcharge ?? this.weekendSurcharge,
      applyWeekend: applyWeekend ?? this.applyWeekend,
    );
  }
}

class CourtPricingService {
  CourtPricingService._();
  static final CourtPricingService instance = CourtPricingService._();

  static const String _storageKey = 'court_pricing_configs_map';
  final Map<String, CourtPricingModel> _cache = {};
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            _cache[key] = CourtPricingModel.fromJson(val);
          }
        });
      }
    } catch (_) {}
    _initialized = true;
  }

  /// Đăng ký biểu giá từ CourtEntity/CourtModel đã nạp từ server
  void registerCourtPricing({
    required String courtId,
    required double normalPrice,
    required double peakPrice,
    bool applyPeak = true,
    double weekendSurcharge = 20000.0,
    bool applyWeekend = true,
  }) {
    _cache[courtId] = CourtPricingModel(
      courtId: courtId,
      normalPrice: normalPrice,
      peakPrice: peakPrice,
      applyPeak: applyPeak,
      weekendSurcharge: weekendSurcharge,
      applyWeekend: applyWeekend,
    );
  }

  /// Lấy cấu hình biểu giá từ Supabase nếu chưa có trong cache
  Future<CourtPricingModel> getPricing(String courtId, {double? fallbackBasePrice, CourtEntity? court}) async {
    if (court != null) {
      registerCourtPricing(
        courtId: court.id,
        normalPrice: court.pricePerHour,
        peakPrice: court.peakPrice,
        applyPeak: court.applyPeak,
        weekendSurcharge: court.weekendSurcharge,
        applyWeekend: court.applyWeekend,
      );
      return _cache[court.id]!;
    }

    if (_cache.containsKey(courtId)) {
      return _cache[courtId]!;
    }

    // Thử truy vấn từ Supabase
    try {
      final response = await Supabase.instance.client
          .from('courts')
          .select('id, price_per_hour, peak_price, apply_peak, weekend_surcharge, apply_weekend')
          .eq('id', courtId)
          .maybeSingle();

      if (response != null) {
        final model = CourtPricingModel.fromJson(response);
        _cache[courtId] = model;
        return model;
      }
    } catch (_) {}

    await _ensureInitialized();
    if (_cache.containsKey(courtId)) {
      return _cache[courtId]!;
    }

    final base = fallbackBasePrice ?? 140000.0;
    final peak = (base * 1.3).roundToDouble();

    final config = CourtPricingModel(
      courtId: courtId,
      normalPrice: base,
      peakPrice: peak,
      applyPeak: true,
      weekendSurcharge: 20000.0,
      applyWeekend: true,
    );
    _cache[courtId] = config;
    return config;
  }

  CourtPricingModel getPricingSync(String courtId, {double? fallbackBasePrice, CourtEntity? court}) {
    if (court != null) {
      registerCourtPricing(
        courtId: court.id,
        normalPrice: court.pricePerHour,
        peakPrice: court.peakPrice,
        applyPeak: court.applyPeak,
        weekendSurcharge: court.weekendSurcharge,
        applyWeekend: court.applyWeekend,
      );
      return _cache[court.id]!;
    }

    if (_cache.containsKey(courtId)) {
      return _cache[courtId]!;
    }

    final base = fallbackBasePrice ?? 140000.0;
    final peak = (base * 1.3).roundToDouble();
    return CourtPricingModel(
      courtId: courtId,
      normalPrice: base,
      peakPrice: peak,
      applyPeak: true,
      weekendSurcharge: 20000.0,
      applyWeekend: true,
    );
  }

  /// Lưu cấu hình giá: Cập nhật trực tiếp lên Supabase & đồng bộ in-memory
  Future<void> savePricing(CourtPricingModel config) async {
    _cache[config.courtId] = config;

    // 1. Cập nhật trực tiếp lên Supabase để mọi khách hàng đều thấy ngay lập tức
    try {
      await Supabase.instance.client.from('courts').update({
        'price_per_hour': config.normalPrice,
        'peak_price': config.peakPrice,
        'apply_peak': config.applyPeak,
        'weekend_surcharge': config.weekendSurcharge,
        'apply_weekend': config.applyWeekend,
      }).eq('id', config.courtId);
    } catch (e) {
      debugPrint("Lỗi cập nhật giá sân lên Supabase: $e");
    }

    // 2. Lưu bộ nhớ tạm SharedPreferences làm fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = _cache.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_storageKey, jsonEncode(mapToSave));
    } catch (_) {}
  }

  /// Tính giá thực tế của 1 ca 30 phút dựa trên:
  /// - Khung giờ thường (06:00 - 16:00): normalPrice
  /// - Giờ cao điểm (16:00 - 22:00): peakPrice (nếu applyPeak = true)
  /// - Cuối tuần (T7, CN): cộng thêm weekendSurcharge (nếu applyWeekend = true)
  double calculateSlotPrice({
    required String courtId,
    required int slotIndex,
    required DateTime date,
    String? openTime,
    double? fallbackBasePrice,
    CourtEntity? court,
  }) {
    final pricing = getPricingSync(courtId, fallbackBasePrice: fallbackBasePrice, court: court);

    // Tính phút bắt đầu của ca dựa theo giờ mở cửa của cơ sở
    int baseMinutes = 6 * 60;
    if (openTime != null && openTime.trim().isNotEmpty) {
      final parts = openTime.trim().split(':');
      if (parts.isNotEmpty) {
        final h = int.tryParse(parts[0]) ?? 6;
        final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        baseMinutes = h * 60 + m;
      }
    }
    final slotStartMinutes = baseMinutes + slotIndex * 30;

    // Giờ cao điểm: 16:00 (960p) đến 22:00 (1320p)
    final isPeakTime = slotStartMinutes >= (16 * 60) && slotStartMinutes < (22 * 60);

    double hourPrice = pricing.normalPrice;
    if (isPeakTime && pricing.applyPeak) {
      hourPrice = pricing.peakPrice;
    }

    // Cuối tuần (Thứ 7 hoặc Chủ Nhật)
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    if (isWeekend && pricing.applyWeekend) {
      hourPrice += pricing.weekendSurcharge;
    }

    // Mỗi slot là 30 phút = 0.5 giờ
    return hourPrice * 0.5;
  }
}
