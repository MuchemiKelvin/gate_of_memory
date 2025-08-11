/// API Configuration for Kardiverse Mobile Backend Integration
/// 
/// This file contains all API-related configuration including:
/// - Base URLs for different environments
/// - API endpoints
/// - Configuration for different build modes
class ApiConfig {
  // Base URLs for different environments
  static const String _devBaseUrl = "http://192.168.100.14:8000";
  static const String _stagingBaseUrl = "https://staging.kardiverse.com";
  static const String _productionBaseUrl = "https://api.kardiverse.com";
  
  // API version
  static const String _apiVersion = "v1";
  
  // Get base URL based on build mode
  static String get baseUrl {
    // In production builds, use environment variables
    // For now, default to development
    return _devBaseUrl;
  }
  
  // Get API URL
  static String get apiUrl => "$baseUrl/api";
  
  // Get full API URL with version
  static String get fullApiUrl => "$apiUrl/$_apiVersion";
  
  // Authentication endpoints
  static String get loginEndpoint => "$apiUrl/auth/login";
  static String get logoutEndpoint => "$apiUrl/auth/logout";
  static String get refreshEndpoint => "$apiUrl/auth/refresh";
  
  // QR Code endpoints
  static String get qrValidationEndpoint => "$apiUrl/qr-codes/validate";
  static String get qrGenerationEndpoint => "$apiUrl/qr-codes/generate";
  
  // Template endpoints
  static String get templatesEndpoint => "$apiUrl/templates";
  static String get templateDownloadEndpoint => "$apiUrl/templates/{id}/download";
  static String get templateVersionsEndpoint => "$apiUrl/templates/{id}/versions";
  
  // Sync endpoints
  static String get syncStatusEndpoint => "$apiUrl/sync/status";
  static String get syncTemplatesEndpoint => "$apiUrl/sync/templates/{id}";
  
  // License endpoints
  static String get licenseValidationEndpoint => "$apiUrl/licenses/validate";
  static String get licenseDetailsEndpoint => "$apiUrl/licenses/{id}";
  
  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Rate limiting configurations
  static const int maxRequestsPerMinute = 60;
  static const int authRequestsPerMinute = 5;
  static const int qrRequestsPerMinute = 100;
  static const int syncRequestsPerMinute = 10;
  
  // Sync intervals
  static const Duration defaultSyncInterval = Duration(minutes: 5);
  static const Duration maxSyncRetryDelay = Duration(minutes: 10);
  
  // Debug mode (set to false in production)
  static const bool debugMode = true;
  
  // Log API calls in debug mode
  static void logApiCall(String endpoint, {Map<String, dynamic>? data}) {
    if (debugMode) {
      print('🌐 API Call: $endpoint');
      if (data != null) {
        print('📤 Data: $data');
      }
    }
  }
  
  // Log API responses in debug mode
  static void logApiResponse(String endpoint, dynamic response) {
    if (debugMode) {
      print('📥 API Response: $endpoint');
      print('📋 Response: $response');
    }
  }
  
  // Log API errors in debug mode
  static void logApiError(String endpoint, dynamic error) {
    if (debugMode) {
      print('❌ API Error: $endpoint');
      print('🚨 Error: $error');
    }
  }
} 