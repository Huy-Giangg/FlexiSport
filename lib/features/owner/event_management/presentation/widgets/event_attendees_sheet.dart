import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/event_management/domain/entities/owner_event_attendee_entity.dart';
import 'package:flexisport_app/features/owner/event_management/domain/entities/owner_event_entity.dart';
import 'package:flexisport_app/features/owner/event_management/presentation/providers/owner_event_provider.dart';

class EventAttendeesSheet extends StatefulWidget {
  final OwnerEventEntity event;
  final OwnerEventProvider provider;

  const EventAttendeesSheet({
    super.key,
    required this.event,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    required OwnerEventEntity event,
    required OwnerEventProvider provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EventAttendeesSheet(
        event: event,
        provider: provider,
      ),
    );
  }

  @override
  State<EventAttendeesSheet> createState() => _EventAttendeesSheetState();
}

class _EventAttendeesSheetState extends State<EventAttendeesSheet> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'all'; // 'all', 'completed', 'used', 'pending', 'cancelled'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.fetchAttendees(widget.event.id);
    });
  }

  @override
  void dispose() {
    widget.provider.clearViewingEvent();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }

  String _formatDate(String dateStr) {
    try {
      final clean = dateStr.split('T')[0].split(' ')[0].trim();
      final parts = clean.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$h:$min - $d/$m/$y";
  }

  (String?, String) _parseNote(String? rawNote) {
    if (rawNote == null || rawNote.trim().isEmpty) return (null, '');
    final match = RegExp(r'\[?Mã GD:\s*([A-Za-z0-9_]+)\]?').firstMatch(rawNote);
    if (match != null) {
      final txCode = match.group(1);
      final clean = rawNote.replaceAll(match.group(0)!, '').trim();
      return (txCode, clean);
    }
    return (null, rawNote.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final attendees = widget.provider.attendees;
        final isLoading = widget.provider.isLoadingAttendees;

        // Lọc theo từ khóa tìm kiếm & trạng thái
        final filteredAttendees = attendees.where((a) {
          // Lọc trạng thái
          if (_selectedStatusFilter != 'all') {
            final st = a.status.toLowerCase().trim();
            if (_selectedStatusFilter == 'completed' && st != 'completed' && st != 'paid') return false;
            if (_selectedStatusFilter == 'used' && st != 'used') return false;
            if (_selectedStatusFilter == 'pending' && st != 'pending') return false;
            if (_selectedStatusFilter == 'cancelled' && st != 'cancelled' && st != 'canceled') return false;
          }

          // Lọc tìm kiếm
          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.toLowerCase().trim();
            final matchName = a.customerName.toLowerCase().contains(q);
            final matchPhone = a.customerPhone.toLowerCase().contains(q);
            final matchId = a.id.toLowerCase().contains(q);
            return matchName || matchPhone || matchId;
          }
          return true;
        }).toList();

        final nonCancelled = attendees.where((a) => a.status != 'cancelled' && a.status != 'canceled').toList();
        final totalTickets = nonCancelled.fold<int>(0, (sum, a) => sum + a.ticketCount);
        final totalRevenue = nonCancelled.fold<double>(0.0, (sum, a) => sum + a.totalAmount);
        final checkedInCount = attendees.where((a) => a.status == 'used').length;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.people_alt_rounded, color: Color(0xFF0288D1), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Danh sách người tham gia",
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              Text(
                                "${widget.event.title} • ${widget.event.courtName}",
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: "Làm mới",
                          onPressed: () => widget.provider.fetchAttendees(widget.event.id),
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Metrics Summary Strip
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: "Vé đã bán",
                            value: "$totalTickets / ${widget.event.maxTickets}",
                            icon: Icons.confirmation_number_rounded,
                            color: const Color(0xFF0288D1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            title: "Đã check-in",
                            value: "$checkedInCount lượt",
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF00897B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            title: "Doanh thu",
                            value: _formatCurrency(totalRevenue),
                            icon: Icons.payments_rounded,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.lexend(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm theo tên, số điện thoại, mã vé...",
                    hintStyle: GoogleFonts.lexend(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả (${attendees.length})'),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'completed',
                      'Đã thanh toán (${attendees.where((a) => a.status == 'completed' || a.status == 'paid').length})',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'used',
                      'Đã check-in (${attendees.where((a) => a.status == 'used').length})',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'pending',
                      'Chờ TT (${attendees.where((a) => a.status == 'pending').length})',
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'cancelled',
                      'Đã hủy (${attendees.where((a) => a.status == 'cancelled' || a.status == 'canceled').length})',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Content List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: () => widget.provider.fetchAttendees(widget.event.id),
                        child: filteredAttendees.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade300),
                                          const SizedBox(height: 10),
                                          Text(
                                            attendees.isEmpty
                                                ? "Chưa có người đăng ký tham gia sự kiện này"
                                                : "Không tìm thấy người tham gia phù hợp",
                                            style: GoogleFonts.lexend(fontSize: 14, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                itemCount: filteredAttendees.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (ctx, index) {
                                  final attendee = filteredAttendees[index];
                                  return _buildAttendeeItem(attendee);
                                },
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedStatusFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006D38) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF006D38) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lexend(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeItem(OwnerEventAttendeeEntity attendee) {
    final initial = attendee.customerName.trim().isNotEmpty
        ? attendee.customerName.trim()[0].toUpperCase()
        : 'K';

    String statusText = 'Chờ TT';
    Color statusBg = const Color(0xFFFFF3CD);
    Color statusColor = const Color(0xFF856404);

    if (attendee.status == 'completed' || attendee.status == 'paid') {
      statusText = 'ĐÃ TT';
      statusBg = const Color(0xFFD4EDDA);
      statusColor = const Color(0xFF155724);
    } else if (attendee.status == 'used') {
      statusText = 'CHECK-IN';
      statusBg = const Color(0xFFE0F2FE);
      statusColor = const Color(0xFF0288D1);
    } else if (attendee.status == 'cancelled' || attendee.status == 'canceled') {
      statusText = 'ĐÃ HỦY';
      statusBg = const Color(0xFFF8D7DA);
      statusColor = const Color(0xFF721C24);
    }

    final shortId = attendee.id.length >= 8 ? attendee.id.substring(0, 8).toUpperCase() : attendee.id.toUpperCase();
    final (txCode, _) = _parseNote(attendee.note);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () => _showAttendeeDetailModal(attendee),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            attendee.customerName,
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: GoogleFonts.lexend(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          attendee.customerPhone,
                          style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "#$shortId",
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            color: const Color(0xFF006D38),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (txCode != null && txCode.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "Mã GD: $txCode",
                          style: GoogleFonts.lexend(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${attendee.ticketCount} vé",
                      style: GoogleFonts.lexend(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(attendee.totalAmount),
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hộp thoại xem chi tiết vé & thao tác Check-in của chủ sân
  void _showAttendeeDetailModal(OwnerEventAttendeeEntity attendee) {
    final (txCode, cleanNote) = _parseNote(attendee.note);
    final shortId = attendee.id.length >= 8 ? attendee.id.substring(0, 8).toUpperCase() : attendee.id.toUpperCase();

    String statusText = 'Chờ thanh toán';
    Color statusBg = const Color(0xFFFFF3CD);
    Color statusColor = const Color(0xFF856404);

    if (attendee.status == 'completed' || attendee.status == 'paid') {
      statusText = 'ĐÃ THANH TOÁN (HỢP LỆ)';
      statusBg = const Color(0xFFD4EDDA);
      statusColor = const Color(0xFF155724);
    } else if (attendee.status == 'used') {
      statusText = 'ĐÃ CHECK-IN (VÀO SÂN)';
      statusBg = const Color(0xFFE0F2FE);
      statusColor = const Color(0xFF0288D1);
    } else if (attendee.status == 'cancelled' || attendee.status == 'canceled') {
      statusText = 'ĐÃ HỦY VÉ';
      statusBg = const Color(0xFFF8D7DA);
      statusColor = const Color(0xFF721C24);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Thông tin vé tham gia",
                          style: GoogleFonts.lexend(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Event Summary Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6FAF7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EFE7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF006D38),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.event.courtName,
                                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.event.startTime} - ${widget.event.endTime} | Ngày: ${_formatDate(widget.event.eventDate)}",
                                style: GoogleFonts.lexend(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Customer Details
                    _buildModalInfoRow("Khách hàng", attendee.customerName, isBold: true),
                    _buildModalInfoRow(
                      "Số điện thoại",
                      attendee.customerPhone,
                      trailingWidget: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: attendee.customerPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Đã sao chép số điện thoại!")),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.copy_rounded, size: 14, color: Color(0xFF006D38)),
                        ),
                      ),
                    ),
                    _buildModalInfoRow("Số lượng vé", "${attendee.ticketCount} vé", isBold: true),
                    _buildModalInfoRow(
                      "Mã đặt vé",
                      "#$shortId",
                      valueColor: const Color(0xFF006D38),
                      isBold: true,
                    ),
                    if (txCode != null && txCode.isNotEmpty)
                      _buildModalInfoRow(
                        "Mã giao dịch",
                        txCode,
                        valueColor: Colors.deepOrange,
                        isBold: true,
                      ),
                    if (cleanNote.isNotEmpty)
                      _buildModalInfoRow("Ghi chú", cleanNote),
                    _buildModalInfoRow("Thời gian đặt", _formatDateTime(attendee.createdAt)),

                    // Total Amount Card
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD3E7DC)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tổng thanh toán",
                            style: GoogleFonts.lexend(fontSize: 13, color: Colors.black54),
                          ),
                          Text(
                            _formatCurrency(attendee.totalAmount),
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF006D38),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Actions
                    if (attendee.status == 'completed' || attendee.status == 'paid') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006D38),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            Navigator.of(modalCtx).pop();
                            final ok = await widget.provider.updateAttendeeStatus(attendee.id, 'used');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok ? "Đã xác nhận Check-in cho ${attendee.customerName}!" : "Không thể cập nhật trạng thái.",
                                ),
                                backgroundColor: ok ? const Color(0xFF2E7D32) : Colors.redAccent,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: Text(
                            "XÁC NHẬN CHECK-IN (ĐÃ ĐẾN SÂN)",
                            style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ] else if (attendee.status == 'pending') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            Navigator.of(modalCtx).pop();
                            final ok = await widget.provider.updateAttendeeStatus(attendee.id, 'completed');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok ? "Đã xác nhận thanh toán cho ${attendee.customerName}!" : "Không thể cập nhật trạng thái.",
                                ),
                                backgroundColor: ok ? const Color(0xFF2E7D32) : Colors.redAccent,
                              ),
                            );
                          },
                          icon: const Icon(Icons.payments_outlined, size: 20),
                          label: Text(
                            "XÁC NHẬN ĐÃ THU TIỀN TẠI SÂN",
                            style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ] else if (attendee.status == 'used') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFB3E5FC)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF0288D1), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Khách đã hoàn tất Check-in vào sân",
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0288D1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(modalCtx).pop(),
                        child: Text("ĐÓNG", style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalInfoRow(String label, String value, {Color? valueColor, bool isBold = false, Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: GoogleFonts.lexend(fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: valueColor ?? Colors.black87,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                ?trailingWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
