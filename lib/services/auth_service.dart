/// Authentication service for managing user authentication
/// 
/// This service handles login, logout, token storage, and automatic
/// token refresh for the Kardiverse mobile application.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/auth_response.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();
  
  User? _currentUser;
  String? _currentToken;
  DateTime? _tokenExpiry;
  
  /// Get current authenticated user
  User? get currentUser => _currentUser;
  
  /// Get current authentication token
  String? get currentToken => _currentToken;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null && _currentToken != null && !_isTokenExpired;
  
  /// Check if current token is expired
  bool get _isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }
  
  /// Check if token will expire soon (within 5 minutes)
  bool get isTokenExpiringSoon {
    if (_tokenExpiry == null) return true;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(_tokenExpiry!);
  }
  
  /// Initialize authentication service
  Future<void> initialize() async {
    await _loadStoredAuth();
    await _checkTokenExpiry();
  }
  
  /// Load stored authentication data
  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      final expiryString = prefs.getString(_tokenExpiryKey);
      
      if (token != null && userJson != null) {
        _currentToken = token;
        _currentUser = User.fromJson(jsonDecode(userJson));
        
        if (expiryString != null) {
          _tokenExpiry = DateTime.parse(expiryString);
        }
      }
    } catch (e) {
      ApiConfig.logApiError('Load stored auth', e);
      await _clearStoredAuth();
    }
  }
  
  /// Store authentication data
  Future<void> _storeAuth(AuthResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (response.token != null) {
        await prefs.setString(_tokenKey, response.token!);
        _currentToken = response.token;
      }
      
      if (response.user != null) {
        await prefs.setString(_userKey, jsonEncode(response.user!.toJson()));
        _currentUser = response.user;
      }
      
      if (response.expiresAt != null) {
        await prefs.setString(_tokenExpiryKey, response.expiresAt!.toIso8601String());
        _tokenExpiry = response.expiresAt;
      }
    } catch (e) {
      ApiConfig.logApiError('Store auth', e);
    }
  }
  
  /// Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);
      
      _currentUser = null;
      _currentToken = null;
      _tokenExpiry = null;
    } catch (e) {
      ApiConfig.logApiError('Clear stored auth', e);
    }
  }
  
  /// Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      ApiConfig.logApiCall(ApiConfig.loginEndpoint, data: {'email': email, 'password': '***'});
      
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.connectionTimeout);
      
      ApiConfig.logApiResponse(ApiConfig.loginEndpoint, response.body);
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        if (authResponse.isSuccessful) {
          await _storeAuth(authResponse);
        }
        
        return authResponse;
      } else {
        final errorBody = jsonDecode(response.body);
        return AuthResponse.failure(
          message: errorBody['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      ApiConfig.logApiError(ApiConfig.loginEndpoint, e);
      return AuthResponse.failure(
        message: 'Network error: ${e.toString()}',
      );
    }
  }
  
  /// Logout current user
  Future<bool> logout() async {
    try {
      if (_currentToken != null) {
        // Try to call logout endpoint
        try {
          await http.post(
            Uri.parse(ApiConfig.logoutEndpoint),
            headers: {
              'Authorization': 'Bearer $_currentToken',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          // Ignore logout endpoint errors, continue with local cleanup
          ApiConfig.logApiError('Logout endpoint', e);
        }
      }
      
      // Clear local authentication data
      await _clearStoredAuth();
      return true;
    } catch (e) {
      ApiConfig.logApiError('Logout', e);
      return false;
    }
  }
  
  /// Refresh authentication token
  Future<bool> refreshToken() async {
    try {
      if (_currentToken == null) return false;
      
      ApiConfig.logApiCall(ApiConfig.refreshEndpoint);
      
      final response = await http.post(
        Uri.parse(ApiConfig.refreshEndpoint),
        headers: {
          'Authorization': 'Bearer $_currentToken',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.connectionTimeout);
      
      ApiConfig.logApiResponse(ApiConfig.refreshEndpoint, response.body);
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        if (authResponse.isSuccessful) {
          await _storeAuth(authResponse);
          return true;
        }
      }
      
      // If refresh failed, clear auth and return false
      await _clearStoredAuth();
      return false;
    } catch (e) {
      ApiConfig.logApiError('Refresh token', e);
      await _clearStoredAuth();
      return false;
    }
  }
  
  /// Check token expiry and refresh if needed
  Future<void> _checkTokenExpiry() async {
    if (_isTokenExpired) {
      if (_currentToken != null) {
        // Try to refresh token
        await refreshToken();
      }
    } else if (isTokenExpiringSoon) {
      // Proactively refresh token if expiring soon
      await refreshToken();
    }
  }
  
  /// Get authentication headers for API calls
  Map<String, String> getAuthHeaders() {
    if (_currentToken == null) return {};
    
    return {
      'Authorization': 'Bearer $_currentToken',
      'Accept': 'application/json',
    };
  }
  
  /// Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.hasRole(role) ?? false;
  }
  
  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    return _currentUser?.hasAnyRole(roles) ?? false;
  }
  
  /// Check if current user is admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  
  /// Get token expiry information
  String get tokenExpiryInfo {
    if (_tokenExpiry == null) return 'No expiry set';
    
    if (_isTokenExpired) return 'Expired';
    
    final timeLeft = _tokenExpiry!.difference(DateTime.now());
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }
  
  /// Force token refresh (for testing/debugging)
  Future<bool> forceRefreshToken() async {
    return await refreshToken();
  }
} 