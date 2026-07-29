import 'package:flexisport_app/features/booking/presentation/providers/booking_provider.dart';
import 'package:flexisport_app/features/home/presentation/providers/main_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EventBookingPage extends StatefulWidget {
  final String venueId;
  const EventBookingPage({super.key, this.venueId = ''});

  @override
  State<EventBookingPage> createState() => _EventBookingPageState();
}

class _EventBookingPageState extends State<EventBookingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BookingProvider>().loadEvents(widget.venueId);
      }
    });
  }

  String _formatVND(double amount) {
    final String str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return "${buffer.toString()}đ";
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('T')[0].split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF006D38),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D38),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.read<MainPageProvider>().showNavbar();
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          "Đặt lịch sự kiện",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              bookingProvider.loadEvents(widget.venueId);
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : bookingProvider.events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy, color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    widget.venueId.isNotEmpty
                        ? "Không có sự kiện nào tại cơ sở này!"
                        : "Hiện tại chưa có sự kiện nào!",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: bookingProvider.events.length,
              itemBuilder: (context, index) {
                final event = bookingProvider.events[index];
                final bookedCount =
                    bookingProvider.eventBookedTicketsCount[event.id] ?? 0;
                final isFull = bookedCount >= event.maxTickets;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF008F4A),
                        const Color(0xFF005F31).withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16.0,
                            bottom: 72,
                            right: 16,
                            left: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        color: Color(0xFFFFEC88),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(event.eventDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${event.startTime} - ${event.endTime} | ${event.courtName}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF33A56E),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.sports_tennis_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          event.sportType,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3A8DEE),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            event.level,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    color: Colors.white70,
                                    iconSize: 20,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(
                                            0xFF005F31,
                                          ),
                                          title: Text(
                                            event.title,
                                            style: const TextStyle(
                                              color: Color(0xFFFFEC88),
                                            ),
                                          ),
                                          content: Text(
                                            event.description,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                "ĐÓNG",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.info_outline),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFull
                                          ? Colors.redAccent.withOpacity(0.8)
                                          : const Color(0xFF33A56E),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      isFull
                                          ? "Hết vé: ${event.maxTickets}/${event.maxTickets}"
                                          : "Vé đã bán: $bookedCount/${event.maxTickets}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 1,
                                        color: const Color(0xFFFFEC88),
                                      ),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      "${_formatVND(event.ticketPrice)}/Vé",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFFFFEC88),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: () {
                              if (isFull) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Sự kiện này đã hết vé!"),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              } else {
                                context.push(
                                  '/EventBookingDetailPage',
                                  extra: {
                                    'event': event,
                                    'bookedCount': bookedCount,
                                  },
                                );
                              }
                            },
                            child: Container(
                              width: 56.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: isFull
                                    ? Colors.grey
                                    : const Color(0xFF33A56E),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16.0),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_outlined,
                                color: Colors.white,
                                size: 24.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
