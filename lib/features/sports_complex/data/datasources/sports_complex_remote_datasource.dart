import 'package:flexisport_app/features/sports_complex/data/models/sports_complex_model.dart';
import 'package:flexisport_app/features/sports_complex/data/models/venue_images_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SportsComplexRemoteDatasource {
  final supabase = Supabase.instance.client;

  Future<List<SportsComplexModel>> getStadiums() async {
    final response = await supabase.from('venues').select();

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
}
