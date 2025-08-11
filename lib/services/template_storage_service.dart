/// Template storage service for managing template file downloads and caching
/// 
/// This service handles downloading, storing, and managing template files
/// locally on the device for offline access.
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/template.dart';
import '../config/api_config.dart';

class TemplateStorageService {
  static TemplateStorageService? _instance;
  static TemplateStorageService get instance => _instance ??= TemplateStorageService._();
  
  TemplateStorageService._();
  
  static const String _templatesDir = 'templates';
  static const String _thumbnailsDir = 'thumbnails';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxTemplates = 50; // Keep last 50 templates
  
  Directory? _templatesDirectory;
  Directory? _thumbnailsDirectory;
  
  /// Initialize storage directories
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      _templatesDirectory = Directory(path.join(appDir.path, _templatesDir));
      _thumbnailsDirectory = Directory(path.join(appDir.path, _thumbnailsDir));
      
      // Create directories if they don't exist
      if (!await _templatesDirectory!.exists()) {
        await _templatesDirectory!.create(recursive: true);
      }
      
      if (!await _thumbnailsDirectory!.exists()) {
        await _thumbnailsDirectory!.create(recursive: true);
      }
      
      ApiConfig.logApiCall('Template storage initialized', data: {
        'templates_dir': _templatesDirectory!.path,
        'thumbnails_dir': _thumbnailsDirectory!.path,
      });
    } catch (e) {
      ApiConfig.logApiError('Initialize template storage', e);
    }
  }
  
  /// Download and cache a template
  Future<String?> downloadTemplate(Template template) async {
    try {
      if (_templatesDirectory == null) {
        await initialize();
      }
      
      final fileName = _generateFileName(template);
      final filePath = path.join(_templatesDirectory!.path, fileName);
      
      // Check if file already exists
      if (await File(filePath).exists()) {
        ApiConfig.logApiCall('Template already cached', data: {
          'template_id': template.id,
          'template_name': template.name,
          'file_path': filePath,
        });
        return filePath;
      }
      
      // Download template file
      ApiConfig.logApiCall('Downloading template', data: {
        'template_id': template.id,
        'template_name': template.name,
        'file_url': template.fileUrl,
        'file_size': template.formattedFileSize,
      });
      
      final file = File(filePath);
      final httpClient = HttpClient();
      
      try {
        final request = await httpClient.getUrl(Uri.parse(template.fileUrl));
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final bytes = await _consolidateHttpClientResponseBytes(response);
          await file.writeAsBytes(bytes);
          
          // Download thumbnail if available
          if (template.hasThumbnail) {
            await _downloadThumbnail(template);
          }
          
          // Clean up old templates if needed
          await cleanupOldTemplates();
          
          ApiConfig.logApiCall('Template downloaded successfully', data: {
            'template_id': template.id,
            'template_name': template.name,
            'file_path': filePath,
            'file_size': await file.length(),
          });
          
          return filePath;
        } else {
          ApiConfig.logApiCall('Template download failed', data: {
            'template_id': template.id,
            'status_code': response.statusCode,
          });
          return null;
        }
      } finally {
        httpClient.close();
      }
    } catch (e) {
      ApiConfig.logApiError('Download template ${template.id}', e);
      return null;
    }
  }
  
  /// Download template thumbnail
  Future<String?> _downloadThumbnail(Template template) async {
    try {
      if (template.thumbnailUrl == null) return null;
      
      final fileName = _generateThumbnailFileName(template);
      final filePath = path.join(_thumbnailsDirectory!.path, fileName);
      
      // Check if thumbnail already exists
      if (await File(filePath).exists()) {
        return filePath;
      }
      
      final file = File(filePath);
      final httpClient = HttpClient();
      
      try {
        final request = await httpClient.getUrl(Uri.parse(template.thumbnailUrl!));
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final bytes = await _consolidateHttpClientResponseBytes(response);
          await file.writeAsBytes(bytes);
          
          ApiConfig.logApiCall('Thumbnail downloaded', data: {
            'template_id': template.id,
            'thumbnail_path': filePath,
          });
          
          return filePath;
        }
      } finally {
        httpClient.close();
      }
    } catch (e) {
      ApiConfig.logApiError('Download thumbnail ${template.id}', e);
    }
    
    return null;
  }
  
  /// Get cached template file path
  Future<String?> getCachedTemplatePath(int templateId) async {
    try {
      if (_templatesDirectory == null) {
        await initialize();
      }
      
      final files = await _templatesDirectory!.list().toList();
      
      for (final file in files) {
        if (file is File && path.basename(file.path).startsWith('${templateId}_')) {
          return file.path;
        }
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Get cached template path $templateId', e);
      return null;
    }
  }
  
  /// Get cached thumbnail path
  Future<String?> getCachedThumbnailPath(int templateId) async {
    try {
      if (_thumbnailsDirectory == null) {
        await initialize();
      }
      
      final files = await _thumbnailsDirectory!.list().toList();
      
      for (final file in files) {
        if (file is File && path.basename(file.path).startsWith('${templateId}_')) {
          return file.path;
        }
      }
      
      return null;
    } catch (e) {
      ApiConfig.logApiError('Get cached thumbnail path $templateId', e);
      return null;
    }
  }
  
  /// Check if template is cached
  Future<bool> isTemplateCached(int templateId) async {
    final path = await getCachedTemplatePath(templateId);
    return path != null;
  }
  
  /// Get template file size
  Future<int?> getTemplateFileSize(int templateId) async {
    try {
      final filePath = await getCachedTemplatePath(templateId);
      if (filePath != null) {
        final file = File(filePath);
        return await file.length();
      }
      return null;
    } catch (e) {
      ApiConfig.logApiError('Get template file size $templateId', e);
      return null;
    }
  }
  
  /// Get total cache size
  Future<int> getTotalCacheSize() async {
    try {
      if (_templatesDirectory == null) {
        await initialize();
      }
      
      int totalSize = 0;
      final files = await _templatesDirectory!.list().toList();
      
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      // Add thumbnails size
      if (_thumbnailsDirectory != null) {
        final thumbnailFiles = await _thumbnailsDirectory!.list().toList();
        for (final file in thumbnailFiles) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      ApiConfig.logApiError('Get total cache size', e);
      return 0;
    }
  }
  
  /// Clean up old templates to free space
  Future<void> cleanupOldTemplates() async {
    try {
      if (_templatesDirectory == null) {
        await initialize();
      }
      
      final files = await _templatesDirectory!.list().toList();
      final fileInfos = <Map<String, dynamic>>[];
      
      // Get file information
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          fileInfos.add({
            'path': file.path,
            'modified': stat.modified,
            'size': stat.size,
          });
        }
      }
      
      // Sort by modification time (oldest first)
      fileInfos.sort((a, b) => a['modified'].compareTo(b['modified']));
      
      // Remove old files if we have too many or cache is too large
      int currentSize = await getTotalCacheSize();
      int removedCount = 0;
      
      for (final fileInfo in fileInfos) {
        if (fileInfos.length - removedCount <= _maxTemplates && 
            currentSize <= _maxCacheSize) {
          break;
        }
        
        final file = File(fileInfo['path']);
        if (await file.exists()) {
          final size = fileInfo['size'] as int;
          await file.delete();
          currentSize -= size;
          removedCount++;
          
          // Also remove corresponding thumbnail
          await _removeThumbnail(fileInfo['path']);
        }
      }
      
      if (removedCount > 0) {
        ApiConfig.logApiCall('Cleaned up old templates', data: {
          'removed_count': removedCount,
          'remaining_size': currentSize,
        });
      }
    } catch (e) {
      ApiConfig.logApiError('Cleanup old templates', e);
    }
  }
  
  /// Remove thumbnail for a template
  Future<void> _removeThumbnail(String templatePath) async {
    try {
      if (_thumbnailsDirectory == null) return;
      
      final templateFileName = path.basename(templatePath);
      final thumbnailFileName = templateFileName.replaceFirst('.', '_thumb.');
      final thumbnailPath = path.join(_thumbnailsDirectory!.path, thumbnailFileName);
      
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    } catch (e) {
      ApiConfig.logApiError('Remove thumbnail', e);
    }
  }
  
  /// Clear all cached templates
  Future<void> clearAllTemplates() async {
    try {
      if (_templatesDirectory != null) {
        await _templatesDirectory!.delete(recursive: true);
        await _templatesDirectory!.create();
      }
      
      if (_thumbnailsDirectory != null) {
        await _thumbnailsDirectory!.delete(recursive: true);
        await _thumbnailsDirectory!.create();
      }
      
      ApiConfig.logApiCall('All templates cleared');
    } catch (e) {
      ApiConfig.logApiError('Clear all templates', e);
    }
  }
  
  /// Generate filename for template
  String _generateFileName(Template template) {
    final extension = template.fileExtension.toLowerCase();
    return '${template.id}_${template.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.$extension';
  }
  
  /// Generate filename for thumbnail
  String _generateThumbnailFileName(Template template) {
    return '${template.id}_${template.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_thumb.jpg';
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    try {
      final totalSize = await getTotalCacheSize();
      final templatesCount = await _getTemplatesCount();
      final thumbnailsCount = await _getThumbnailsCount();
      
      return {
        'total_size': totalSize,
        'total_size_formatted': _formatFileSize(totalSize),
        'templates_count': templatesCount,
        'thumbnails_count': thumbnailsCount,
        'max_cache_size': _maxCacheSize,
        'max_cache_size_formatted': _formatFileSize(_maxCacheSize),
        'max_templates': _maxTemplates,
        'cache_usage_percent': (totalSize / _maxCacheSize) * 100,
      };
    } catch (e) {
      ApiConfig.logApiError('Get cache statistics', e);
      return {};
    }
  }
  
  /// Get templates count
  Future<int> _getTemplatesCount() async {
    try {
      if (_templatesDirectory == null) return 0;
      
      final files = await _templatesDirectory!.list().toList();
      return files.where((file) => file is File).length;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get thumbnails count
  Future<int> _getThumbnailsCount() async {
    try {
      if (_thumbnailsDirectory == null) return 0;
      
      final files = await _thumbnailsDirectory!.list().toList();
      return files.where((file) => file is File).length;
    } catch (e) {
      return 0;
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
  
  /// Consolidate HTTP client response bytes
  Future<List<int>> _consolidateHttpClientResponseBytes(HttpClientResponse response) async {
    final List<int> bytes = [];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    return bytes;
  }
} 