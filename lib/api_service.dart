import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<String> sendMessage(String message) async {
    final url = Uri.parse('$baseUrl/chat');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'message': message,
      'history': [],
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['answer'];
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  }
}
