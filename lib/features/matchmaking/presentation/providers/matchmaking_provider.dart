import 'package:flutter/material.dart';
import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_request.dart';
import 'package:flexisport_app/features/matchmaking/domain/repositories/matchmaking_repository.dart';

class MatchmakingProvider extends ChangeNotifier {
  final MatchmakingRepository repository;

  MatchmakingProvider({required this.repository});

  List<MatchmakingPost> _posts = [];
  List<MatchmakingPost> get posts => _posts;

  List<MatchmakingRequest> _requests = [];
  List<MatchmakingRequest> get requests => _requests;

  List<MatchmakingRequest> _userRequests = [];
  List<MatchmakingRequest> get userRequests => _userRequests;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadPosts({String? sportCategory, String? district, String? level}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await repository.getMatchmakingPosts(
        sportCategory: sportCategory,
        district: district,
        level: level,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost(MatchmakingPost post) async {
    _isLoading = true;
    notifyListeners();

    try {
      await repository.createMatchmakingPost(post);
      await loadPosts();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRequests(String postId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _requests = await repository.getMatchmakingRequests(postId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserRequests(String userId) async {
    try {
      _userRequests = await repository.getUserRequests(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> submitRequest(MatchmakingRequest request) async {
    try {
      await repository.submitMatchmakingRequest(request);
      if (request.postId == request.postId) {
        await loadRequests(request.postId);
      }
      await loadUserRequests(request.userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> respondToRequest(String requestId, String status, String postId) async {
    try {
      await repository.updateRequestStatus(requestId, status);
      await loadRequests(postId);
      await loadPosts(); // Cập nhật lại số lượng slot trống của các kèo
      
      // Cập nhật lại danh sách yêu cầu của user để đồng bộ UI
      MatchmakingRequest? requestObj;
      for (final r in _requests) {
        if (r.id == requestId) {
          requestObj = r;
          break;
        }
      }
      if (requestObj == null) {
        for (final r in _userRequests) {
          if (r.id == requestId) {
            requestObj = r;
            break;
          }
        }
      }

      if (requestObj != null && requestObj.userId.isNotEmpty) {
        await loadUserRequests(requestObj.userId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelPost(String postId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await repository.updatePostStatus(postId, 'cancelled');
      await loadPosts();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
