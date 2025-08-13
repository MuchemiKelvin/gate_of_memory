/// Template Service for managing templates and their operations
/// 
/// This service handles template fetching, management, versioning,
/// and download operations with the backend.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/template.dart';
import '../models/sync_status.dart';
import 'auth_service.dart';
import 'template_storage_service.dart';
import 'category_mapping_service.dart';

class TemplateService {
  static TemplateService? _instance;
  static TemplateService get instance => _instance ??= TemplateService._();
  
  TemplateService._();
  
  // Cache for templates
  final Map<int, Template> _templateCache = {};
  final Map<String, List<Template>> _categoryCache = {};
  
  /// Fetch all templates from backend
  Future<List<Template>?> fetchTemplates({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _templateCache.isNotEmpty) {
        return _templateCache.values.toList();
      }
      
      if (!AuthService.instance.isAuthenticated) {
        return null;
      }
      
      ApiConfig.logApiCall(ApiConfig.templatesEndpoint, data: {'force_refresh': forceRefresh});
      
      final response = await http.get(
        Uri.parse(ApiConfig.templatesEndpoint),
        headers: {
          'Accept': 'application/json',
          ...AuthService.instance.getAuthHeaders(),
        },
      ).timeout(ApiConfig.connectionTimeout);
      
      ApiConfig.logApiResponse(ApiConfig.templatesEndpoint, response.body);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final templatesList = responseData['data'] as List<dynamic>;
          final templates = templatesList
              .map((json) => Template.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // Update cache
          _templateCache.clear();
          for (final template in templates) {
            _templateCache[template.id] = template;
          }
          
          // Update category cache
          _updateCategoryCache(templates);
          
          ApiConfig.logApiCall('Templates fetched', data: {
            'count': templates.length,
            'cached': true,
          });
          
          return templates;
        }
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Fetch templates', e);
      return null;
    }
  }
  
  /// Fetch templates by category
  Future<List<Template>?> fetchTemplatesByCategory(String category) async {
    try {
      // Check category cache first
      if (_categoryCache.containsKey(category)) {
        return _categoryCache[category];
      }
      
      // Fetch all templates if not cached
      final allTemplates = await fetchTemplates();
      if (allTemplates != null) {
        final categoryTemplates = allTemplates
            .where((template) => template.category.toLowerCase() == category.toLowerCase())
            .toList();
        
        _categoryCache[category] = categoryTemplates;
        return categoryTemplates;
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Fetch templates by category', e);
      return null;
    }
  }
  
  /// Get template by ID
  Future<Template?> getTemplateById(int id) async {
    try {
      // Check cache first
      if (_templateCache.containsKey(id)) {
        return _templateCache[id];
      }
      
      // Fetch from backend if not cached
      final templates = await fetchTemplates();
      return templates?.firstWhere((template) => template.id == id);
    } catch (e) {
      ApiConfig.logApiError('Get template by ID', e);
      return null;
    }
  }
  
  /// Download specific template
  Future<bool> downloadTemplate(int templateId) async {
    try {
      final template = await getTemplateById(templateId);
      if (template == null) {
        ApiConfig.logApiError('Download template', 'Template not found: $templateId');
        return false;
      }
      
      ApiConfig.logApiCall('Download template', data: {
        'template_id': templateId,
        'template_name': template.name,
        'file_size': template.formattedFileSize,
      });
      
      // Use template storage service to download
      final filePath = await TemplateStorageService.instance.downloadTemplate(template);
      
      if (filePath != null) {
        ApiConfig.logApiCall('Template downloaded successfully', data: {
          'template_id': templateId,
          'file_path': filePath,
        });
        return true;
      } else {
        ApiConfig.logApiError('Download template', 'Failed to download template: $templateId');
        return false;
      }
    } catch (e) {
      ApiConfig.logApiError('Download template $templateId', e);
      return false;
    }
  }
  
  /// Get template versions
  Future<List<Map<String, dynamic>>?> getTemplateVersions(int templateId) async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        return null;
      }
      
      final endpoint = '${ApiConfig.templatesEndpoint}/$templateId/versions';
      ApiConfig.logApiCall(endpoint, data: {'template_id': templateId});
      
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
          final versionsList = responseData['data'] as List<dynamic>;
          return versionsList
              .map((version) => version as Map<String, dynamic>)
              .toList();
        }
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Get template versions', e);
      return null;
    }
  }
  
  /// Restore template to specific version
  Future<bool> restoreTemplateVersion(int templateId, int versionId) async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        return false;
      }
      
      final endpoint = '${ApiConfig.templatesEndpoint}/$templateId/restore/$versionId';
      ApiConfig.logApiCall(endpoint, data: {
        'template_id': templateId,
        'version_id': versionId,
      });
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Accept': 'application/json',
          ...AuthService.instance.getAuthHeaders(),
        },
      ).timeout(ApiConfig.connectionTimeout);
      
      ApiConfig.logApiResponse(endpoint, response.body);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Clear cache to force refresh
          _templateCache.remove(templateId);
          _categoryCache.clear();
          
          ApiConfig.logApiCall('Template version restored', data: {
            'template_id': templateId,
            'version_id': versionId,
          });
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
      ApiConfig.logApiError('Restore template version', e);
      return false;
    }
  }
  
  /// Search templates
  Future<List<Template>?> searchTemplates(String query) async {
    try {
      final allTemplates = await fetchTemplates();
      if (allTemplates == null) return null;
      
      final lowercaseQuery = query.toLowerCase();
      return allTemplates.where((template) {
        return template.name.toLowerCase().contains(lowercaseQuery) ||
               template.description.toLowerCase().contains(lowercaseQuery) ||
               template.category.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      ApiConfig.logApiError('Search templates', e);
      return null;
    }
  }
  
  /// Get templates by sync status
  Future<List<Template>?> getTemplatesBySyncStatus(String syncStatus) async {
    try {
      final allTemplates = await fetchTemplates();
      if (allTemplates == null) return null;
      
      return allTemplates
          .where((template) => template.syncStatus.toLowerCase() == syncStatus.toLowerCase())
          .toList();
    } catch (e) {
      ApiConfig.logApiError('Get templates by sync status', e);
      return null;
    }
  }
  
  /// Get templates that need update
  Future<List<Template>?> getTemplatesNeedingUpdate() async {
    try {
      final allTemplates = await fetchTemplates();
      if (allTemplates == null) return null;
      
      return allTemplates.where((template) => template.needsUpdate).toList();
    } catch (e) {
      ApiConfig.logApiError('Get templates needing update', e);
      return null;
    }
  }
  
  /// Get template statistics
  Future<Map<String, dynamic>?> getTemplateStatistics() async {
    try {
      final allTemplates = await fetchTemplates();
      if (allTemplates == null) return null;
      
      final totalTemplates = allTemplates.length;
      final activeTemplates = allTemplates.where((t) => t.isActive).length;
      final syncedTemplates = allTemplates.where((t) => t.isSynced).length;
      final pendingSync = allTemplates.where((t) => t.needsSync).length;
      
      // Category breakdown
      final categoryBreakdown = <String, int>{};
      for (final template in allTemplates) {
        final category = template.category;
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }
      
      // File type breakdown
      final fileTypeBreakdown = <String, int>{};
      for (final template in allTemplates) {
        final fileType = template.fileExtension;
        fileTypeBreakdown[fileType] = (fileTypeBreakdown[fileType] ?? 0) + 1;
      }
      
      // Total file size
      final totalFileSize = allTemplates.fold<int>(0, (sum, template) => sum + template.fileSize);
      
      return {
        'total_templates': totalTemplates,
        'active_templates': activeTemplates,
        'synced_templates': syncedTemplates,
        'pending_sync': pendingSync,
        'category_breakdown': categoryBreakdown,
        'file_type_breakdown': fileTypeBreakdown,
        'total_file_size': totalFileSize,
        'total_file_size_formatted': _formatFileSize(totalFileSize),
      };
    } catch (e) {
      ApiConfig.logApiError('Get template statistics', e);
      return null;
    }
  }
  
  /// Check if template is downloaded locally
  Future<bool> isTemplateDownloaded(int templateId) async {
    try {
      return await TemplateStorageService.instance.isTemplateCached(templateId);
    } catch (e) {
      ApiConfig.logApiError('Check template downloaded', e);
      return false;
    }
  }
  
  /// Get local template file path
  Future<String?> getLocalTemplatePath(int templateId) async {
    try {
      return await TemplateStorageService.instance.getCachedTemplatePath(templateId);
    } catch (e) {
      ApiConfig.logApiError('Get local template path', e);
      return null;
    }
  }
  
  /// Clear template cache
  void clearTemplateCache() {
    _templateCache.clear();
    _categoryCache.clear();
    ApiConfig.logApiCall('Template cache cleared');
  }
  
  /// Update category cache
  void _updateCategoryCache(List<Template> templates) {
    _categoryCache.clear();
    
    for (final template in templates) {
      final category = template.category;
      if (!_categoryCache.containsKey(category)) {
        _categoryCache[category] = [];
      }
      _categoryCache[category]!.add(template);
    }
  }
  
  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'templates_cached': _templateCache.length,
      'categories_cached': _categoryCache.length,
      'cache_keys': _templateCache.keys.toList(),
      'category_keys': _categoryCache.keys.toList(),
    };
  }

  /// Get essential templates for startup sync
  Future<List<Template>> getEssentialTemplates() async {
    try {
      // Get all templates
      final allTemplates = await fetchTemplates();
      if (allTemplates == null || allTemplates.isEmpty) {
        return [];
      }

      // Filter for essential templates (demo memorials, core content)
      final essentialTemplates = allTemplates.where((template) {
        // Check if template is for demo memorials
        if (template.category.toLowerCase().contains('memorial') ||
            template.category.toLowerCase().contains('demo')) {
          return true;
        }

        // Check if template is recently updated (within last 7 days)
        final templateAge = DateTime.now().difference(template.updatedAt);
        if (templateAge.inDays < 7) {
          return true;
        }

        return false;
      }).toList();

      // Sort by priority (then by update date)
      essentialTemplates.sort((a, b) {
        // Then by update date (newest first)
        return b.updatedAt.compareTo(a.updatedAt);
      });

      // Limit to top 10 essential templates
      return essentialTemplates.take(10).toList();

    } catch (e) {
      print('Error getting essential templates: $e');
      return [];
    }
  }
} 