import 'package:flutter/material.dart';
import 'dart:async';
import '../models/memorial.dart';
import '../services/memorial_service.dart';

class ARContentLoadingService {
  static final ARContentLoadingService _instance = ARContentLoadingService._internal();
  factory ARContentLoadingService() => _instance;
  ARContentLoadingService._internal();

  final MemorialService _memorialService = MemorialService();
  
  // Content cache
  final Map<String, ARContent> _contentCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Loading state
  bool _isLoading = false;
  String? _currentLoadingId;
  double _loadingProgress = 0.0;
  
  // Content types
  static const Map<String, String> _contentTypes = {
    'hologram': 'assets/animation/',
    'image': 'assets/images/',
    'video': 'assets/video/',
    'audio': 'assets/audio/',
  };

  // Getters
  bool get isLoading => _isLoading;
  String? get currentLoadingId => _currentLoadingId;
  double get loadingProgress => _loadingProgress;
  int get cachedContentCount => _contentCache.length;

  /// Convert position map to double values
  Map<String, double>? _convertPositionToDouble(dynamic position) {
    if (position == null) return null;
    if (position is Map<String, dynamic>) {
      return {
        'x': (position['x'] ?? 0).toDouble(),
        'y': (position['y'] ?? 0).toDouble(),
        'z': (position['z'] ?? 0).toDouble(),
      };
    }
    return null;
  }

  /// Test database connectivity and memorial loading
  Future<void> testDatabaseConnection() async {
    try {
      print('=== TESTING DATABASE CONNECTION ===');
      final memorials = await _memorialService.getAllMemorials();
      print('Found ${memorials.length} memorials in database');
      
      for (final memorial in memorials) {
        print('  - ID: ${memorial.id}, Name: ${memorial.name}, QR: "${memorial.qrCode}"');
        print('    Image: ${memorial.imagePath}');
        print('    Video: ${memorial.videoPath}');
        print('    Hologram: ${memorial.hologramPath}');
        print('    Audio: ${memorial.audioPaths.join(', ')}');
        print('    Stories: ${memorial.stories.length}');
      }
      print('=== END DATABASE TEST ===');
    } catch (e) {
      print('Database test error: $e');
    }
  }

  /// Test specific marker lookup
  Future<void> testMarkerLookup(String markerId) async {
    try {
      print('=== TESTING MARKER LOOKUP: $markerId ===');
      final memorials = await _memorialService.getAllMemorials();
      final targetMemorial = memorials.firstWhere(
        (memorial) => memorial.qrCode == markerId,
        orElse: () => throw Exception('Memorial not found'),
      );
      
      print('Found memorial for marker $markerId:');
      print('  - Name: ${targetMemorial.name}');
      print('  - QR Code: "${targetMemorial.qrCode}"');
      print('  - Hologram: ${targetMemorial.hologramPath}');
      print('  - Audio files: ${targetMemorial.audioPaths.length}');
      print('  - Stories: ${targetMemorial.stories.length}');
      print('=== END MARKER LOOKUP TEST ===');
    } catch (e) {
      print('Marker lookup test error for $markerId: $e');
    }
  }

  /// Load AR content for a marker
  Future<ARContent?> loadContent(String markerId, Map<String, dynamic> markerData) async {
    try {
      print('Loading AR content for marker: $markerId');
      
      // Check cache first
      if (_contentCache.containsKey(markerId)) {
        final cachedContent = _contentCache[markerId]!;
        final cacheTime = _cacheTimestamps[markerId]!;
        
        // Check if cache is still valid (5 minutes)
        if (DateTime.now().difference(cacheTime).inMinutes < 5) {
          print('Returning cached content for: $markerId');
          return cachedContent;
        } else {
          // Remove expired cache
          _contentCache.remove(markerId);
          _cacheTimestamps.remove(markerId);
        }
      }

      // Start loading
      _isLoading = true;
      _currentLoadingId = markerId;
      _loadingProgress = 0.0;

      // Determine content type and load accordingly
      final contentType = markerData['type'] ?? 'memorial';
      ARContent? content;

      switch (contentType) {
        case 'memorial':
          content = await _loadMemorialContent(markerId, markerData);
          break;
        case 'hologram':
          content = await _loadHologramContent(markerId, markerData);
          break;
        case 'test':
          content = await _loadTestContent(markerId, markerData);
          break;
        default:
          print('Unknown content type: $contentType');
          return null;
      }

      // Cache the content
      if (content != null) {
        _contentCache[markerId] = content;
        _cacheTimestamps[markerId] = DateTime.now();
        print('Content cached for marker: $markerId');
      }

      // Reset loading state
      _isLoading = false;
      _currentLoadingId = null;
      _loadingProgress = 1.0;

      return content;
    } catch (e) {
      print('Error loading AR content: $e');
      _isLoading = false;
      _currentLoadingId = null;
      _loadingProgress = 0.0;
      return null;
    }
  }

