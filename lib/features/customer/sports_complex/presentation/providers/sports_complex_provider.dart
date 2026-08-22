import 'dart:async';
import 'dart:convert';
import 'package:flexisport_app/core/utils/location_helper.dart';
import 'package:flexisport_app/features/customer/sports_complex/data/models/sports_complex_model.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/venue_review_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/usecases/get_venue_reviews_usecase.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/usecases/submit_venue_review_usecase.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/venue_images_entity.dart';
import '../../domain/usecases/get_sports_complex_images_usecase.dart';
import '../../domain/usecases/get_sports_complex_usecase.dart';

class SportsComplexProvider extends ChangeNotifier {
  final GetSportsComplexUsecase getStadiumsUseCase;
  final GetSportsComplexImagesUsecase getStadiumImagesUseCase;
  final GetVenueReviewsUsecase getVenueReviewsUseCase;
  final SubmitVenueReviewUsecase submitVenueReviewUseCase;

  SportsComplexProvider(
    this.getStadiumsUseCase,
    this.getStadiumImagesUseCase,
    this.getVenueReviewsUseCase,
    this.submitVenueReviewUseCase,
  ) {
    loadFavorites();
  }

  List<SportsComplexEntity> stadiums = [];
  List<String> _favoriteStadiumIds = [];
  List<String> get favoriteStadiumIds => _favoriteStadiumIds;

