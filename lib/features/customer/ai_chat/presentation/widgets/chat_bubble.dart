import 'package:flexisport_app/features/customer/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:flexisport_app/features/customer/ai_chat/presentation/widgets/chat_venue_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final ValueChanged<String>? onQuickReplySelected;

  const ChatBubble({
    super.key,
    required this.message,
    this.onQuickReplySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildAiBubble(context);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF006D38), // Brand green
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, color: Color(0xFF006D38), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar FlexiBot
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A86B), Color(0xFF006D38)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),

              // Nội dung tin nhắn của FlexiBot
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF1E293B),
                          ),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          listBullet: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF006D38),
                          ),
                        ),
                      ),
                    ),

                    // Danh sách thẻ sân tương tác (nếu AI có đề xuất sân)
                    if (message.suggestedVenues.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, top: 4, bottom: 2),
                        child: Text(
                          "Sân được đề xuất cho bạn:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 255,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: message.suggestedVenues.length,
                          itemBuilder: (context, index) {
                            final venue = message.suggestedVenues[index];
                            return ChatVenueCard(venue: venue);
                          },
                        ),
                      ),
                    ],

                    // Gợi ý phản hồi nhanh (Quick replies)
                    if (message.quickReplies.isNotEmpty && onQuickReplySelected != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: message.quickReplies.map((reply) {
                          return InkWell(
                            onTap: () => onQuickReplySelected!(reply),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_outlined, size: 12, color: Colors.green.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    reply,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
