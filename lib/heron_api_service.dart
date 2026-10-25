
import 'dart:convert';
import 'package:http/http.dart' as http;

class HeronApiService {
  // Android emulator: use 10.0.2.2 to reach your computer.
  // If testing on a physical phone, replace this with your computer's
  // local network IP address.
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Replace this placeholder with the SAME API key configured in
  // backend/.env as HERON_API_KEY. Never share that key publicly.
  static const String apiKey = 'REPLACE_WITH_YOUR_HERON_API_KEY';

  static Future<bool> sendEmergencyAlert({
    required String reason,
    required List<String> trustedContactChatIds,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/alert');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: jsonEncode({
        'reason': reason,
        'trusted_contact_chat_ids': trustedContactChatIds,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(
      'Emergency alert failed (${response.statusCode}): ${response.body}',
    );
  }
}
