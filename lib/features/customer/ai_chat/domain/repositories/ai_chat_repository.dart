import 'package:flexisport_app/features/customer/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';

abstract class AiChatRepository {
  Future<ChatMessageEntity> sendMessage({
    required String prompt,
    required List<ChatMessageEntity> history,
    required List<SportsComplexEntity> availableVenues,
    double? userLat,
    double? userLng,
  });

  Future<String?> getStoredApiKey();
  Future<void> saveApiKey(String apiKey);
}
