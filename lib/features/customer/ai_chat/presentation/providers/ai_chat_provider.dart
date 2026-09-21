import 'package:flutter/material.dart';
import 'package:flexisport_app/features/customer/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:flexisport_app/features/customer/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';

class AiChatProvider extends ChangeNotifier {
  final AiChatRepository repository;

  AiChatProvider({required this.repository}) {
    _initSettings();
  }

  final List<ChatMessageEntity> _messages = [];
  bool _isLoading = false;
  String _currentApiKey = '';
  String _serverUrl = '';
  String _currentTarget = 'auto'; // 'auto' | 'venue' | 'event' | 'court'

  List<ChatMessageEntity> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get currentApiKey => _currentApiKey;
  String get serverUrl => _serverUrl;
  String get currentTarget => _currentTarget;

  static const List<String> defaultPrompts = [
    "Sân Pickleball tốt nhất gần tôi?",
    "Tìm sân Cầu lông giá hợp lý",
    "Có giải đấu nào sắp diễn ra?",
    "Hướng dẫn thanh toán VietQR tự động",
    "Chính sách hủy sân và hoàn tiền sự kiện?",
  ];

  static const Map<String, String> targetLabels = {
    'auto': 'Tất cả',
    'venue': 'Sân bãi',
    'event': 'Sự kiện',
    'court': 'Sân đấu',
  };

  void setTarget(String target) {
    if (_currentTarget != target) {
      _currentTarget = target;
      notifyListeners();
    }
  }

  Future<void> _initSettings() async {
    _serverUrl = await repository.getServerUrl();
    final key = await repository.getStoredApiKey();
    if (key != null) {
      _currentApiKey = key;
    }
    notifyListeners();
  }

  Future<void> saveServerUrl(String url) async {
    await repository.saveServerUrl(url);
    _serverUrl = await repository.getServerUrl();
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    await repository.saveApiKey(key);
    _currentApiKey = key;
    notifyListeners();
  }

  void initializeChat(List<SportsComplexEntity> venues) {
    if (_messages.isNotEmpty) return;

    // Tin nhắn chào mừng ban đầu
    _messages.add(
      ChatMessageEntity(
        id: 'welcome_msg',
        content: 'Xin chào! Tôi là FlexiBot AI. Tôi có thể hỗ trợ gì cho bạn hôm nay? 😊',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedVenues: const [],
        quickReplies: const [],
      ),
    );
    notifyListeners();
  }

  Future<void> sendMessage({
    required String text,
    required List<SportsComplexEntity> availableVenues,
    double? userLat,
    double? userLng,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isLoading) return;

    // 1. Thêm tin nhắn của User vào danh sách
    final userMsg = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: trimmedText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    // 2. Tạo tin nhắn AI dạng placeholder với trạng thái đang stream
    final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    var currentAiContent = '';
    final aiPlaceholder = ChatMessageEntity(
      id: aiMsgId,
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(aiPlaceholder);
    _isLoading = true;
    notifyListeners();

    try {
      // 3. Lắng nghe Stream SSE từ backend chatbot-sports
      final stream = repository.askAiStream(
        query: trimmedText,
        target: _currentTarget,
      );

      await for (final token in stream) {
        currentAiContent += token;
        final index = _messages.indexWhere((m) => m.id == aiMsgId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            content: currentAiContent,
            isStreaming: true,
          );
          notifyListeners();
        }
      }

      // 4. Kết thúc Stream - parse suggested venues nếu có
      final finalIndex = _messages.indexWhere((m) => m.id == aiMsgId);
      if (finalIndex != -1) {
        final parsed = _extractSuggestedVenues(currentAiContent, availableVenues);
        _messages[finalIndex] = _messages[finalIndex].copyWith(
          content: parsed.content.isEmpty ? "Rất tiếc, tôi chưa có thông tin phù hợp cho yêu cầu này." : parsed.content,
          isStreaming: false,
          suggestedVenues: parsed.venues,
          quickReplies: _getRelevantQuickReplies(_currentTarget),
        );
      }
    } catch (e) {
      debugPrint("[AiChatProvider] Lỗi stream AI: $e");
      final errIndex = _messages.indexWhere((m) => m.id == aiMsgId);
      final currentUrl = await repository.getServerUrl();
      
      if (errIndex != -1) {
        _messages[errIndex] = ChatMessageEntity(
          id: aiMsgId,
          content: "⚠️ **Không thể kết nối tới máy chủ AI!**\n\n"
                   "- **Địa chỉ đang kết nối:** `$currentUrl/api/ask`\n"
                   "- **Chi tiết lỗi:** `$e`\n\n"
                   "👉 **Hướng dẫn khắc phục:**\n"
                   "1. Đảm bảo bạn đã chạy backend Python trong thư mục `chatbot-sports`: `python app.py`.\n"
                   "2. Nếu đang chạy trên **máy ảo Android (Emulator)**: Vào cài đặt máy chủ (biểu tượng góc trên bên phải) chọn `http://10.0.2.2:5000`.\n"
                   "3. Nếu đang chạy trên **thiết bị thật (điện thoại cắm dây/wifi)**: Máy tính và điện thoại phải chung mạng Wifi, nhập IP máy tính của bạn (VD: `http://192.168.1.xxx:5000`).\n"
                   "4. Nếu đang chạy trên **Windows/macOS/Chrome**: Chọn `http://127.0.0.1:5000`.",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
          isStreaming: false,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  _ParsedContent _extractSuggestedVenues(String text, List<SportsComplexEntity> availableVenues) {
    String cleanContent = text;
    final venues = <SportsComplexEntity>[];

    final venueRegex = RegExp(r'\[SUGGESTED_VENUES:\s*([^\]]+)\]', caseSensitive: false);
    final match = venueRegex.firstMatch(cleanContent);
    if (match != null) {
      final idsStr = match.group(1) ?? '';
      final ids = idsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      for (final id in ids) {
        final found = availableVenues.firstWhere(
          (v) => v.id == id,
          orElse: () => SportsComplexEntity(
            id: '',
            name: '',
            address: '',
            logoUrl: '',
            rating: 0,
            open_time: '',
            close_time: '',
          ),
        );
        if (found.id.isNotEmpty && !venues.any((v) => v.id == found.id)) {
          venues.add(found);
        }
      }
      cleanContent = cleanContent.replaceAll(venueRegex, '').trim();
    }

    return _ParsedContent(cleanContent, venues);
  }

  List<String> _getRelevantQuickReplies(String target) {
    switch (target) {
      case 'venue':
        return [
          "Sân cầu lông nào gần tôi?",
          "Sân pickleball có điều hòa",
          "Giá thuê sân vào giờ cao điểm?",
        ];
      case 'event':
        return [
          "Các giải đấu sắp diễn ra?",
          "Kèo giao lưu cho người mới",
          "Quy định hoàn tiền sự kiện?",
        ];
      case 'court':
        return [
          "Cách xem khung giờ còn trống",
          "Thời gian giữ chỗ là bao lâu?",
          "Hướng dẫn thanh toán VietQR",
        ];
      default:
        return [
          "Sân Pickleball tốt nhất gần tôi",
          "Các giải đấu sắp diễn ra?",
          "Hướng dẫn thanh toán VietQR",
        ];
    }
  }

  void clearChat(List<SportsComplexEntity> venues) {
    _messages.clear();
    initializeChat(venues);
    notifyListeners();
  }
}

class _ParsedContent {
  final String content;
  final List<SportsComplexEntity> venues;
  _ParsedContent(this.content, this.venues);
}

