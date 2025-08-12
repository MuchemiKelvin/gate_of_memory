/// Web Storage Service for web platform compatibility
/// 
/// This service provides local storage functionality for web platforms
/// where SQLite is not available.
import 'package:flutter/foundation.dart';
import 'dart:convert';

class WebStorageService {
  static WebStorageService? _instance;
  static WebStorageService get instance => _instance ??= WebStorageService._();
  
  WebStorageService._();
  
  // In-memory storage for web (simulates database tables)
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'categories': [],
    'memorials': [],
    'media': [],
    'sync_log': [],
  };
  
  /// Initialize web storage with default data
  Future<void> initialize() async {
    try {
      print('Initializing web storage service...');
      
      // Load data from localStorage if available
      await _loadFromLocalStorage();
      
      // Seed default data if tables are empty
      if (_tables['categories']!.isEmpty) {
        await _seedDefaultCategories();
      }
      
      if (_tables['memorials']!.isEmpty) {
        await _seedDemoMemorials();
      }
      
      // Save to localStorage
      await _saveToLocalStorage();
      
      print('Web storage service initialized successfully');
    } catch (e) {
      print('Error initializing web storage: $e');
      rethrow;
    }
  }
  
  /// Seed default categories
  Future<void> _seedDefaultCategories() async {
    final defaultCategories = [
      {'id': 1, 'name': 'Memorial', 'description': 'Memorial cards and tributes'},
      {'id': 2, 'name': 'Celebration', 'description': 'Celebration and event cards'},
      {'id': 3, 'name': 'Tribute', 'description': 'Tribute and honor cards'},
      {'id': 4, 'name': 'Historical', 'description': 'Historical and educational cards'},
    ];
    
    _tables['categories']!.addAll(defaultCategories);
    print('Seeded ${defaultCategories.length} default categories');
  }
  
  /// Seed demo memorials
  Future<void> _seedDemoMemorials() async {
    final demoMemorials = [
      {
        'id': 1,
        'name': 'Naomi N.',
        'description': 'A beloved mother and community leader who touched countless lives with her warmth and wisdom.',
        'category': 'Memorial',
        'version': '1.0',
        'imagePath': 'assets/images/memorial_card.jpeg', // Use existing asset
        'videoPath': 'assets/video/sample_video.mp4', // Placeholder
        'hologramPath': 'assets/video/sample_video.mp4', // Use video as hologram placeholder
        'audioPaths': ['assets/audio/sample_audio.mp3'], // Placeholder
        'qrCode': 'NAOMI-N-MEMORIAL-001',
        'status': 'active',
        'syncStatus': 'synced',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'name': 'John M.',
        'description': 'A dedicated teacher who inspired generations of students to pursue their dreams.',
        'category': 'Celebration',
        'version': '1.0',
        'imagePath': 'assets/images/memorial_card.jpeg', // Use existing asset
        'videoPath': 'assets/video/sample_video.mp4', // Placeholder
        'hologramPath': 'assets/video/sample_video.mp4', // Use video as hologram placeholder
        'audioPaths': ['assets/audio/sample_audio.mp3'], // Placeholder
        'qrCode': 'JOHN-M-MEMORIAL-002',
        'status': 'active',
        'syncStatus': 'synced',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 3,
        'name': 'Sarah K.',
        'description': 'A pioneering scientist whose research advanced our understanding of renewable energy.',
        'category': 'Tribute',
        'version': '1.0',
        'imagePath': 'assets/images/memorial_card.jpeg', // Use existing asset
        'videoPath': 'assets/video/sample_video.mp4', // Placeholder
        'hologramPath': 'assets/video/sample_video.mp4', // Use video as hologram placeholder
        'audioPaths': ['assets/audio/sample_audio.mp3'], // Placeholder
        'qrCode': 'SARAH-K-MEMORIAL-003',
        'status': 'active',
        'syncStatus': 'synced',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];
    
    _tables['memorials']!.addAll(demoMemorials);
    print('Seeded ${demoMemorials.length} demo memorials');
    
    // Add associated media
    for (final memorial in demoMemorials) {
      await _addMemorialMedia(memorial['id'] as int, memorial);
    }
  }
  
  /// Add media for a memorial
  Future<void> _addMemorialMedia(int memorialId, Map<String, dynamic> memorialData) async {
    // Add image media
    if (memorialData['imagePath'] != null) {
      final imageMedia = {
        'id': memorialId * 10 + 1,
        'memorial_id': memorialId,
        'type': 'image',
        'title': '${memorialData['name']} - Main Image',
        'description': 'Primary memorial image',
        'local_path': memorialData['imagePath'],
        'remote_url': '',
        'file_size': 0,
        'file_type': 'jpeg',
        'mime_type': 'image/jpeg',
        'metadata': {},
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      _tables['media']!.add(imageMedia);
    }
    
    // Add video media
    if (memorialData['videoPath'] != null) {
      final videoMedia = {
        'id': memorialId * 10 + 2,
        'memorial_id': memorialId,
        'type': 'video',
        'title': '${memorialData['name']} - Memorial Video',
        'description': 'Memorial tribute video',
        'local_path': memorialData['videoPath'],
        'remote_url': '',
        'file_size': 0,
        'file_type': 'mp4',
        'mime_type': 'video/mp4',
        'metadata': {},
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      _tables['media']!.add(videoMedia);
    }
    
    // Add hologram media
    if (memorialData['hologramPath'] != null) {
      final hologramMedia = {
        'id': memorialId * 10 + 3,
        'memorial_id': memorialId,
        'type': 'hologram',
        'title': '${memorialData['name']} - Hologram',
        'description': 'AR hologram content',
        'local_path': memorialData['hologramPath'],
        'remote_url': '',
        'file_size': 0,
        'file_type': 'mp4',
        'mime_type': 'video/mp4',
        'metadata': {},
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      _tables['media']!.add(hologramMedia);
    }
  }
  
  /// Get database statistics
  Map<String, dynamic> getDatabaseStatistics() {
    return {
      'databasePath': 'web_storage',
      'databaseVersion': 1,
      'totalMemorials': _tables['memorials']!.length,
      'totalCategories': _tables['categories']!.length,
      'totalMedia': _tables['media']!.length,
      'tableCounts': {
        'categories': _tables['categories']!.length,
        'memorials': _tables['memorials']!.length,
        'media': _tables['media']!.length,
        'sync_log': _tables['sync_log']!.length,
      },
    };
  }
  
  /// Reset database (for development/testing)
  Future<void> resetDatabase() async {
    print('Resetting web storage...');
    
    try {
      // Clear all tables
      for (final tableName in _tables.keys) {
        _tables[tableName]!.clear();
      }
      
      // Re-seed data
      await initialize();
      
      print('✓ Web storage reset completed successfully');
    } catch (e) {
      print('❌ Error during web storage reset: $e');
      rethrow;
    }
  }
  
  /// Save data to localStorage
  Future<void> _saveToLocalStorage() async {
    try {
      // In a real web app, you would use html.window.localStorage
      // For now, we'll just print that we're saving
      print('Saving data to web storage...');
    } catch (e) {
      print('Error saving to localStorage: $e');
    }
  }
  
  /// Load data from localStorage
  Future<void> _loadFromLocalStorage() async {
    try {
      // In a real web app, you would use html.window.localStorage
      // For now, we'll just print that we're loading
      print('Loading data from web storage...');
    } catch (e) {
      print('Error loading from localStorage: $e');
    }
  }
} 