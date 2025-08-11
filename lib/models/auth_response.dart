/// Authentication response model for login operations
/// 
/// This model represents the response from the authentication API,
/// including user information, authentication token, and response status.
import 'user.dart';

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;
  final String? tokenType;
  final DateTime? expiresAt;

  const AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.tokenType,
    this.expiresAt,
  });

  /// Create AuthResponse from JSON response
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      user: json['data']?['user'] != null 
          ? User.fromJson(json['data']['user'] as Map<String, dynamic>)
          : null,
      token: json['data']?['token'] as String?,
      tokenType: json['data']?['token_type'] as String?,
      expiresAt: json['data']?['expires_at'] != null
          ? DateTime.parse(json['data']['expires_at'] as String)
          : null,
    );
  }

  /// Create AuthResponse for successful login
  factory AuthResponse.success({
    required String message,
    required User user,
    required String token,
    String tokenType = 'Bearer',
    DateTime? expiresAt,
  }) {
    return AuthResponse(
      success: true,
      message: message,
      user: user,
      token: token,
      tokenType: tokenType,
      expiresAt: expiresAt,
    );
  }

  /// Create AuthResponse for failed login
  factory AuthResponse.failure({
    required String message,
  }) {
    return AuthResponse(
      success: false,
      message: message,
    );
  }

  /// Convert AuthResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (user != null) 'user': user!.toJson(),
      if (token != null) 'token': token,
      if (tokenType != null) 'token_type': tokenType,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }

  /// Check if authentication was successful
  bool get isSuccessful => success && user != null && token != null;
  
  /// Check if token is expired
  bool get isTokenExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  /// Check if token will expire soon (within 5 minutes)
  bool get isTokenExpiringSoon {
    if (expiresAt == null) return false;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiresAt!);
  }
  
  /// Get time until token expires
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now());
  }

  /// Get formatted expiry time string
  String get formattedExpiryTime {
    if (expiresAt == null) return 'No expiry';
    
    final timeLeft = timeUntilExpiry!;
    if (timeLeft.isNegative) return 'Expired';
    
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  String toString() {
    return 'AuthResponse(success: $success, message: $message, user: ${user?.name}, token: ${token != null ? '***' : 'null'})';
  }
} 