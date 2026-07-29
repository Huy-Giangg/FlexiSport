import 'package:flexisport_app/features/sports_complex/data/models/sports_complex_model.dart';
import 'package:flexisport_app/features/sports_complex/data/models/venue_images_model.dart';
import 'package:flexisport_app/features/sports_complex/data/models/venue_review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SportsComplexRemoteDatasource {
  final supabase = Supabase.instance.client;

  Future<List<SportsComplexModel>> getStadiums() async {
    final response = await supabase
        .from('venues')
        .select('id, name, address, rating, open_time, close_time, latitude, longitude, sports_type, logo_url');

    return response
        .map<SportsComplexModel>((json) => SportsComplexModel.fromJson(json))
        .toList();
  }

  Future<List<VenueImageModel>> getStadiumImages(String stadiumId) async {
    final response = await supabase
        .from('venue_images')
        .select()
        .eq('venue_id', stadiumId);

    return response
        .map<VenueImageModel>((json) => VenueImageModel.fromJson(json))
        .toList();
  }

  Future<List<VenueReviewModel>> getVenueReviews(String venueId) async {
    final response = await supabase
        .from('venue_reviews')
        .select('*, profiles(name)')
        .eq('venue_id', venueId)
        .order('created_at', ascending: false);

    return response
        .map<VenueReviewModel>((json) => VenueReviewModel.fromJson(json))
        .toList();
  }

  Future<void> submitVenueReview({
    required String bookingId,
    required String venueId,
    required String userId,
    required double rating,
    required String content,
  }) async {
    await supabase.from('venue_reviews').upsert({
      'booking_id': bookingId,
      'venue_id': venueId,
      'user_id': userId,
      'rating': rating,
      'content': content,
    });

    await updateVenueAverageRating(venueId);
  }

  Future<void> updateVenueAverageRating(String venueId) async {
    final reviews = await supabase
        .from('venue_reviews')
        .select('rating')
        .eq('venue_id', venueId);

    if (reviews.isEmpty) return;

    double total = 0;
    for (var r in reviews) {
      total += (r['rating'] as num).toDouble();
    }
    double average = total / reviews.length;
    average = double.parse(average.toStringAsFixed(1));

    await supabase
        .from('venues')
        .update({'rating': average})
        .eq('id', venueId);
  }
}
