import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final tables = [
    'prices',
    'pricing',
    'court_price',
    'court_prices',
    'stadium_prices',
    'stadium_price',
    'booking',
    'bookings',
    'slots',
    'time_slots',
    'schedules',
    'schedule',
    'venue_prices',
    'sport_type_prices'
  ];
  
  for (var table in tables) {
    final url = 'https://xespfyhsjmfglktpsqxk.supabase.co/rest/v1/$table?limit=1';
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.add('apikey', 'sb_publishable_Tz2LMObapxx6UFwRgd8yfg_Xq1vVk9d');
      request.headers.add('Authorization', 'Bearer sb_publishable_Tz2LMObapxx6UFwRgd8yfg_Xq1vVk9d');
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        print('Table exists: $table (Status 200)');
        print('Sample data: $body');
      } else {
        final decoded = jsonDecode(body);
        final message = decoded['message'] ?? '';
        if (!message.toString().contains('does not exist') && !message.toString().contains('not found')) {
          print('Table exists or has different error: $table (Status ${response.statusCode}) -> $message');
        }
      }
    } catch (e) {
      // Ignore
    }
  }
  client.close();
}