  bool _showFavoritesOnly = false;
  bool get showFavoritesOnly => _showFavoritesOnly;

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favoriteStadiumIds = prefs.getStringList('favorite_stadium_ids') ?? [];
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String stadiumId) async {
    if (_favoriteStadiumIds.contains(stadiumId)) {
      _favoriteStadiumIds.remove(stadiumId);
    } else {
      _favoriteStadiumIds.add(stadiumId);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_stadium_ids', _favoriteStadiumIds);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  void toggleShowFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }
  List<VenueImageEntity> currentStadiumImages = [];

  bool isLoading = false;
  bool isImagesLoading = false;
  String? errorMessage;
  String? imagesErrorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedSport;
  String? get selectedSport => _selectedSport;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectSport(String? sport) {
    if (_selectedSport == sport) {
      _selectedSport = null; // Toggle off
    } else {
      _selectedSport = sport;
    }
    notifyListeners();
  }

  bool _stadiumMatchesSport(SportsComplexEntity stadium, String sport) {
    final name = stadium.name.toLowerCase();
    final lowercaseSport = sport.toLowerCase();
    
    if (name.contains(lowercaseSport)) return true;
    
    // Custom mappings for English terms or alternate names
    if (lowercaseSport == 'cầu lông' && name.contains('badminton')) return true;
    if (lowercaseSport == 'bóng đá' && (name.contains('football') || name.contains('soccer') || name.contains('sân cỏ'))) return true;
    if (lowercaseSport.contains('chuyền') && (name.contains('chuyền') || name.contains('volleyball'))) return true;
    if (lowercaseSport == 'bóng rổ' && name.contains('basketball')) return true;
    if (lowercaseSport == 'tennis' && name.contains('quần vợt')) return true;
    
    return false;
  }

  List<SportsComplexEntity> get filteredStadiums {
    List<SportsComplexEntity> list = stadiums;
    
    if (_showFavoritesOnly) {
      list = list.where((stadium) => _favoriteStadiumIds.contains(stadium.id)).toList();
    }
    
    if (_selectedSport != null) {
      list = list.where((stadium) => _stadiumMatchesSport(stadium, _selectedSport!)).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final lowercaseQuery = _searchQuery.toLowerCase();
      list = list.where((stadium) {
        final matchesName = stadium.name.toLowerCase().contains(lowercaseQuery);
        final matchesAddress = stadium.address.toLowerCase().contains(lowercaseQuery);
        return matchesName || matchesAddress;
      }).toList();
    }

    // Sắp xếp các sân theo thứ tự gần nhất lên đầu
    list = List.from(list);
    list.sort((a, b) {
      final distA = LocationHelper.calculateDistanceFromDefault(a.latitude, a.longitude);
      final distB = LocationHelper.calculateDistanceFromDefault(b.latitude, b.longitude);
      if (distA.isNaN && distB.isNaN) return 0;
      if (distA.isNaN) return 1;
      if (distB.isNaN) return -1;
      return distA.compareTo(distB);
    });
    
    return list;
  }

  static const String _cachedStadiumsKey = 'cached_stadiums';

  Future<void> loadCachedStadiums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cachedStadiumsKey);
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        stadiums = decoded
            .map((json) => SportsComplexModel.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cached stadiums: $e');
    }
  }

  Future<void> _saveStadiumsToCache(List<SportsComplexEntity> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = jsonEncode(
        data.map((item) {
          if (item is SportsComplexModel) {
            return item.toJson();
          } else {
            return {
              'id': item.id,
              'name': item.name,
              'address': item.address,
              'logo_url': item.logoUrl,
              'rating': item.rating,
              'open_time': item.open_time,
              'close_time': item.close_time,
            };
          }
        }).toList(),
      );
      await prefs.setString(_cachedStadiumsKey, encodedData);
    } catch (e) {
      print('Error caching stadiums: $e');
    }
  }

  Future<void> fetchStadiums() async {
    // Chỉ hiển thị loading chính khi chưa có dữ liệu trong cache
    if (stadiums.isEmpty) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    // Đọc cache trước nếu danh sách đang trống
    if (stadiums.isEmpty) {
      await loadCachedStadiums();
    }

    try {
      // Đặt timeout 20 giây cho truy vấn Supabase để hỗ trợ mạng rất yếu
      final fetchedStadiums = await getStadiumsUseCase.call().timeout(const Duration(seconds: 20));
      stadiums = fetchedStadiums;
      errorMessage = null;
      await _saveStadiumsToCache(fetchedStadiums);
    } catch (e) {
      print('Error fetching stadiums from Supabase: $e');
      // Nếu danh sách vẫn trống (không load được cả cache và API), hiển thị thông báo lỗi
      if (stadiums.isEmpty) {
        if (e is TimeoutException) {
          errorMessage = "Kết nối mạng quá yếu hoặc hết hạn kết nối. Vui lòng thử lại!";
        } else {
          errorMessage = "Không thể tải danh sách sân. Vui lòng kiểm tra lại kết nối!";
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStadiumImages(String stadiumId) async {
    isImagesLoading = true;
    imagesErrorMessage = null;
    notifyListeners();

    try {
      currentStadiumImages = await getStadiumImagesUseCase.call(stadiumId);
    } catch (e) {
      imagesErrorMessage = e.toString();
      print('Error fetching stadium images: $e');
    } finally {
      isImagesLoading = false;
      notifyListeners();
    }
  }

  // Reviews logic
  List<VenueReviewEntity> currentVenueReviews = [];
  bool isReviewsLoading = false;

  List<Map<String, dynamic>> userBookingsForVenue = [];
  bool isCheckBookingsLoading = false;

  Future<void> fetchVenueReviews(String venueId) async {
    isReviewsLoading = true;
    notifyListeners();
    try {
      currentVenueReviews = await getVenueReviewsUseCase.call(venueId);
    } catch (e) {
      print("Error fetching venue reviews: $e");
    } finally {
      isReviewsLoading = false;
      notifyListeners();
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return const TimeOfDay(hour: 6, minute: 0);
  }

  DateTime? _getBookingEndDateTime(List slots, String openTime, String closeTime) {
    if (slots.isEmpty) return null;
    
    final String dateStr = slots.first['booking_date']?.toString() ?? '';
    if (dateStr.isEmpty) return null;
    
    final dateParts = dateStr.split('-');
    if (dateParts.length != 3) return null;
    final year = int.tryParse(dateParts[0]) ?? 0;
    final month = int.tryParse(dateParts[1]) ?? 0;
    final day = int.tryParse(dateParts[2]) ?? 0;
    
    final open = _parseTime(openTime);
    final close = _parseTime(closeTime);
    int startMinutes = open.hour * 60 + open.minute;
    int endMinutes = close.hour * 60 + close.minute;
    if (endMinutes <= startMinutes) {
      startMinutes = 6 * 60;
      endMinutes = 22 * 60;
    }
    
    final List<int> startMinutesList = [];
    int current = startMinutes;
    while (current < endMinutes) {
      startMinutesList.add(current);
      current += 30;
    }
    
    final List<int> indices = slots.map((s) => s['slot_index'] as int? ?? 0).toList();
    if (indices.isEmpty) return null;
    indices.sort();
    final maxIdx = indices.last;
    
    if (maxIdx < startMinutesList.length) {
      final startMin = startMinutesList[maxIdx];
      final endMin = startMin + 30;
      final endHour = endMin ~/ 60;
      final endMinute = endMin % 60;
      
      return DateTime(year, month, day, endHour, endMinute);
    }
    return null;
  }

  bool _isBookingPassed(List slots, String openTime, String closeTime) {
    final endDateTime = _getBookingEndDateTime(slots, openTime, closeTime);
    if (endDateTime == null) return false;
    return DateTime.now().isAfter(endDateTime);
  }

  Future<void> fetchUserBookingsEligibility(String venueId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      userBookingsForVenue = [];
      notifyListeners();
      return;
    }

    isCheckBookingsLoading = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch bookings for user
      final bookingsResponse = await supabase
          .from('bookings')
          .select('*, booking_slots(*, courts(*, venues(*)))')
          .eq('user_id', user.id);

      // 2. Filter completed and passed bookings for the venue
      final List<Map<String, dynamic>> filteredBookings = [];
      for (var booking in bookingsResponse) {
        final slots = booking['booking_slots'] as List? ?? [];
        final status = booking['status']?.toString() ?? 'pending';
        
        bool belongsToVenue = false;
        String openTime = '06:00';
        String closeTime = '22:00';
        
        for (var slot in slots) {
          final court = slot['courts'];
          if (court != null && court['venue_id'] == venueId) {
            belongsToVenue = true;
            final venue = court['venues'];
            if (venue != null) {
              openTime = venue['open_time']?.toString() ?? '06:00';
              closeTime = venue['close_time']?.toString() ?? '22:00';
            }
            break;
          }
        }

        final hasPassed = status != 'cancelled' && _isBookingPassed(slots, openTime, closeTime);

        if (belongsToVenue && status == 'completed' && hasPassed) {
          filteredBookings.add(Map<String, dynamic>.from(booking));
        }
      }

      // 3. Check which booking_ids have been reviewed
      final reviewedResponse = await supabase
          .from('venue_reviews')
          .select('booking_id')
          .eq('user_id', user.id)
          .eq('venue_id', venueId);

      final reviewedIds = reviewedResponse
          .where((r) => r['booking_id'] != null)
          .map((r) => r['booking_id'].toString())
          .toSet();

      // 4. Mark reviewed status
      for (var booking in filteredBookings) {
        booking['isReviewed'] = reviewedIds.contains(booking['id'].toString());
      }

      userBookingsForVenue = filteredBookings;
    } catch (e) {
      print("Error checking eligibility: $e");
      userBookingsForVenue = [];
    } finally {
      isCheckBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitReview({
    required String bookingId,
    required String venueId,
    required double rating,
    required String content,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw "Bạn cần đăng nhập để đánh giá!";

    try {
      await submitVenueReviewUseCase.call(
        bookingId: bookingId,
        venueId: venueId,
        userId: user.id,
        rating: rating,
        content: content,
      );

      // Reload data
      await fetchVenueReviews(venueId);
      await fetchUserBookingsEligibility(venueId);
      await fetchStadiums();
    } catch (e) {
      print("Error submitting review: $e");
      throw "Gửi đánh giá thất bại: $e";
    }
  }
}
