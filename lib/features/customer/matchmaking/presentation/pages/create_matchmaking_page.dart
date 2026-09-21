import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/customer/home/presentation/providers/main_page_provider.dart';
import 'package:flexisport_app/features/customer/matchmaking/domain/entities/matchmaking_post.dart';
import 'package:flexisport_app/features/customer/matchmaking/presentation/providers/matchmaking_provider.dart';
import 'package:flexisport_app/features/auth/utils/validators.dart';

class CreateMatchmakingPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? initialBookingData;
  const CreateMatchmakingPage({
    super.key,
    required this.bookingId,
    this.initialBookingData,
  });

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

  static const double _maxCostPerPerson = 300000.0;

  double get _totalBookingAmount {
    final raw = _bookingData?['total_amount'] ??
        _bookingData?['total_price'] ??
        _bookingData?['amount'];
    return (raw as num?)?.toDouble() ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialBookingData != null) {
      _bookingData = widget.initialBookingData;
      _isBookingLoading = false;
    }
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    final bId = widget.bookingId.isNotEmpty
        ? widget.bookingId
        : (_bookingData?['id']?.toString() ?? '');

    if (bId.isEmpty) {
      if (mounted) setState(() => _isBookingLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select('''
            id,
            total_amount,
            booking_slots (
              booking_date,
              slot_index,
              courts (
                name,
                venues (
                  name,
                  sports_type,
                  open_time,
                  close_time
                )
              )
            )
          ''')
          .eq('id', bId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (response != null) {
            _bookingData = response;
          }
          _isBookingLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải thông tin đơn đặt cho kèo ghép: $e");
      if (mounted) {
        setState(() {
          _isBookingLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final clean = dateStr.split('T')[0].split(' ')[0].trim();
      final parts = clean.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        final d = parsed.day.toString().padLeft(2, '0');
        final m = parsed.month.toString().padLeft(2, '0');
        return '$d/$m/${parsed.year}';
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatIndicesToTimeRange(List<int> indices, {String openTime = '06:00'}) {
    if (indices.isEmpty) return '';
    int startHour = 6;
    int startMinute = 0;
    try {
      final parts = openTime.split(':');
      if (parts.isNotEmpty) startHour = int.tryParse(parts[0]) ?? 6;
      if (parts.length > 1) startMinute = int.tryParse(parts[1]) ?? 0;
    } catch (_) {}

    final startIdx = indices.first;
    final endIdx = indices.last;

    final startMinutesTotal = (startHour * 60 + startMinute) + startIdx * 30;
    final endMinutesTotal = (startHour * 60 + startMinute) + (endIdx + 1) * 30;

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
      final cleanCost = _costController.text.replaceAll('.', '').replaceAll(',', '').trim();
      final costPerPerson = double.tryParse(cleanCost) ?? 0.0;

      if (_totalBookingAmount > 0 && costPerPerson >= _totalBookingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Phí dự kiến (${MyValidators.formatCurrency(costPerPerson)}đ) phải nhỏ hơn phí đặt sân (${MyValidators.formatCurrency(_totalBookingAmount)}đ)!',
            ),
          ),
        );
        return;
      }

      if (costPerPerson > _maxCostPerPerson) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chi phí dự kiến không được vượt quá 300.000đ / người!'),
          ),
        );
        return;
      }

      final bId = widget.bookingId.isNotEmpty
          ? widget.bookingId
          : (_bookingData?['id']?.toString() ?? '');

      final newPost = MatchmakingPost(
        id: '', // Supabase tự tạo UUID
        bookingId: bId,
        hostId: currentUserId,
        slotsNeeded: _slotsNeeded,
        slotsAvailable: _slotsNeeded,
        targetLevel: _selectedLevel,
        estimatedCostPerPerson: costPerPerson,
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

  String? _buildCostHelperText() {
    final clean = _costController.text.replaceAll('.', '').replaceAll(',', '').trim();
    if (clean.isEmpty || clean == '0') {
      return 'Kèo miễn phí cho người tham gia';
    }
    final val = double.tryParse(clean);
    if (val != null) {
      if (_totalBookingAmount > 0 && val >= _totalBookingAmount) {
        return 'Phí dự kiến phải nhỏ hơn phí đặt sân (${MyValidators.formatCurrency(_totalBookingAmount)} VNĐ)';
      }
      if (val > _maxCostPerPerson) {
        return 'Vượt quá mức chi phí tối đa cho phép (300.000 VNĐ)';
      }
      if (val >= 1000) {
        return 'Tương đương: ${MyValidators.formatCurrency(val)} VNĐ / người';
      }
    }
    return null;
  }

  Widget _buildQuickPriceChip(String label, String value) {
    final cleanCurrent = _costController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final isSelected = cleanCurrent == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        labelStyle: GoogleFonts.lexend(
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.primaryContainer,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        backgroundColor: isSelected
            ? AppColors.primaryContainer
            : AppColors.primaryContainer.withValues(alpha: 0.08),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.primaryContainer.withValues(alpha: 0.25),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          setState(() {
            _costController.text = value;
          });
          _formKey.currentState?.validate();
        },
      ),
    );
  }

  List<Widget> _buildQuickChips() {
    final chips = <Widget>[
      _buildQuickPriceChip('0đ (Miễn phí)', '0'),
    ];

    if (_totalBookingAmount > 0) {
      final rawSplit = _totalBookingAmount / (_slotsNeeded + 1);
      final split = (rawSplit / 1000).floor() * 1000;
      final cappedSplit = split > _maxCostPerPerson.toInt()
          ? _maxCostPerPerson.toInt()
          : split;
      if (cappedSplit > 0 && cappedSplit < _totalBookingAmount) {
        chips.add(
          _buildQuickPriceChip(
            'Chia đều (${MyValidators.formatCurrency(cappedSplit.toDouble())}đ)',
            cappedSplit.toString(),
          ),
        );
      }
    }

    final defaultAmounts = [
      30000,
      50000,
      100000,
      200000,
      300000,
    ];

    for (final amt in defaultAmounts) {
      final isLessThanBooking = _totalBookingAmount <= 0 || amt < _totalBookingAmount;
      final isWithinMax = amt <= _maxCostPerPerson;
      if (isLessThanBooking && isWithinMax) {
        final label = amt == 300000
            ? '300.000đ (Tối đa)'
            : '${MyValidators.formatCurrency(amt.toDouble())}đ';
        chips.add(_buildQuickPriceChip(label, amt.toString()));
      }
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final slots = _bookingData?['booking_slots'] as List? ?? [];
    String sportTypeStr = '';
    if (slots.isNotEmpty) {
      final firstSlot = slots.first;
      sportTypeStr = firstSlot['courts']?['venues']?['sports_type']?.toString() ?? '';
    }

    int maxSlots = 20;
    if (sportTypeStr == 'Cầu lông' || sportTypeStr == 'Pickleball' || sportTypeStr == 'Tennis' || sportTypeStr == 'Golf') {
      maxSlots = 10;
    } else if (sportTypeStr == 'Bóng rổ') {
      maxSlots = 15;
    } else if (sportTypeStr == 'Bóng chuyền') {
      maxSlots = 18;
    } else if (sportTypeStr == 'Bóng đá') {
      maxSlots = 25;
    }

    if (_slotsNeeded > maxSlots) {
      _slotsNeeded = maxSlots;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryContainer, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
        title: Text(
          "Mở kèo ghép sân",
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isBookingLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
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
                        Text(
                          'Số lượng người cần tuyển thêm:',
                          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (sportTypeStr.isNotEmpty)
                          Text(
                            '(Tối đa $maxSlots người)',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _slotsNeeded > 1 
                                ? () => setState(() => _slotsNeeded--) 
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline_rounded,
                              color: _slotsNeeded > 1 ? AppColors.primaryContainer : Colors.grey.shade400,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$_slotsNeeded',
                              style: GoogleFonts.lexend(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _slotsNeeded < maxSlots
                                ? () => setState(() => _slotsNeeded++)
                                : null,
                            icon: Icon(
                              Icons.add_circle_outline_rounded,
                              color: _slotsNeeded < maxSlots ? AppColors.primaryContainer : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Trình độ mong muốn
                    Text(
                      'Trình độ yêu cầu:',
                      style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _levels.map((level) {
                        final isSelected = _selectedLevel == level;
                        return ChoiceChip(
                          label: Text(
                            level,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryContainer,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : AppColors.outlineVariant.withValues(alpha: 0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedLevel = level;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Chi phí dự kiến chia đầu người
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Chi phí dự kiến (VNĐ / người):',
                              style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _totalBookingAmount > 0 && _totalBookingAmount <= _maxCostPerPerson
                                  ? '(< ${MyValidators.formatCurrency(_totalBookingAmount)}đ)'
                                  : '(Tối đa 300k)',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        if (_costController.text.trim() == '0' || _costController.text.trim().isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Miễn phí',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) {
                        setState(() {});
                      },
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: _totalBookingAmount > 0
                            ? 'Nhập số tiền (< ${MyValidators.formatCurrency(_totalBookingAmount)}đ)'
                            : 'Nhập số tiền (tối đa 300.000 VNĐ)',
                        hintStyle: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.8),
                        ),
                        prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.primaryContainer),
                        suffixText: 'VNĐ',
                        suffixStyle: GoogleFonts.lexend(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryContainer,
                        ),
                        helperText: _buildCostHelperText(),
                        helperStyle: TextStyle(
                          color: (_costController.text.isNotEmpty &&
                                  double.tryParse(_costController.text.replaceAll('.', '').replaceAll(',', '')) != null &&
                                  ((_totalBookingAmount > 0 &&
                                          (double.tryParse(_costController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0) >= _totalBookingAmount) ||
                                      (double.tryParse(_costController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0) > _maxCostPerPerson))
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số tiền (hoặc ghi 0 nếu miễn phí)';
                        }
                        final cleanValue = value.replaceAll('.', '').replaceAll(',', '').trim();
                        final parsed = double.tryParse(cleanValue);
                        if (parsed == null) {
                          return 'Vui lòng nhập số tiền hợp lệ';
                        }
                        if (parsed < 0) {
                          return 'Chi phí không được là số âm';
                        }
                        if (parsed > 0 && parsed < 1000) {
                          return 'Chi phí tối thiểu từ 1.000đ (hoặc 0 nếu miễn phí)';
                        }
                        if (_totalBookingAmount > 0 && parsed >= _totalBookingAmount) {
                          return 'Phí dự kiến phải nhỏ hơn phí đặt sân (${MyValidators.formatCurrency(_totalBookingAmount)}đ)';
                        }
                        if (parsed > _maxCostPerPerson) {
                          return 'Chi phí dự kiến tối đa không quá 300.000đ / người';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _buildQuickChips(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lời nhắn nhắn gửi
                    Text(
                      'Lời nhắn của bạn:',
                      style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      style: GoogleFonts.lexend(fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Mô tả thêm về kèo đấu, nước uống, hoặc tính chất trận đấu...',
                        hintStyle: GoogleFonts.lexend(fontSize: 13, color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nút Đăng kèo
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryContainer, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Đăng Kèo Ghép',
                          style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold),
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
    String openTime = '06:00';

    if (slots.isNotEmpty) {
      final firstSlot = slots.first;
      final courtName = firstSlot['courts']?['name']?.toString() ?? 'Sân';
      final venue = firstSlot['courts']?['venues'];
      final venueName = venue?['name']?.toString() ?? 'Tổ hợp thể thao';
      sportTypeStr = venue?['sports_type']?.toString() ?? '';
      openTime = venue?['open_time']?.toString() ?? '06:00';
      venueAndCourt = '$venueName - $courtName';

      final rawDate = firstSlot['booking_date']?.toString() ?? '';
      final date = _formatDate(rawDate);
      final List<int> indices = slots
          .map((s) => (s['slot_index'] as num?)?.toInt() ?? 0)
          .toList()
        ..sort();
      final rangeStr = _formatIndicesToTimeRange(indices, openTime: openTime);
      timeStr = date.isNotEmpty ? '$date | $rangeStr' : rangeStr;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.stadium_rounded, size: 16, color: AppColors.primaryContainer),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SÂN ĐANG MỞ KÈO GHÉP',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primaryContainer,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (sportTypeStr.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_tennis_rounded, size: 13, color: AppColors.primaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        sportTypeStr,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            venueAndCourt,
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.outline),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timeStr,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_totalBookingAmount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16, color: AppColors.primaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Phí đặt sân:',
                        style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  Text(
                    '${MyValidators.formatCurrency(_totalBookingAmount)} VNĐ',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
