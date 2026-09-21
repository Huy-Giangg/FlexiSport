import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flexisport_app/features/customer/ai_chat/data/datasources/ai_chat_remote_datasource.dart';

class ServerConfigDialog extends StatefulWidget {
  final String currentUrl;
  final ValueChanged<String> onSave;

  const ServerConfigDialog({
    super.key,
    required this.currentUrl,
    required this.onSave,
  });

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isChecking = false;
  bool? _isSuccess;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isChecking = true;
      _isSuccess = null;
      _statusMessage = "Đang kiểm tra kết nối...";
    });

    try {
      final baseHost = AiChatRemoteDatasource.normalizeBaseUrl(url);
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      final res = await dio.get('$baseHost/');
      if (res.statusCode == 200) {
        setState(() {
          _isSuccess = true;
          _statusMessage = "✅ Kết nối thành công tới máy chủ AI!";
        });
      } else {
        setState(() {
          _isSuccess = false;
          _statusMessage = "⚠️ Máy chủ trả về mã HTTP ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = "❌ Không thể kết nối. Hãy đảm bảo python app.py đang chạy tại địa chỉ này.";
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _setUrl(String url) {
    _urlController.text = url;
    setState(() {
      _isSuccess = null;
      _statusMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_ethernet_rounded, color: Color(0xFF006D38), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cài đặt Máy chủ AI",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          "Backend chatbot-sports",
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Địa chỉ API Base URL:",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: "http://10.0.2.2:5000",
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF006D38), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nút chọn nhanh
              const Text(
                "Chọn nhanh theo môi trường chạy:",
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text("127.0.0.1 (ADB Reverse / Máy ảo)"),
                    avatar: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.green),
                    onPressed: () => _setUrl("http://127.0.0.1:5000"),
                  ),
                  ActionChip(
                    label: const Text("IP Wi-Fi LAN (192.168.0.131)"),
                    avatar: const Icon(Icons.wifi, size: 16),
                    onPressed: () => _setUrl("http://192.168.0.131:5000"),
                  ),
                  ActionChip(
                    label: const Text("10.0.2.2 (Emulator NAT)"),
                    avatar: const Icon(Icons.android, size: 16),
                    onPressed: () => _setUrl("http://10.0.2.2:5000"),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Nút kiểm tra kết nối
              OutlinedButton.icon(
                onPressed: _isChecking ? null : _checkConnection,
                icon: _isChecking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check_rounded, size: 18),
                label: Text(_isChecking ? "Đang kiểm tra..." : "Kiểm tra kết nối máy chủ"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF006D38),
                  side: const BorderSide(color: Color(0xFF006D38)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 42),
                ),
              ),

              // Kết quả kiểm tra
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isSuccess == true
                        ? Colors.green.shade50
                        : (_isSuccess == false ? Colors.red.shade50 : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSuccess == true
                          ? Colors.green.shade200
                          : (_isSuccess == false ? Colors.red.shade200 : Colors.blue.shade200),
                    ),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _isSuccess == true
                          ? Colors.green.shade900
                          : (_isSuccess == false ? Colors.red.shade900 : Colors.blue.shade900),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Bottom buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(_urlController.text.trim());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D38),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Lưu cấu hình"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
