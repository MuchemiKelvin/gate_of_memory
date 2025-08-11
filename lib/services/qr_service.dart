/// QR Code Service for validation, generation, and management
/// 
/// This service handles QR code operations including validation against
/// the backend, local caching, and QR code generation for licenses.
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import '../config/api_config.dart';
import '../models/license.dart';
import '../models/template.dart';
import 'auth_service.dart';

class QRService {
  static QRService? _instance;
  static QRService get instance => _instance ??= QRService._();
  
  QRService._();
  
  // Cache for validation results (offline fallback)
  final Map<String, Map<String, dynamic>> _validationCache = {};
  static const int _cacheExpiryHours = 24; // Cache for 24 hours
  
  /// Validate a QR code against the backend
  Future<Map<String, dynamic>?> validateQRCode(String qrData) async {
    try {
      // First, try to parse the QR data locally
      final parsedData = _parseQRData(qrData);
      if (parsedData == null) {
        return {
          'success': false,
          'message': 'Invalid QR code format',
          'error_code': 'invalid_format',
        };
      }
      
      // Check cache first for offline validation
      if (_validationCache.containsKey(qrData)) {
        final cachedResult = _validationCache[qrData]!;
        if (!_isCacheExpired(cachedResult['cached_at'])) {
          ApiConfig.logApiCall('QR validation (cached)', data: {
            'qr_data': qrData,
            'result': 'cached_validation',
          });
          return cachedResult;
        } else {
          // Remove expired cache entry
          _validationCache.remove(qrData);
        }
      }
      
      // Try online validation
      if (await _checkConnectivity()) {
        return await _validateOnline(qrData, parsedData);
      } else {
        // Offline mode - return cached result if available
        return _getOfflineValidationResult(qrData, parsedData);
      }
    } catch (e) {
      ApiConfig.logApiError('Validate QR code', e);
      return {
        'success': false,
        'message': 'Validation failed: ${e.toString()}',
        'error_code': 'validation_error',
      };
    }
  }
  
  /// Parse QR code data locally
  Map<String, dynamic>? _parseQRData(String qrData) {
    try {
      // Try to parse as JSON first
      if (qrData.startsWith('{') && qrData.endsWith('}')) {
        return jsonDecode(qrData);
      }
      
      // Try to parse as URL-encoded data
      if (qrData.contains('=')) {
        final params = Uri.splitQueryString(qrData);
        return params;
      }
      
      // Simple text format (fallback)
      return {
        'license_code': qrData,
        'type': 'simple_license',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      ApiConfig.logApiError('Parse QR data', e);
      return null;
    }
  }
  
  /// Validate QR code online against backend
  Future<Map<String, dynamic>?> _validateOnline(String qrData, Map<String, dynamic> parsedData) async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        return {
          'success': false,
          'message': 'Authentication required',
          'error_code': 'auth_required',
        };
      }
      
      ApiConfig.logApiCall(ApiConfig.qrValidationEndpoint, data: {
        'qr_data': qrData,
        'parsed_data': parsedData,
      });
      
      final response = await http.post(
        Uri.parse(ApiConfig.qrValidationEndpoint),
        headers: {
          'Accept': 'application/json',
          ...AuthService.instance.getAuthHeaders(),
        },
        body: jsonEncode({'qr_data': qrData}),
      ).timeout(ApiConfig.connectionTimeout);
      
      ApiConfig.logApiResponse(ApiConfig.qrValidationEndpoint, response.body);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          // Cache the successful validation
          final result = {
            'success': true,
            'message': responseData['message'] ?? 'QR code is valid',
            'data': responseData['data'],
            'cached_at': DateTime.now().toIso8601String(),
            'validation_method': 'online',
          };
          
