/// License service for managing licenses and their validation
/// 
/// This service handles license validation, management, and linking
/// with memorials in the Kardiverse system.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/license.dart';
import 'auth_service.dart';

class LicenseService {
  static LicenseService? _instance;
  static LicenseService get instance => _instance ??= LicenseService._();
  
  LicenseService._();
  
  /// Validate a license code
  Future<License?> validateLicense(String licenseCode) async {
    try {
      ApiConfig.logApiCall(ApiConfig.licenseValidationEndpoint, data: {'license_code': licenseCode});
      
      final response = await http.post(
        Uri.parse(ApiConfig.licenseValidationEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...AuthService.instance.getAuthHeaders(),
        },
        body: jsonEncode({
          'license_code': licenseCode,
        }),
      ).timeout(ApiConfig.connectionTimeout);
      
      ApiConfig.logApiResponse(ApiConfig.licenseValidationEndpoint, response.body);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['data']?['license'] != null) {
          return License.fromJson(responseData['data']['license']);
        }
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError(ApiConfig.licenseValidationEndpoint, e);
      return null;
    }
  }
  
  /// Get license details by ID
  Future<License?> getLicenseDetails(int licenseId) async {
    try {
      final endpoint = ApiConfig.licenseDetailsEndpoint.replaceAll('{id}', licenseId.toString());
      ApiConfig.logApiCall(endpoint);
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Accept': 'application/json',
          ...AuthService.instance.getAuthHeaders(),
        },
      ).timeout(ApiConfig.connectionTimeout);
      
      ApiConfig.logApiResponse(endpoint, response.body);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return License.fromJson(responseData['data']);
        }
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Get license details', e);
      return null;
    }
  }
  
  /// Check if a license is valid for use
  Future<bool> isLicenseValid(String licenseCode) async {
    final license = await validateLicense(licenseCode);
    return license != null && license.isActive && !license.isExpired;
  }
  
  /// Check if a license can be assigned to a memorial
  Future<bool> canAssignLicense(String licenseCode) async {
    final license = await validateLicense(licenseCode);
    return license != null && license.canBeAssigned;
  }
  
  /// Check if a license can be activated
  Future<bool> canActivateLicense(String licenseCode) async {
    final license = await validateLicense(licenseCode);
    return license != null && license.canBeActivated;
  }
  
  /// Get license status information
  Future<Map<String, dynamic>?> getLicenseStatus(String licenseCode) async {
    final license = await validateLicense(licenseCode);
    
    if (license == null) return null;
    
    return {
      'is_valid': license.isActive && !license.isExpired,
      'is_active': license.isActive,
      'is_expired': license.isExpired,
      'is_assigned': license.isAssigned,
      'is_activated': license.isActivated,
      'can_be_assigned': license.canBeAssigned,
      'can_be_activated': license.canBeActivated,
      'expires_in': license.formattedExpiryTime,
      'status': license.statusDescription,
      'template_id': license.templateId,
    };
  }
  
  /// Link a license to a memorial
  Future<bool> linkLicenseToMemorial(String licenseCode, int memorialId) async {
    try {
      final license = await validateLicense(licenseCode);
      
      if (license == null || !license.canBeAssigned) {
        return false;
      }
      
      // This would typically call a backend endpoint to link the license
      // For now, we'll just validate that it's possible
      ApiConfig.logApiCall('Link license to memorial', data: {
        'license_code': licenseCode,
        'memorial_id': memorialId,
      });
      
      return true;
    } catch (e) {
      ApiConfig.logApiError('Link license to memorial', e);
      return false;
    }
  }
  
  /// Get licenses for a specific template
  Future<List<License>> getLicensesForTemplate(int templateId) async {
    try {
      // This would typically call a backend endpoint
      // For now, return empty list as placeholder
      ApiConfig.logApiCall('Get licenses for template', data: {'template_id': templateId});
      
      return [];
    } catch (e) {
      ApiConfig.logApiError('Get licenses for template', e);
      return [];
    }
  }
  
  /// Get all licenses for current user
  Future<List<License>> getUserLicenses() async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        return [];
      }
      
      // This would typically call a backend endpoint
      // For now, return empty list as placeholder
      ApiConfig.logApiCall('Get user licenses');
      
      return [];
    } catch (e) {
      ApiConfig.logApiError('Get user licenses', e);
      return [];
    }
  }
  
  /// Generate a new license for a template
  Future<License?> generateLicense(int templateId) async {
    try {
      if (!AuthService.instance.isAdmin) {
        return null;
      }
      
      // This would typically call a backend endpoint
      // For now, return null as placeholder
      ApiConfig.logApiCall('Generate license', data: {'template_id': templateId});
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Generate license', e);
      return null;
    }
  }
  
  /// Revoke a license
  Future<bool> revokeLicense(String licenseCode) async {
    try {
      if (!AuthService.instance.isAdmin) {
        return false;
      }
      
      // This would typically call a backend endpoint
      // For now, return false as placeholder
      ApiConfig.logApiCall('Revoke license', data: {'license_code': licenseCode});
      
      return false;
    } catch (e) {
      ApiConfig.logApiError('Revoke license', e);
      return false;
    }
  }
  
  /// Get license statistics
  Future<Map<String, dynamic>> getLicenseStatistics() async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        return {};
      }
      
      // This would typically call a backend endpoint
      // For now, return placeholder data
      ApiConfig.logApiCall('Get license statistics');
      
      return {
        'total_licenses': 0,
        'active_licenses': 0,
        'expired_licenses': 0,
        'assigned_licenses': 0,
        'unassigned_licenses': 0,
      };
    } catch (e) {
      ApiConfig.logApiError('Get license statistics', e);
      return {};
    }
  }
  
  /// Validate multiple licenses at once
  Future<Map<String, bool>> validateMultipleLicenses(List<String> licenseCodes) async {
    final results = <String, bool>{};
    
    for (final licenseCode in licenseCodes) {
      results[licenseCode] = await isLicenseValid(licenseCode);
    }
    
    return results;
  }
  
  /// Check if license is expiring soon (within 7 days)
  Future<List<String>> getExpiringLicenses() async {
    try {
      final userLicenses = await getUserLicenses();
      final expiringLicenses = <String>[];
      
      for (final license in userLicenses) {
        if (license.isExpiringSoon) {
          expiringLicenses.add(license.code);
        }
      }
      
      return expiringLicenses;
    } catch (e) {
      ApiConfig.logApiError('Get expiring licenses', e);
      return [];
    }
  }
} 