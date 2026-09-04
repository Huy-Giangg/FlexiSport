import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flexisport_app/core/config/app_config.dart';
import 'package:flexisport_app/core/utils/location_helper.dart';
import 'package:flexisport_app/features/customer/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:flexisport_app/features/customer/sports_complex/domain/entities/sports_complex_entity.dart';

class AiChatRemoteDatasource {
  static const String _prefApiKey = 'gemini_api_key_custom';

  Future<String?> getStoredApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString(_prefApiKey);
    if (customKey != null && customKey.trim().isNotEmpty) {
      return customKey.trim();
    }
    if (AppConfig.geminiApiKey.isNotEmpty) {
      return AppConfig.geminiApiKey;
    }
    return null;
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (apiKey.trim().isEmpty) {
      await prefs.remove(_prefApiKey);
    } else {
      await prefs.setString(_prefApiKey, apiKey.trim());
    }
  }

  Future<ChatMessageEntity> sendMessage({
    required String prompt,
    required List<ChatMessageEntity> history,
    required List<SportsComplexEntity> availableVenues,
    double? userLat,
    double? userLng,
  }) async {
    final apiKey = await getStoredApiKey();

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        return await _callGemini(
          apiKey: apiKey,
          prompt: prompt,
          history: history,
          availableVenues: availableVenues,
          userLat: userLat,
          userLng: userLng,
        );
      } catch (e) {
        debugPrint("Lỗi khi gọi Gemini API ($e). Sử dụng cơ chế phản hồi thông minh dự phòng.");
      }
    }

    // Fallback response generator khi chưa có API key hoặc gặp sự cố mạng
    return _generateSmartFallbackResponse(
      prompt: prompt,
      availableVenues: availableVenues,
      userLat: userLat,
      userLng: userLng,
    );
  }

  Future<ChatMessageEntity> _callGemini({
    required String apiKey,
    required String prompt,
    required List<ChatMessageEntity> history,
    required List<SportsComplexEntity> availableVenues,
    double? userLat,
    double? userLng,
  }) async {
    // Xây dựng ngữ cảnh các sân thể thao hiện có
    final venuesContext = availableVenues.map((v) {
      double? distance;
      if (userLat != null && userLng != null && v.latitude != null && v.longitude != null) {
        distance = LocationHelper.calculateDistance(userLat, userLng, v.latitude!, v.longitude!);
      } else {
        distance = LocationHelper.calculateDistanceFromDefault(v.latitude, v.longitude);
      }
      final distStr = "${distance.toStringAsFixed(1)} km";
      return "- ID: ${v.id} | Tên: ${v.name} | Môn: ${v.sportsType ?? 'Đa năng'} | Địa chỉ: ${v.address} | Giờ: ${v.open_time} - ${v.close_time} | Đánh giá: ${v.rating}⭐ | Khoảng cách: $distStr";
    }).join("\n");

    final systemInstruction = '''
Bạn là FlexiBot - Trợ lý AI thông minh chính thức của nền tảng thể thao FlexiSport.
Nhiệm vụ của bạn:
1. Tư vấn lựa chọn sân thể thao phù hợp cho khách hàng dựa trên môn thể thao (Pickleball, Cầu lông, Bóng đá, Tennis, Bóng rổ, v.v.), vị trí/khoảng cách, giờ mở cửa, đánh giá sao và nhu cầu cụ thể.
2. Giải đáp thắc mắc về cơ sở vật chất, dịch vụ, nội quy sân và cách thức sử dụng ứng dụng.
3. Hướng dẫn quy trình đặt sân & thanh toán:
   - Bước 1: Tìm sân và nhấn "Đặt sân ngay" để vào giao diện chọn slot trực quan (mỗi khung giờ 30-60 phút).
   - Bước 2: Chọn ngày và các slot còn trống. Hệ thống sẽ tạm giữ chỗ (Court Lock).
   - Bước 3: Điền thông tin người đặt và chọn thanh toán.
   - Bước 4: Chuyển khoản qua VietQR với đúng số tiền và mã thanh toán tự động (VD: FLEXIxxxx). Hệ thống nhận diện qua Webhook ngân hàng và xác nhận tức thì.
   - Chính sách hủy & hoàn tiền: Sự kiện tự động hủy trước 2h nếu thiếu người tham gia tối thiểu; đặt sân có thể hủy theo quy định cụ thể của chủ sân.
4. Hỗ trợ tìm kiếm sân: Khi bạn gợi ý một hoặc nhiều sân từ danh sách cơ sở dữ liệu được cung cấp dưới đây, BẮT BUỘC chèn đoạn tag sau ở CUỐI CÙNG của câu trả lời:
   [SUGGESTED_VENUES: id1, id2]
   (Trong đó id1, id2 là các ID thực tế của sân trong danh sách dữ liệu).
5. Kèm theo 2 đến 3 câu hỏi gợi ý tiếp theo mà người dùng có thể muốn hỏi:
   [QUICK_REPLIES: "Câu hỏi 1", "Câu hỏi 2"]

DỮ LIỆU CÁC SÂN THỂ THAO HIỆN CÓ TRÊN HỆ THỐNG:
$venuesContext

Quy tắc phong cách:
- Luôn trả lời bằng tiếng Việt, lịch sự, thân thiện, tràn đầy tinh thần thể thao.
- Sử dụng Markdown để trình bày rõ ràng, dễ đọc (in đậm, danh sách gạch đầu dòng).
- Chỉ gợi ý các sân thực sự có trong danh sách trên.
''';

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1000,
      ),
    );

    // Chuyển đổi lịch sử chat
    final contentHistory = <Content>[];
    for (final msg in history.take(10)) { // Lấy tối đa 10 tin nhắn gần nhất để tối ưu context
      if (msg.isUser) {
        contentHistory.add(Content.text(msg.content));
      } else {
        contentHistory.add(Content.model([TextPart(msg.content)]));
      }
    }

    final chat = model.startChat(history: contentHistory);
    final response = await chat.sendMessage(Content.text(prompt));
    final rawText = response.text ?? "Xin lỗi, tôi chưa thể xử lý yêu cầu lúc này. Bạn vui lòng thử lại nhé!";

    return _parseAiResponse(rawText, availableVenues);
  }

  ChatMessageEntity _parseAiResponse(String rawText, List<SportsComplexEntity> availableVenues) {
    String cleanContent = rawText;
    final suggestedVenues = <SportsComplexEntity>[];
    final quickReplies = <String>[];

    // Trích xuất SUGGESTED_VENUES
    final venueRegex = RegExp(r'\[SUGGESTED_VENUES:\s*([^\]]+)\]', caseSensitive: false);
    final venueMatch = venueRegex.firstMatch(cleanContent);
    if (venueMatch != null) {
      final idsStr = venueMatch.group(1) ?? '';
      final ids = idsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      for (final id in ids) {
        final found = availableVenues.firstWhere(
          (v) => v.id == id,
          orElse: () => SportsComplexEntity(
            id: '',
            name: '',
            address: '',
            logoUrl: '',
            rating: 0,
            open_time: '',
            close_time: '',
          ),
        );
        if (found.id.isNotEmpty && !suggestedVenues.any((v) => v.id == found.id)) {
          suggestedVenues.add(found);
        }
      }
      cleanContent = cleanContent.replaceAll(venueRegex, '').trim();
    }

    // Trích xuất QUICK_REPLIES
    final repliesRegex = RegExp(r'\[QUICK_REPLIES:\s*([^\]]+)\]', caseSensitive: false);
    final repliesMatch = repliesRegex.firstMatch(cleanContent);
    if (repliesMatch != null) {
      final repliesStr = repliesMatch.group(1) ?? '';
      final quoteRegex = RegExp(r'"([^"]+)"');
      final matches = quoteRegex.allMatches(repliesStr);
      for (final m in matches) {
        final text = m.group(1)?.trim();
        if (text != null && text.isNotEmpty) {
          quickReplies.add(text);
        }
      }
      cleanContent = cleanContent.replaceAll(repliesRegex, '').trim();
    }

    return ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: cleanContent,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedVenues: suggestedVenues,
      quickReplies: quickReplies,
    );
  }

  ChatMessageEntity _generateSmartFallbackResponse({
    required String prompt,
    required List<SportsComplexEntity> availableVenues,
    double? userLat,
    double? userLng,
  }) {
    final lowerPrompt = prompt.toLowerCase();
    final suggestedVenues = <SportsComplexEntity>[];
    String replyText = '';
    final quickReplies = <String>[];

    // 1. Kiểm tra câu hỏi về thanh toán VietQR
    if (lowerPrompt.contains('thanh toán') ||
        lowerPrompt.contains('vietqr') ||
        lowerPrompt.contains('chuyển khoản') ||
        lowerPrompt.contains('trả tiền') ||
        lowerPrompt.contains('ngân hàng')) {
      replyText = '''
**Hướng dẫn Thanh toán Tự động VietQR trên FlexiSport:**

1. **Bước 1: Chọn sân & Khung giờ (Slot)**
   - Bạn chọn sân muốn chơi và nhấp **"Đặt sân ngay"**.
   - Chọn ngày chơi và các khung giờ còn trống (màu xanh lá).
2. **Bước 2: Xác nhận thông tin**
   - Kiểm tra họ tên, số điện thoại và ghi chú (nếu có) tại trang tóm tắt.
3. **Bước 3: Quét mã VietQR**
   - Màn hình sẽ hiển thị mã QR cùng số tiền và **Mã giao dịch** (Ví dụ: `FLEXI8B9C123D`).
   - Dùng bất kỳ ứng dụng ngân hàng nào (Vietcombank, MBBank, BIDV, Techcombank,...) quét mã QR. 
   - **Lưu ý quan trọng**: Giữ nguyên nội dung chuyển khoản để hệ thống đối soát tự động.
4. **Bước 4: Xác nhận tức thì**
   - Ngay khi tiền vào tài khoản thụ hưởng, hệ thống tự động nhận diện qua Webhook và chuyển sang màn hình **Thanh toán Thành công**.
''';
      quickReplies.addAll([
        "Quy định hủy sân và hoàn tiền?",
        "Làm sao để biết sân còn trống?",
        "Gợi ý sân cầu lông tốt nhất",
      ]);
    }
    // 2. Kiểm tra câu hỏi về quy trình đặt sân & giữ chỗ
    else if (lowerPrompt.contains('quy trình') ||
        lowerPrompt.contains('cách đặt') ||
        lowerPrompt.contains('giữ chỗ') ||
        lowerPrompt.contains('hướng dẫn')) {
      replyText = '''
**Quy trình Đặt sân Thể thao trên FlexiSport:**

- **Bước 1**: Tìm kiếm sân theo môn thể thao bạn muốn (Cầu lông, Pickleball, Bóng đá,...).
- **Bước 2**: Nhấn vào sân để xem hình ảnh thực tế, tiện ích, biểu phí theo khung giờ (giờ thường & giờ cao điểm).
- **Bước 3**: Nhấn nút **"Đặt sân ngay"** -> Giao diện chọn slot theo dòng thời gian trực quan.
- **Bước 4**: Khi bạn chọn slot, hệ thống sẽ tạm giữ chỗ (Lock) trong 10 phút để bạn hoàn tất thanh toán mà không sợ bị người khác đặt trùng.
- **Bước 5**: Hoàn tất chuyển khoản VietQR để nhận mã đặt chỗ thành công!
''';
      quickReplies.addAll([
        "Hướng dẫn thanh toán VietQR",
        "Sân Pickleball nào gần tôi?",
        "Chính sách hủy sân thế nào?",
      ]);
    }
    // 3. Kiểm tra câu hỏi về quy định hủy, hoàn tiền, sự kiện
    else if (lowerPrompt.contains('hủy') ||
        lowerPrompt.contains('hoàn tiền') ||
        lowerPrompt.contains('đổi lịch') ||
        lowerPrompt.contains('sự kiện')) {
      replyText = '''
**Chính sách Hủy sân & Hoàn tiền trên FlexiSport:**

- **Đặt sân thông thường**: Bạn có thể xem chính sách hủy cụ thể tại tab *Điều khoản & Quy định* của từng cơ sở thể thao. Hầu hết các sân cho phép hủy trước 6h - 12h trước giờ đá.
- **Sự kiện & Giải đấu ghép**:
  - Nếu trước **2 tiếng** diễn ra mà sự kiện chưa đạt đủ số lượng người tối thiểu (`min_tickets`), hệ thống FlexiSport sẽ **tự động hủy sự kiện** và hoàn lại 100% tiền vé cho người tham gia.
- **Quá hạn thanh toán**: Mỗi đơn đặt có thời gian đếm ngược (thường là 10 phút). Nếu quá hạn chưa thanh toán, các slot sẽ tự động được mở lại cho người khác.
''';
      quickReplies.addAll([
        "Cách ghép kèo tìm đối thủ?",
        "Tìm sân bóng đá gần tôi",
        "Hướng dẫn thanh toán VietQR",
      ]);
    }
    // 4. Tìm kiếm / tư vấn theo môn thể thao hoặc khoảng cách
    else {
      String sportFilter = '';
      if (lowerPrompt.contains('pickleball')) {
        sportFilter = 'pickleball';
      } else if (lowerPrompt.contains('cầu lông') || lowerPrompt.contains('badminton')) {
        sportFilter = 'cầu lông';
      } else if (lowerPrompt.contains('bóng đá') || lowerPrompt.contains('football') || lowerPrompt.contains('soccer')) {
        sportFilter = 'bóng đá';
      } else if (lowerPrompt.contains('tennis')) {
        sportFilter = 'tennis';
      } else if (lowerPrompt.contains('bóng rổ') || lowerPrompt.contains('basketball')) {
        sportFilter = 'bóng rổ';
      } else if (lowerPrompt.contains('bóng chuyền') || lowerPrompt.contains('volleyball')) {
        sportFilter = 'bóng chuyền';
      }

      List<SportsComplexEntity> matched = [];
      if (sportFilter.isNotEmpty) {
        matched = availableVenues.where((v) {
          final t = (v.sportsType ?? '').toLowerCase();
          return t.contains(sportFilter);
        }).toList();
      }

      if (matched.isEmpty) {
        // Lấy các sân có đánh giá cao nhất
        matched = List<SportsComplexEntity>.from(availableVenues)
          ..sort((a, b) => b.rating.compareTo(a.rating));
        matched = matched.take(3).toList();
      } else {
        matched = matched.take(3).toList();
      }

      suggestedVenues.addAll(matched);

      if (sportFilter.isNotEmpty) {
        replyText = '''
Dạ, em đã tìm thấy **${matched.length} cơ sở** cho bộ môn **${sportFilter.toUpperCase()}** phù hợp nhất với bạn:

${matched.map((v) => "• **${v.name}** - Đánh giá: ${v.rating}⭐ | Giờ mở: ${v.open_time} - ${v.close_time}\n  *Địa chỉ: ${v.address}*").join("\n\n")}

Bạn có thể bấm vào thẻ bên dưới để xem hình ảnh chi tiết hoặc nhấn **"Đặt sân ngay"** để chọn khung giờ nhé!
''';
      } else {
        replyText = '''
Xin chào! Em là **FlexiBot** - Trợ lý AI thể thao của FlexiSport 🎾🏸⚽.

Em có thể hỗ trợ bạn:
1. **Tìm kiếm & gợi ý sân**: Tìm sân theo môn thể thao, vị trí gần bạn, mức giá và đánh giá.
2. **Quy trình đặt lịch**: Hướng dẫn chọn slot và đặt sân nhanh chóng.
3. **Thanh toán VietQR**: Hướng dẫn quét mã và xác nhận tự động.
4. **Giải đáp thắc mắc**: Chính sách hủy sân, hoàn tiền sự kiện, tiện ích bãi đỗ xe...

Dưới đây là một số sân thể thao nổi bật được yêu thích nhất hiện nay:
''';
      }

      quickReplies.addAll([
        "Sân Pickleball nào tốt nhất?",
        "Tìm sân Cầu lông giá hợp lý",
        "Hướng dẫn thanh toán VietQR",
        "Chính sách hủy sân và hoàn tiền?",
      ]);
    }

    return ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedVenues: suggestedVenues,
      quickReplies: quickReplies,
    );
  }
}