          _validationCache[qrData] = result;
          return result;
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'QR code validation failed',
            'error_code': 'backend_validation_failed',
          };
        }
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Invalid QR code format',
          'error_code': 'invalid_format',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'License not found or invalid',
          'error_code': 'license_not_found',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'error_code': 'server_error',
        };
      }
    } catch (e) {
      ApiConfig.logApiError('Online QR validation', e);
      return null;
    }
  }
  
  /// Get offline validation result
  Map<String, dynamic>? _getOfflineValidationResult(String qrData, Map<String, dynamic> parsedData) {
    // Check if we have a cached result
    if (_validationCache.containsKey(qrData)) {
      final cachedResult = _validationCache[qrData]!;
      if (!_isCacheExpired(cachedResult['cached_at'])) {
        return {
          'success': true,
          'message': 'QR code validated (offline - cached)',
          'data': cachedResult['data'],
          'validation_method': 'offline_cached',
          'offline_warning': 'Using cached validation result',
        };
      }
    }
    
    // Basic offline validation based on parsed data
    if (parsedData.containsKey('license_code')) {
      return {
        'success': true,
        'message': 'QR code validated (offline - basic)',
        'data': {
          'license': {
            'code': parsedData['license_code'],
            'status': 'unknown_offline',
          },
          'template': {
            'id': parsedData['template_id'] ?? 0,
            'name': 'Template (offline)',
            'status': 'unknown_offline',
          },
        },
        'validation_method': 'offline_basic',
        'offline_warning': 'Limited validation in offline mode',
      };
    }
    
    return {
      'success': false,
      'message': 'Cannot validate QR code offline',
      'error_code': 'offline_validation_failed',
    };
  }
  
  /// Generate QR code for a license
  Future<Uint8List?> generateQRCode(License license, {int size = 200}) async {
    try {
      final qrData = {
        'license_code': license.code,
        'template_id': license.templateId,
        'type': 'license_activation',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final qrString = jsonEncode(qrData);
      
      ApiConfig.logApiCall('Generate QR code', data: {
        'license_code': license.code,
        'template_id': license.templateId,
        'qr_data': qrString,
      });
      
      // Generate QR code using qr_flutter
      final qrPainter = QrPainter(
        data: qrString,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        size: size.toDouble(),
      );
      
      // Convert to image bytes
      final qrImage = await qrPainter.toImageData(size.toDouble());
      return qrImage?.buffer.asUint8List();
    } catch (e) {
      ApiConfig.logApiError('Generate QR code', e);
      return null;
    }
  }
  
  /// Generate QR code for template selection
  Future<Uint8List?> generateTemplateQRCode(Template template, {int size = 200}) async {
    try {
      final qrData = {
        'template_id': template.id,
        'template_name': template.name,
        'category': template.category,
        'version': template.version,
        'type': 'template_selection',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final qrString = jsonEncode(qrData);
      
      ApiConfig.logApiCall('Generate template QR code', data: {
        'template_id': template.id,
        'template_name': template.name,
        'qr_data': qrString,
      });
      
      // Generate QR code
      final qrPainter = QrPainter(
        data: qrString,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        size: size.toDouble(),
      );
      
      final qrImage = await qrPainter.toImageData(size.toDouble());
      return qrImage?.buffer.asUint8List();
    } catch (e) {
      ApiConfig.logApiError('Generate template QR code', e);
      return null;
    }
  }
  
  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      // Simple connectivity check - try to reach the API
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if cache entry is expired
  bool _isCacheExpired(String cachedAt) {
    try {
      final cachedTime = DateTime.parse(cachedAt);
      final expiryTime = cachedTime.add(Duration(hours: _cacheExpiryHours));
      return DateTime.now().isAfter(expiryTime);
    } catch (e) {
      return true; // Consider expired if parsing fails
    }
  }
  
  /// Clear validation cache
  void clearValidationCache() {
    _validationCache.clear();
    ApiConfig.logApiCall('QR validation cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    final totalEntries = _validationCache.length;
    final expiredEntries = _validationCache.entries
        .where((entry) => _isCacheExpired(entry.value['cached_at']))
        .length;
    
    return {
      'total_entries': totalEntries,
      'expired_entries': expiredEntries,
      'valid_entries': totalEntries - expiredEntries,
      'cache_expiry_hours': _cacheExpiryHours,
    };
  }
  
  /// Validate QR code format without backend call
  bool isValidQRFormat(String qrData) {
    try {
      final parsed = _parseQRData(qrData);
      return parsed != null && parsed.containsKey('license_code');
    } catch (e) {
      return false;
    }
  }
  
  /// Get QR code type
  String getQRCodeType(String qrData) {
    try {
      final parsed = _parseQRData(qrData);
      if (parsed != null) {
        return parsed['type'] ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
} 