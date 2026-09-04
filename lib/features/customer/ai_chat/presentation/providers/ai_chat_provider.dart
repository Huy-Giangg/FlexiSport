import 'package:flutter/material.dart';
import 'package:flexisport_app/features/customer/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:flexisport_app/features/customer/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';

class AiChatProvider extends ChangeNotifier {
  final AiChatRepository repository;

  AiChatProvider({required this.repository}) {
    _loadApiKey();
  }

  final List<ChatMessageEntity> _messages = [];
  bool _isLoading = false;
  String _currentApiKey = '';

  List<ChatMessageEntity> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get currentApiKey => _currentApiKey;

  static const List<String> defaultPrompts = [
    "🎾 Sân Pickleball tốt nhất gần tôi",
    "🏸 Tìm sân Cầu lông giá hợp lý",
    "💳 Hướng dẫn thanh toán VietQR tự động",
    "📅 Quy trình đặt sân và thời gian giữ chỗ",
    "⚠️ Chính sách hủy sân và hoàn tiền sự kiện",
  ];

  Future<void> _loadApiKey() async {
    final key = await repository.getStoredApiKey();
    if (key != null) {
      _currentApiKey = key;
      notifyListeners();
    }
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
        content: '''
Xin chào! Em là **FlexiBot** - Trợ lý AI thông minh của nền tảng thể thao **FlexiSport** 🎾🏸⚽.

Em có thể hỗ trợ bạn:
- 🔍 **Tìm & gợi ý sân**: Tìm sân gần bạn theo môn (Pickleball, Cầu lông, Bóng đá, v.v.), xem giá và đánh giá.
- ⚡ **Đặt sân tức thì**: Giúp bạn chọn slot và dẫn trực tiếp vào trang đặt sân.
- 💳 **Hướng dẫn thanh toán VietQR**: Giải thích chi tiết quy trình chuyển khoản và xác nhận tự động.
- ❓ **Giải đáp thắc mắc**: Chính sách hủy đặt sân, tự động hủy sự kiện thiếu người, dịch vụ tiện ích...

Bạn cần em hỗ trợ gì hôm nay ạ?
''',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedVenues: venues.take(2).toList(),
        quickReplies: defaultPrompts,
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
    _isLoading = true;
    notifyListeners();

    try {
      // 2. Gửi request tới Repository (Gemini API hoặc Smart Fallback)
      final aiResponse = await repository.sendMessage(
        prompt: trimmedText,
        history: _messages,
        availableVenues: availableVenues,
        userLat: userLat,
        userLng: userLng,
      );

      _messages.add(aiResponse);
    } catch (e) {
      _messages.add(
        ChatMessageEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: "Đã có sự cố khi kết nối với trợ lý AI ($e). Bạn vui lòng thử lại nhé!",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat(List<SportsComplexEntity> venues) {
    _messages.clear();
    initializeChat(venues);
    notifyListeners();
  }
}
