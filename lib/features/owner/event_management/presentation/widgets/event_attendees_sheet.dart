import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.fetchAttendees(widget.event.id);
    });
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

  @override
  Widget build(BuildContext context) {
    final attendees = widget.provider.attendees;
    final isLoading = widget.provider.isLoadingAttendees;

    final filteredAttendees = attendees.where((a) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return a.customerName.toLowerCase().contains(q) ||
          a.customerPhone.toLowerCase().contains(q);
    }).toList();

    final totalTickets = attendees.fold<int>(0, (sum, a) => sum + a.ticketCount);
    final totalRevenue = attendees.fold<double>(0.0, (sum, a) => sum + a.totalAmount);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                            widget.event.title,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.lexend(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Tìm kiếm theo tên hoặc số điện thoại...",
                hintStyle: GoogleFonts.lexend(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

          // Content List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredAttendees.isEmpty
                    ? Center(
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
                                    : "Không tìm thấy kết quả phù hợp",
                                style: GoogleFonts.lexend(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredAttendees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final attendee = filteredAttendees[index];
                          return _buildAttendeeItem(attendee);
                        },
                      ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(fontSize: 10, color: color, fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeItem(OwnerEventAttendeeEntity attendee) {
    final initial = attendee.customerName.trim().isNotEmpty
        ? attendee.customerName.trim()[0].toUpperCase()
        : 'K';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLightBg,
            child: Text(
              initial,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.customerName,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.onBackground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      attendee.customerPhone,
                      style: GoogleFonts.lexend(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (attendee.note != null && attendee.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Ghi chú: ${attendee.note}",
                      style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                    fontSize: 11,
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
            ],
          ),
        ],
      ),
    );
  }
}
