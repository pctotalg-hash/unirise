import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String get role => (_currentUser?.role ?? 'student').toLowerCase();

  AuthService() {
    initAuth();
  }

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userJsonStr = prefs.getString('user_data');
      if (_token != null && userJsonStr != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJsonStr));
        await fetchMe();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      _token = res['token'];
      final userObj = res['user'] ?? res;
      _currentUser = UserModel.fromJson(userObj);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(userObj));
      await prefs.setString('user_role', _currentUser!.role);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMe() async {
    try {
      final res = await ApiClient.get('/auth/me');
      _currentUser = UserModel.fromJson(res);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(res));
      await prefs.setString('user_role', _currentUser!.role);
      notifyListeners();
    } catch (e) {
      debugPrint('FetchMe error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {}
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('user_role');
    notifyListeners();
  }
}
