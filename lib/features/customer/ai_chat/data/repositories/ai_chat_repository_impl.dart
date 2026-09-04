import 'package:flexisport_app/features/customer/ai_chat/data/datasources/ai_chat_remote_datasource.dart';
import 'package:flexisport_app/features/customer/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:flexisport_app/features/customer/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';

class AiChatRepositoryImpl implements AiChatRepository {
  final AiChatRemoteDatasource datasource;

  AiChatRepositoryImpl(this.datasource);

  @override
  Future<ChatMessageEntity> sendMessage({
    required String prompt,
    required List<ChatMessageEntity> history,
    required List<SportsComplexEntity> availableVenues,
    double? userLat,
    double? userLng,
  }) {
    return datasource.sendMessage(
      prompt: prompt,
      history: history,
      availableVenues: availableVenues,
      userLat: userLat,
      userLng: userLng,
    );
  }

  @override
  Future<String?> getStoredApiKey() {
    return datasource.getStoredApiKey();
  }

  @override
  Future<void> saveApiKey(String apiKey) {
    return datasource.saveApiKey(apiKey);
  }
}
