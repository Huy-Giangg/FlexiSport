import 'package:flexisport_app/features/sports_complex/domain/entities/sports_complex_entity.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/venue_images_entity.dart';
import '../../domain/usecases/get_sports_complex_images_usecase.dart';
import '../../domain/usecases/get_sports_complex_usecase.dart';

class SportsComplexProvider extends ChangeNotifier {

  final GetSportsComplexUsecase getStadiumsUseCase;
  final GetSportsComplexImagesUsecase getStadiumImagesUseCase;

  SportsComplexProvider(this.getStadiumsUseCase, this.getStadiumImagesUseCase);

  List<SportsComplexEntity> stadiums = [];
  List<VenueImageEntity> currentStadiumImages = [];

  bool isLoading = false;
  bool isImagesLoading = false;
  String? errorMessage;
  String? imagesErrorMessage;

  Future<void> fetchStadiums() async {

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      stadiums = await getStadiumsUseCase.call();
    } catch (e) {
      errorMessage = e.toString();
      print('Error fetching stadiums: $e');
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
}