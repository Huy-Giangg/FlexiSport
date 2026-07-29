import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/matchmaking/presentation/providers/matchmaking_provider.dart';

class CreateMatchmakingPage extends StatefulWidget {
  final String bookingId; // Booking ID liên kết
  const CreateMatchmakingPage({super.key, required this.bookingId});

  @override
  State<CreateMatchmakingPage> createState() => _CreateMatchmakingPageState();
}

class _CreateMatchmakingPageState extends State<CreateMatchmakingPage> {
  final _formKey = GlobalKey<FormState>();
  int _slotsNeeded = 2;
  String _selectedLevel = 'Trung bình';
  final List<String> _levels = ['Mới chơi', 'Trung bình', 'Khá', 'Chuyên nghiệp'];
  final _costController = TextEditingController(text: '0');
  final _messageController = TextEditingController();

  Map<String, dynamic>? _bookingData;
  bool _isBookingLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select('''
            id,
            booking_slots (
              booking_date,
              slot_index,
              courts (
                name,
                venues (
                  name,
                  sports_type
                )
              )
            )
          ''')
          .eq('id', widget.bookingId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _bookingData = response;
          _isBookingLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookingLoading = false;
        });
      }
    }
  }

  String _formatIndicesToTimeRange(List<int> indices) {
    if (indices.isEmpty) return '';
    const startHour = 6;
    final startIdx = indices.first;
    final endIdx = indices.last;

    final startMinutesTotal = startHour * 60 + startIdx * 30;
    final endMinutesTotal = startHour * 60 + (endIdx + 1) * 30;

    final startH = startMinutesTotal ~/ 60;
    final startM = startMinutesTotal % 60;
    final endH = endMinutesTotal ~/ 60;
    final endM = endMinutesTotal % 60;

    final startStr = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
    final endStr = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
    
    return '$startStr - $endStr';
  }

  @override
  void dispose() {
    _costController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để mở kèo ghép!')),
      );
      final mainPageProvider = context.read<MainPageProvider>();
      mainPageProvider.hideNavbar();
      context.push('/login').then((_) {
        mainPageProvider.showNavbar();
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      final newPost = MatchmakingPost(
        id: '', // Supabase tự tạo UUID
        bookingId: widget.bookingId,
        hostId: currentUserId,
        slotsNeeded: _slotsNeeded,
        slotsAvailable: _slotsNeeded,
        targetLevel: _selectedLevel,
        estimatedCostPerPerson: double.tryParse(_costController.text) ?? 0.0,
        message: _messageController.text.trim(),
        status: 'open',
        createdAt: DateTime.now(),
      );

      context.read<MatchmakingProvider>().createPost(newPost).then((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng kèo ghép thành công!')),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Xác định môn thể thao từ dữ liệu booking slots
    final slots = _bookingData?['booking_slots'] as List? ?? [];
    String sportTypeStr = '';
    if (slots.isNotEmpty) {
      final firstSlot = slots.first;
      sportTypeStr = firstSlot['courts']?['venues']?['sports_type'] ?? '';
    }

    // Thiết lập số người tối đa tùy theo từng bộ môn (Phương án B)
    int maxSlots = 20; // Giá trị mặc định mặc định
    if (sportTypeStr == 'Cầu lông' || sportTypeStr == 'Pickleball' || sportTypeStr == 'Tennis' || sportTypeStr == 'Golf') {
      maxSlots = 10;
    } else if (sportTypeStr == 'Bóng rổ') {
      maxSlots = 15;
    } else if (sportTypeStr == 'Bóng chuyền') {
      maxSlots = 18;
    } else if (sportTypeStr == 'Bóng đá') {
      maxSlots = 25;
    }

    // Đảm bảo slotsNeeded hiện tại không vượt quá giới hạn mới (nếu có cập nhật động)
    if (_slotsNeeded > maxSlots) {
      _slotsNeeded = maxSlots;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D38),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: const Text(
          "Mở kèo ghép sân",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isBookingLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingInfoCard(),
              const SizedBox(height: 24),

              // Số lượng cần tuyển
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Số lượng người cần tuyển thêm:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (sportTypeStr.isNotEmpty)
                    Text(
                      '(Tối đa $maxSlots người)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _slotsNeeded > 1 
                        ? () => setState(() => _slotsNeeded--) 
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_slotsNeeded',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _slotsNeeded < maxSlots
                        ? () => setState(() => _slotsNeeded++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Trình độ mong muốn
              const Text(
                'Trình độ yêu cầu:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _levels.map((level) {
                  final isSelected = _selectedLevel == level;
                  return ChoiceChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedLevel = level;
                        });
                      }
                    },
                    selectedColor: Colors.green.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Chi phí dự kiến chia đầu người
              const Text(
                'Chi phí dự kiến (VND / người):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Nhập số tiền (ví dụ: 50000)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền hoặc ghi 0 nếu miễn phí';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Lời nhắn nhắn gửi
              const Text(
                'Lời nhắn của bạn:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Mô tả thêm về kèo đấu, nước uống, hoặc tính chất trận đấu...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Nút Đăng kèo
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Đăng Kèo Ghép',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    final slots = _bookingData?['booking_slots'] as List? ?? [];
    String venueAndCourt = 'Chưa xác định sân';
    String timeStr = 'Chưa xác định thời gian';
    String sportTypeStr = '';
    if (slots.isNotEmpty) {
      final firstSlot = slots.first;
      final courtName = firstSlot['courts']?['name'] ?? 'Sân';
      final venueName = firstSlot['courts']?['venues']?['name'] ?? 'Tổ hợp sân';
      sportTypeStr = firstSlot['courts']?['venues']?['sports_type'] ?? '';
      venueAndCourt = '$venueName - $courtName';
      
      final date = firstSlot['booking_date'] ?? '';
      final List<int> indices = slots.map((s) => s['slot_index'] as int? ?? 0).toList()..sort();
      final rangeStr = _formatIndicesToTimeRange(indices);
      timeStr = '$date | $rangeStr';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sân đang ghép:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              if (sportTypeStr.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sportTypeStr,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(venueAndCourt, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Thời gian: $timeStr'),
        ],
      ),
    );
  }
}
