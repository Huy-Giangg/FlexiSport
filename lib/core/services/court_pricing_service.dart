import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    return CourtPricingModel(
      courtId: json['court_id']?.toString() ?? '',
      normalPrice: (json['normal_price'] as num?)?.toDouble() ?? 140000.0,
      peakPrice: (json['peak_price'] as num?)?.toDouble() ?? 182000.0,
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

  Future<CourtPricingModel> getPricing(String courtId, {double? fallbackBasePrice}) async {
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

  CourtPricingModel getPricingSync(String courtId, {double? fallbackBasePrice}) {
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

  Future<void> savePricing(CourtPricingModel config) async {
    await _ensureInitialized();
    _cache[config.courtId] = config;

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
  }) {
    final pricing = getPricingSync(courtId, fallbackBasePrice: fallbackBasePrice);

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
