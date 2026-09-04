import 'package:flexisport_app/features/customer/ai_chat/presentation/providers/ai_chat_provider.dart';
import 'package:flexisport_app/features/customer/ai_chat/presentation/widgets/api_key_dialog.dart';
import 'package:flexisport_app/features/customer/ai_chat/presentation/widgets/chat_bubble.dart';
import 'package:flexisport_app/features/customer/ai_chat/presentation/widgets/quick_prompts_widget.dart';
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

  void _openApiKeyDialog() {
    final chatProvider = context.read<AiChatProvider>();
    showDialog(
      context: context,
      builder: (context) => ApiKeyDialog(
        currentApiKey: chatProvider.currentApiKey,
        onSave: (key) => chatProvider.saveApiKey(key),
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

    // Cuộn xuống khi có tin nhắn mới
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && chatProvider.messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
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
                    color: Colors.green.withOpacity(0.3),
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
                      "Trợ lý Thể thao • Trực tuyến",
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
            icon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF006D38)),
            tooltip: "Cấu hình API Key",
            onPressed: _openApiKeyDialog,
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
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < chatProvider.messages.length) {
                    final message = chatProvider.messages[index];
                    return ChatBubble(
                      message: message,
                      onQuickReplySelected: (reply) => _sendMessage(reply),
                    );
                  } else {
                    // Loading indicator khi AI đang suy nghĩ
                    return _buildLoadingBubble();
                  }
                },
              ),
            ),

            // Dãy câu hỏi gợi ý nhanh (Quick Prompts)
            QuickPromptsWidget(
              prompts: AiChatProvider.defaultPrompts,
              onSelected: (prompt) => _sendMessage(prompt),
            ),

            // Khung nhập tin nhắn
            _buildInputBar(chatProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A86B), Color(0xFF006D38)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006D38)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "FlexiBot đang phân tích thông tin sân...",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
            color: Colors.black.withOpacity(0.04),
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
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
                  hintText: "Hỏi FlexiBot về sân, giá, đặt lịch, thanh toán...",
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
