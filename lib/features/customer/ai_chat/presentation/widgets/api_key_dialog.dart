import 'package:flutter/material.dart';

class ApiKeyDialog extends StatefulWidget {
  final String currentApiKey;
  final ValueChanged<String> onSave;

  const ApiKeyDialog({
    super.key,
    required this.currentApiKey,
    required this.onSave,
  });

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentApiKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vpn_key_rounded, color: Color(0xFF006D38)),
          ),
          const SizedBox(width: 10),
          const Text(
            "Cấu hình Gemini API",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bạn có thể nhập Google Gemini API Key để trò chuyện trực tiếp với mô hình Gemini AI mới nhất. Nếu để trống, hệ thống sẽ sử dụng Trợ lý Phân tích CSDL tích hợp sẵn của FlexiSport.",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: "Gemini API Key",
              hintText: "AIzaSy...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_controller.text.trim());
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã cập nhật cấu hình API Key thành công!")),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006D38),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Lưu cấu hình"),
        ),
      ],
    );
  }
}
