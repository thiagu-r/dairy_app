// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/user.dart';
import '../config/api_config.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String get errorMessage => _errorMessage;
  
  // Token management
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  Timer? _tokenTimer;

  String? get token => _accessToken;
  bool get hasValidToken => _accessToken != null && 
    (_tokenExpiry?.isAfter(DateTime.now()) ?? false);

  AuthProvider() {
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    final authBox = Hive.box('authBox');
    final userData = authBox.get('userData');
    final accessToken = authBox.get('accessToken');
    
    if (userData != null && accessToken != null) {
      _currentUser = User.fromJson(json.decode(userData));
      _accessToken = accessToken;
      _refreshToken = authBox.get('refreshToken');
      final expiryString = authBox.get('tokenExpiry');
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }
      
      if (hasValidToken) {
        notifyListeners();
      } else {
        logout();
      }
    }
  }
  
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store tokens
        _accessToken = data['access'];  // Store the access token
        _refreshToken = data['refresh'];
        _tokenExpiry = DateTime.now().add(Duration(minutes: 55)); // Assuming 1-hour token validity
        _setupTokenExpiration();
        
        // Store user data
        if (data['user'] != null) {
          _currentUser = User.fromJson(data['user']);
          await _persistAuthData(data);
        }
        
        _isLoading = false;
        _errorMessage = '';
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      _errorMessage = 'Invalid credentials';
      notifyListeners();
      return false;
      
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Connection error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void _setupTokenExpiration() {
    _tokenTimer?.cancel();
    final timeToExpiry = _tokenExpiry?.difference(DateTime.now());
    if (timeToExpiry != null) {
      _tokenTimer = Timer(timeToExpiry, () {
        refreshToken();
      });
    }
  }
  
  Future<void> refreshToken() async {
    if (_refreshToken == null) {
      logout();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/token/refresh/'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'refresh': _refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access'];
        _tokenExpiry = DateTime.now().add(Duration(minutes: 55));
        _setupTokenExpiration();
        // Fix: Changed to _persistAuthData
        await _persistAuthData(data);
      } else {
        logout();
      }
    } catch (e) {
      logout();
    }
  }
  
  Future<void> _persistAuthData(Map<String, dynamic> data) async {
    final authBox = Hive.box('authBox');
    await authBox.put('userData', json.encode(data['user']));
    await authBox.put('accessToken', data['access']);  // Store the access token
    await authBox.put('refreshToken', data['refresh']);
    await authBox.put('tokenExpiry', _tokenExpiry?.toIso8601String());
  }
  
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _tokenTimer?.cancel();
    _tokenTimer = null;
    _currentUser = null;
    _errorMessage = '';
    
    final authBox = Hive.box('authBox');
    
    // Keep offline data in storage but mark user as logged out
    await authBox.put('isLoggedOut', true);
    
    // Don't clear these boxes as they might contain unsynced data
    // await Hive.box('loadingOrders').clear();
    // await Hive.box('deliveryOrders').clear();
    
    // Clear only authentication related data
    await authBox.delete('accessToken');
    await authBox.delete('refreshToken');
    await authBox.delete('tokenExpiry');
    await authBox.delete('userData');
    
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final authBox = Hive.box('authBox');
    final accessToken = authBox.get('accessToken');
    final refreshTokenValue = authBox.get('refreshToken');
    final expiryString = authBox.get('tokenExpiry');

    if (accessToken == null || refreshTokenValue == null || expiryString == null) {
      return false;
    }

    final expiry = DateTime.parse(expiryString);
    if (expiry.isBefore(DateTime.now())) {
      // Token expired, try to refresh
      _refreshToken = refreshTokenValue;
      await refreshToken();
      return hasValidToken;
    }

    _accessToken = accessToken;
    _refreshToken = refreshTokenValue;
    _tokenExpiry = expiry;
    _setupTokenExpiration();
    
    await checkAuthStatus();
    return hasValidToken;
  }
}