  /// Load memorial content
  Future<ARContent?> _loadMemorialContent(String markerId, Map<String, dynamic> markerData) async {
    try {
      print('Loading memorial content for: $markerId');
      print('Marker data: $markerData');
      
      // Simulate loading progress
      _loadingProgress = 0.2;
      await Future.delayed(Duration(milliseconds: 200));
      
      // Get memorial from database
      final memorials = await _memorialService.getAllMemorials();
      print('Found ${memorials.length} memorials in database');
      
      // Debug: Print all memorials with detailed info
      for (final memorial in memorials) {
        print('  - ID: ${memorial.id}, Name: ${memorial.name}, QR: "${memorial.qrCode}"');
        print('    Description: ${memorial.description.substring(0, 50)}...');
        print('    Image: ${memorial.imagePath}');
        print('    Video: ${memorial.videoPath}');
        print('    Hologram: ${memorial.hologramPath}');
        print('    Audio: ${memorial.audioPaths.join(', ')}');
        print('    Stories: ${memorial.stories.length}');
        print('    Status: ${memorial.status}');
        print('    Sync Status: ${memorial.syncStatus}');
        print('    Created: ${memorial.createdAt}');
        print('    Updated: ${memorial.updatedAt}');
        print('    Deleted: ${memorial.deletedAt}');
        print('    ---');
      }
      
      Memorial? targetMemorial;
      
      // Find memorial by marker ID or name
      for (final memorial in memorials) {
        print('Checking memorial: ${memorial.name} (QR: "${memorial.qrCode}") against marker: "$markerId"');
        print('  QR Code match: ${memorial.qrCode == markerId}');
        print('  Name contains: ${memorial.name.toLowerCase().contains(markerData['name']?.toLowerCase() ?? '')}');
        
        if (memorial.qrCode == markerId || 
            memorial.name.toLowerCase().contains(markerData['name']?.toLowerCase() ?? '')) {
          targetMemorial = memorial;
          print('Found matching memorial: ${memorial.name}');
          break;
        }
      }
      
      _loadingProgress = 0.5;
      await Future.delayed(Duration(milliseconds: 200));
      
      if (targetMemorial == null) {
        print('Memorial not found for marker: $markerId');
        print('Available QR codes: ${memorials.map((m) => '"${m.qrCode}"').join(', ')}');
        print('Available names: ${memorials.map((m) => m.name).join(', ')}');
        
        // Create fallback test content if no memorial found
        print('Creating fallback test content for marker: $markerId');
        final fallbackContent = ARContent(
          id: markerId,
          type: ARContentType.test,
          title: 'Test Memorial - $markerId',
          description: 'Fallback content for testing AR functionality',
          hologramPath: 'assets/animation/hologram.mp4',
          imagePaths: ['assets/images/memorial_card.jpeg'],
          videoPaths: ['assets/video/memorial_video.mp4'],
          audioPaths: ['assets/audio/victory_chime.mp3'],
          stories: [
            Story(
              title: 'Test Story',
              snippet: 'This is a test story for AR content',
              fullText: 'This is a fallback test story that appears when no memorial is found in the database. It allows the AR system to function for testing purposes.',
            ),
          ],
          position: _convertPositionToDouble(markerData['position']) ?? {'x': 0.0, 'y': 0.0, 'z': 0.0},
          scale: (markerData['scale'] ?? 1).toDouble(),
          rotation: (markerData['rotation'] ?? 0).toDouble(),
        );
        
        _loadingProgress = 1.0;
        await Future.delayed(Duration(milliseconds: 200));
        
        print('Fallback test content created: ${fallbackContent.title}');
        return fallbackContent;
      }
      
      // Create AR content from memorial
      final content = ARContent(
        id: markerId,
        type: ARContentType.memorial,
        title: targetMemorial.name,
        description: targetMemorial.description,
        hologramPath: targetMemorial.hologramPath,
        imagePaths: [targetMemorial.imagePath],
        videoPaths: targetMemorial.videoPath.isNotEmpty ? [targetMemorial.videoPath] : [],
        audioPaths: targetMemorial.audioPaths,
        stories: targetMemorial.stories,
        position: _convertPositionToDouble(markerData['position']) ?? {'x': 0.0, 'y': 0.0, 'z': 0.0},
        scale: (markerData['scale'] ?? 1).toDouble(),
        rotation: (markerData['rotation'] ?? 0).toDouble(),
      );
      
      _loadingProgress = 1.0;
      await Future.delayed(Duration(milliseconds: 200));
      
      print('Memorial content loaded: ${content.title}');
      print('  Description: ${content.description.substring(0, 50)}...');
      print('  Hologram: ${content.hologramPath}');
      print('  Images: ${content.imagePaths.length}');
      print('  Videos: ${content.videoPaths.length}');
      print('  Audio: ${content.audioPaths.length}');
      print('  Stories: ${content.stories.length}');
      return content;
    } catch (e) {
      print('Error loading memorial content: $e');
      return null;
    }
  }

