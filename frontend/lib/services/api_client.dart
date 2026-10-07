import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiClient {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _headers();
    try {
      final response = await http.get(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: Unable to connect to server ($e)');
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _headers();
    try {
      final response = await http.post(url, headers: headers, body: jsonEncode(body));
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: Unable to connect to server ($e)');
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _headers();
    try {
      final response = await http.put(url, headers: headers, body: jsonEncode(body));
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: Unable to connect to server ($e)');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _headers();
    try {
      final response = await http.delete(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: Unable to connect to server ($e)');
    }
  }

  static dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else if (statusCode == 401) {
      throw Exception(body['message'] ?? 'Unauthorized session. Please login again.');
    } else if (statusCode == 403) {
      throw Exception(body['message'] ?? 'Forbidden: You do not have permission for this action.');
    } else if (statusCode == 404) {
      throw Exception(body['message'] ?? 'Resource not found.');
    } else {
      throw Exception(body['message'] ?? 'Server error ($statusCode). Please try again.');
    }
  }
}
