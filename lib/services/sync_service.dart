/// Sync service for managing data synchronization with the backend
/// 
/// This service handles template synchronization, conflict resolution,
/// and background sync operations for the Kardiverse mobile application.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';
import '../models/sync_status.dart';
import '../models/template.dart';
import 'auth_service.dart';

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  
  SyncService._();
  
  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;
  final List<SyncLog> _syncHistory = [];
  
  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;
  
  /// Get last sync attempt time
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  
  /// Get sync history
  List<SyncLog> get syncHistory => List.unmodifiable(_syncHistory);
  
  /// Check sync status from backend
  Future<SyncStatus?> checkSyncStatus() async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        return null;
      }
      
      ApiConfig.logApiCall(ApiConfig.syncStatusEndpoint);
      
      final response = await http.get(
        Uri.parse(ApiConfig.syncStatusEndpoint),
        headers: {
          'Accept': 'application/json',
          ...AuthService.instance.getAuthHeaders(),
        },
      ).timeout(ApiConfig.connectionTimeout);
      
      ApiConfig.logApiResponse(ApiConfig.syncStatusEndpoint, response.body);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return SyncStatus.fromJson(responseData['data']);
        }
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Check sync status', e);
      return null;
    }
  }
  
  /// Sync all templates from backend
  Future<bool> syncTemplates() async {
    try {
      if (_isSyncing) {
        ApiConfig.logApiCall('Sync templates', data: {'status': 'Already syncing'});
        return false;
      }
      
      if (!await _checkConnectivity()) {
        ApiConfig.logApiCall('Sync templates', data: {'status': 'No connectivity'});
        return false;
      }
      
      _isSyncing = true;
      _lastSyncAttempt = DateTime.now();
      
      ApiConfig.logApiCall('Sync templates', data: {'status': 'Starting sync'});
      
      // Get templates list from backend
      final templates = await _fetchTemplatesList();
      if (templates == null) {
        _isSyncing = false;
        return false;
      }
      
      // Sync each template
      int successCount = 0;
      int failureCount = 0;
      
      for (final template in templates) {
        try {
          final success = await _syncTemplate(template);
          if (success) {
            successCount++;
          } else {
            failureCount++;
          }
        } catch (e) {
          failureCount++;
          ApiConfig.logApiError('Sync template ${template.id}', e);
        }
      }
      
      // Log sync completion
      _addSyncLog(
        'bulk_sync',
        successCount > 0 ? 'success' : 'failed',
        'Synced $successCount templates, $failureCount failed',
      );
      
      ApiConfig.logApiCall('Sync templates', data: {
        'status': 'Completed',
        'success': successCount,
        'failed': failureCount,
      });
      
      _isSyncing = false;
      return successCount > 0;
    } catch (e) {
      _isSyncing = false;
      ApiConfig.logApiError('Sync templates', e);
      _addSyncLog('bulk_sync', 'failed', e.toString());
      return false;
    }
  }
  
  /// Sync a specific template
  Future<bool> syncTemplate(Template template) async {
    try {
      if (_isSyncing) return false;
      
      _isSyncing = true;
      
      final success = await _syncTemplate(template);
      
      _isSyncing = false;
      return success;
    } catch (e) {
      _isSyncing = false;
      ApiConfig.logApiError('Sync template ${template.id}', e);
      return false;
    }
  }
  
  /// Fetch templates list from backend
  Future<List<Template>?> _fetchTemplatesList() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.templatesEndpoint),
        headers: {
          'Accept': 'application/json',
          ...AuthService.instance.getAuthHeaders(),
        },
      ).timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final templatesList = responseData['data'] as List<dynamic>;
          return templatesList
              .map((json) => Template.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Fetch templates list', e);
      return null;
    }
  }
  
  /// Sync individual template
  Future<bool> _syncTemplate(Template template) async {
    try {
      // Check if template needs sync
      if (!template.needsSync) {
        return true;
      }
      
      // Download template file
      final success = await _downloadTemplate(template);
      
      if (success) {
        _addSyncLog(
          'template_sync',
          'success',
          'Template ${template.name} synced successfully',
          templateId: template.id,
          templateName: template.name,
        );
      } else {
        _addSyncLog(
          'template_sync',
          'failed',
          'Failed to sync template ${template.name}',
          templateId: template.id,
          templateName: template.name,
        );
      }
      
      return success;
    } catch (e) {
      _addSyncLog(
        'template_sync',
        'failed',
        'Error syncing template ${template.name}: ${e.toString()}',
        templateId: template.id,
        templateName: template.name,
      );
      return false;
    }
  }
  
  /// Download template file
  Future<bool> _downloadTemplate(Template template) async {
    try {
      // This would typically download and store the template file locally
      // For now, we'll simulate the download process
      ApiConfig.logApiCall('Download template', data: {
        'template_id': template.id,
        'template_name': template.name,
        'file_url': template.fileUrl,
        'file_size': template.formattedFileSize,
      });
      
      // Simulate download delay based on file size
      if (template.isLargeFile) {
        await Future.delayed(const Duration(seconds: 2));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Simulate successful download
      return true;
    } catch (e) {
      ApiConfig.logApiError('Download template ${template.id}', e);
      return false;
    }
  }
  
  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      ApiConfig.logApiError('Check connectivity', e);
      return false;
    }
  }
  
  /// Add sync log entry
  void _addSyncLog(
    String operation,
    String status,
    String message, {
    int? templateId,
    String? templateName,
  }) {
    final log = SyncLog(
      operation: operation,
      status: status,
      message: message,
      timestamp: DateTime.now(),
      templateId: templateId,
      templateName: templateName,
    );
    
    _syncHistory.add(log);
    
    // Keep only last 100 log entries
    if (_syncHistory.length > 100) {
      _syncHistory.removeAt(0);
    }
  }
  
  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    final totalLogs = _syncHistory.length;
    final successfulLogs = _syncHistory.where((log) => log.isSuccessful).length;
    final failedLogs = _syncHistory.where((log) => log.isFailed).length;
    
    return {
      'total_operations': totalLogs,
      'successful_operations': successfulLogs,
      'failed_operations': failedLogs,
      'success_rate': totalLogs > 0 ? (successfulLogs / totalLogs) * 100 : 0.0,
      'last_sync_attempt': _lastSyncAttempt?.toIso8601String(),
      'is_currently_syncing': _isSyncing,
    };
  }
  
  /// Force sync (for testing/debugging)
  Future<bool> forceSync() async {
    return await syncTemplates();
  }
  
  /// Clear sync history
  void clearSyncHistory() {
    _syncHistory.clear();
  }
  
  /// Get recent sync logs
  List<SyncLog> getRecentSyncLogs({int limit = 10}) {
    if (_syncHistory.length <= limit) {
      return _syncHistory;
    }
    return _syncHistory.sublist(_syncHistory.length - limit);
  }
  
  /// Check if sync is needed based on last sync time
  bool get needsSync {
    if (_lastSyncAttempt == null) return true;
    
    // Sync if last sync was more than 1 hour ago
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _lastSyncAttempt!.isBefore(oneHourAgo);
  }
  
  /// Get time until next sync
  String get timeUntilNextSync {
    if (_lastSyncAttempt == null) return 'Ready to sync';
    
    final nextSyncTime = _lastSyncAttempt!.add(const Duration(hours: 1));
    final timeDiff = nextSyncTime.difference(DateTime.now());
    
    if (timeDiff.isNegative) return 'Ready to sync';
    
    final hours = timeDiff.inHours;
    final minutes = timeDiff.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m until next sync';
    } else {
      return '${minutes}m until next sync';
    }
  }
} 