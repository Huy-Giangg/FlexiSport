import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final url = 'https://xespfyhsjmfglktpsqxk.supabase.co/rest/v1/venues';
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.add('apikey', 'sb_publishable_Tz2LMObapxx6UFwRgd8yfg_Xq1vVk9d');
    request.headers.add('Authorization', 'Bearer sb_publishable_Tz2LMObapxx6UFwRgd8yfg_Xq1vVk9d');
    request.headers.add('Content-Type', 'application/json');
    request.headers.add('Prefer', 'return=representation');
    
    final payload = {
      'name': 'Test Sân Mới 2026',
      'address': 'Số 15 Hoàng Hoa Thám, Ba Đình, Hà Nội',
      'open_time': '06:00',
      'close_time': '22:00',
      'rating': 5.0,
      'latitude': 21.0285,
      'longitude': 105.8542,
      'is_active': true,
      'sports_type': 'Pickleball',
    };
    request.write(jsonEncode(payload));
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    print('HTTP Status: ${response.statusCode}');
    print('Response: $body');
  } catch (e) {
    print('Exception: $e');
  }
  client.close();
}
