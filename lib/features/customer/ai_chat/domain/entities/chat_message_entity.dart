import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';

class ChatMessageEntity {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<SportsComplexEntity> suggestedVenues;
  final List<String> quickReplies;
  final bool isError;

  ChatMessageEntity({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestedVenues = const [],
    this.quickReplies = const [],
    this.isError = false,
  });

  ChatMessageEntity copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<SportsComplexEntity>? suggestedVenues,
    List<String>? quickReplies,
    bool? isError,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      suggestedVenues: suggestedVenues ?? this.suggestedVenues,
      quickReplies: quickReplies ?? this.quickReplies,
      isError: isError ?? this.isError,
    );
  }
}
