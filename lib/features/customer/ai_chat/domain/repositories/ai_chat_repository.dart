import 'package:flexisport_app/features/customer/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';

abstract class AiChatRepository {
  /// Gửi câu hỏi và nhận luồng SSE tokens thời gian thực từ Python backend (chatbot-sports)
  Stream<String> askAiStream({
    required String query,
    String target = 'auto',
  });

  /// Phương thức gửi tin nhắn không stream (dự phòng)
  Future<ChatMessageEntity> sendMessage({
    required String prompt,
    required List<ChatMessageEntity> history,
    required List<SportsComplexEntity> availableVenues,
    double? userLat,
    double? userLng,
    String target = 'auto',
  });

  Future<String> getServerUrl();
  Future<void> saveServerUrl(String url);

  Future<String?> getStoredApiKey();
  Future<void> saveApiKey(String apiKey);
}

