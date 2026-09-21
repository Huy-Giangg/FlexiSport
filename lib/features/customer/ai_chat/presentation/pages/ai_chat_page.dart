import 'package:flexisport_app/features/customer/ai_chat/presentation/providers/ai_chat_provider.dart';
import 'package:flexisport_app/features/customer/ai_chat/presentation/widgets/chat_bubble.dart';
import 'package:flexisport_app/features/customer/ai_chat/presentation/widgets/server_config_dialog.dart';
import 'package:flexisport_app/features/customer/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sportsProvider = context.read<SportsComplexProvider>();
      final chatProvider = context.read<AiChatProvider>();
      chatProvider.initializeChat(sportsProvider.stadiums);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text;
    if (text.trim().isEmpty) return;

    final chatProvider = context.read<AiChatProvider>();
    final sportsProvider = context.read<SportsComplexProvider>();

    if (customText == null) {
      _textController.clear();
      setState(() {
        _isComposing = false;
      });
    }

    chatProvider.sendMessage(
      text: text,
      availableVenues: sportsProvider.stadiums,
    );

    _scrollToBottom();
  }

  void _openServerConfigDialog() {
    final chatProvider = context.read<AiChatProvider>();
    showDialog(
      context: context,
      builder: (context) => ServerConfigDialog(
        currentUrl: chatProvider.serverUrl,
        onSave: (url) => chatProvider.saveServerUrl(url),
      ),
    );
  }

  void _confirmClearChat() {
    final sportsProvider = context.read<SportsComplexProvider>();
    final chatProvider = context.read<AiChatProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xóa đoạn chat?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: const Text("Cuộc trò chuyện hiện tại sẽ được làm mới lại từ đầu."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.clearChat(sportsProvider.stadiums);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Làm mới"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<AiChatProvider>();

    // Cuộn xuống khi có tin nhắn mới hoặc streaming token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && chatProvider.messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Bot Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A86B), Color(0xFF006D38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      "FlexiBot AI",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.verified, color: Color(0xFF006D38), size: 16),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Chatbot Sports RAG • Trực tuyến",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_rounded, color: Color(0xFF006D38)),
            tooltip: "Cài đặt máy chủ AI",
            onPressed: _openServerConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            tooltip: "Làm mới hội thoại",
            onPressed: _confirmClearChat,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Danh sách tin nhắn
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                itemCount: chatProvider.messages.length,
                itemBuilder: (context, index) {
                  final message = chatProvider.messages[index];
                  return ChatBubble(
                    message: message,
                    onQuickReplySelected: (reply) => _sendMessage(reply),
                  );
                },
              ),
            ),

            // Thanh câu hỏi mẫu nằm ngang trên thanh nhắn tin
            _buildHorizontalSuggestionsBar(chatProvider),

            // Khung nhập tin nhắn
            _buildInputBar(chatProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSuggestionsBar(AiChatProvider chatProvider) {
    final prompts = AiChatProvider.defaultPrompts;
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Icon chat bên trái
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Danh sách các câu hỏi mẫu cuộn ngang
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 12),
              itemCount: prompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = prompts[index];
                return InkWell(
                  onTap: chatProvider.isLoading ? null : () => _sendMessage(prompt),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AiChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (val) {
                  setState(() {
                    _isComposing = val.trim().isNotEmpty;
                  });
                },
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Nhập câu hỏi...",
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: _isComposing && !chatProvider.isLoading
                  ? const LinearGradient(
                      colors: [Color(0xFF00A86B), Color(0xFF006D38)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: _isComposing && !chatProvider.isLoading ? null : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: (_isComposing && !chatProvider.isLoading)
                  ? () => _sendMessage()
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