  /// Load hologram content
  Future<ARContent?> _loadHologramContent(String markerId, Map<String, dynamic> markerData) async {
    try {
      print('Loading hologram content for: $markerId');
      
      _loadingProgress = 0.3;
      await Future.delayed(Duration(milliseconds: 300));
      
      final hologramName = markerData['content'] ?? 'hologram';
      final hologramPath = 'assets/animation/${hologramName}.mp4';
      
      _loadingProgress = 0.7;
      await Future.delayed(Duration(milliseconds: 300));
      
      final content = ARContent(
        id: markerId,
        type: ARContentType.hologram,
        title: markerData['name'] ?? 'Hologram',
        description: 'AR Hologram Content',
        hologramPath: hologramPath,
        position: _convertPositionToDouble(markerData['position']) ?? {'x': 0.0, 'y': 0.0, 'z': 0.0},
        scale: (markerData['scale'] ?? 1).toDouble(),
        rotation: (markerData['rotation'] ?? 0).toDouble(),
      );
      
      _loadingProgress = 1.0;
      await Future.delayed(Duration(milliseconds: 200));
      
      print('Hologram content loaded: ${content.title}');
      return content;
    } catch (e) {
      print('Error loading hologram content: $e');
      return null;
    }
  }

  /// Load test content
  Future<ARContent?> _loadTestContent(String markerId, Map<String, dynamic> markerData) async {
    try {
      print('Loading test content for: $markerId');
      
      _loadingProgress = 0.5;
      await Future.delayed(Duration(milliseconds: 500));
      
      final content = ARContent(
        id: markerId,
        type: ARContentType.test,
        title: 'Test Hologram',
        description: 'Test AR content for development',
        hologramPath: 'assets/animation/hologram.mp4',
        position: _convertPositionToDouble(markerData['position']) ?? {'x': 0.0, 'y': 0.0, 'z': 0.0},
        scale: (markerData['scale'] ?? 1).toDouble(),
        rotation: (markerData['rotation'] ?? 0).toDouble(),
      );
      
      _loadingProgress = 1.0;
      await Future.delayed(Duration(milliseconds: 200));
      
      print('Test content loaded: ${content.title}');
      return content;
    } catch (e) {
      print('Error loading test content: $e');
      return null;
    }
  }

  /// Preload content for better performance
  Future<void> preloadContent(List<String> markerIds) async {
    try {
      print('Preloading content for ${markerIds.length} markers');
      
      for (final markerId in markerIds) {
        // Get marker data from detection service
        // For now, we'll use placeholder data
        final markerData = {
          'type': 'memorial',
          'name': 'Preload Memorial',
          'content': 'hologram',
        };
        
        await loadContent(markerId, markerData);
      }
      
      print('Content preloading completed');
    } catch (e) {
      print('Error preloading content: $e');
    }
  }

  /// Clear content cache
  void clearCache() {
    _contentCache.clear();
    _cacheTimestamps.clear();
    print('AR content cache cleared');
  }

  /// Remove specific content from cache
  void removeFromCache(String markerId) {
    _contentCache.remove(markerId);
    _cacheTimestamps.remove(markerId);
    print('Content removed from cache: $markerId');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedContentCount': _contentCache.length,
      'cacheSize': _contentCache.length * 1024, // Approximate size in bytes
      'oldestCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String()
          : null,
      'newestCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
    };
  }

  /// Get loading status
  Map<String, dynamic> getLoadingStatus() {
    return {
      'isLoading': _isLoading,
      'currentLoadingId': _currentLoadingId,
      'loadingProgress': _loadingProgress,
    };
  }

  /// Dispose content loading service
  void dispose() {
    clearCache();
    print('AR content loading service disposed');
  }
}

/// AR Content Types
enum ARContentType {
  memorial,
  hologram,
  test,
  image,
  video,
  audio,
}

/// AR Content Model
class ARContent {
  final String id;
  final ARContentType type;
  final String title;
  final String description;
  final String? hologramPath;
  final List<String> imagePaths;
  final List<String> videoPaths;
  final List<String> audioPaths;
  final List<Story> stories;
  final Map<String, double> position;
  final double scale;
  final double rotation;

  ARContent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.hologramPath,
    this.imagePaths = const [],
    this.videoPaths = const [],
    this.audioPaths = const [],
    this.stories = const [],
    required this.position,
    required this.scale,
    required this.rotation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'hologramPath': hologramPath,
      'imagePaths': imagePaths,
      'videoPaths': videoPaths,
      'audioPaths': audioPaths,
      'stories': stories.map((s) => s.toJson()).toList(),
      'position': position,
      'scale': scale,
      'rotation': rotation,
    };
  }

  @override
  String toString() {
    return 'ARContent(id: $id, type: $type, title: $title)';
  }
} 