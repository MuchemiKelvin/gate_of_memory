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
        'description': 'A beloved mother and community leader who touched countless lives with her warmth and wisdom. Known for her exceptional cooking skills and ability to bring people together.',
        'category': 'Memorial',
        'version': '1.0',
        'image_path': 'assets/images/naomi_memorial.jpeg',
        'video_path': 'assets/video/naomi_memorial_video.mp4',
        'hologram_path': 'assets/animation/naomi_hologram.mp4',
        'audio_paths': ['assets/audio/naomi_voice_message.mp3', 'assets/audio/victory_chime.mp3'],
        'stories': [
          {
            'title': 'Early Life & Family',
            'snippet': 'Born in a small village in 1950, Naomi showed early signs of leadership and compassion...',
            'fullText': 'Born in a small village in 1950, Naomi showed early signs of leadership and compassion. She was the eldest of five children and often took care of her siblings while her parents worked in the fields. Her natural ability to bring people together was evident even in her childhood. She learned to cook from her grandmother, mastering traditional recipes that would later become famous in her community.',
          },
          {
            'title': 'Community Service & Leadership',
            'snippet': 'Throughout her life, Naomi dedicated herself to serving others...',
            'fullText': 'Throughout her life, Naomi dedicated herself to serving others. She founded the local women\'s cooperative, established a community library, and organized annual health camps. Her tireless work improved the lives of thousands in her community. She was known for her famous Sunday dinners, where she would feed anyone who came to her door, creating a sense of family among neighbors.',
          },
          {
            'title': 'Legacy of Love',
            'snippet': 'Naomi\'s greatest legacy was her ability to love unconditionally...',
            'fullText': 'Naomi\'s greatest legacy was her ability to love unconditionally. She raised three children of her own, but was a mother figure to dozens more in her community. Her home was always open, her table always had an extra place setting, and her heart had room for everyone. She taught us that family isn\'t just about blood, but about the bonds we create with those around us.',
          },
        ],
        'qr_code': 'NAOMI-N-MEMORIAL-001',
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'name': 'John M.',
        'description': 'A dedicated teacher who inspired generations of students to pursue their dreams. His innovative teaching methods and unwavering support changed countless lives.',
        'category': 'Celebration',
        'version': '1.0',
        'image_path': 'assets/images/john_memorial.jpeg',
        'video_path': 'assets/video/john_memorial_video.mp4',
        'hologram_path': 'assets/animation/john_hologram.mp4',
        'audio_paths': ['assets/audio/john_teaching_audio.mp3'],
        'stories': [
          {
            'title': 'Teaching Career & Innovation',
            'snippet': 'John spent 35 years as a mathematics teacher, revolutionizing how math was taught...',
            'fullText': 'John spent 35 years as a mathematics teacher at the local high school. His innovative teaching methods made complex concepts accessible to all students. He used real-world examples, interactive games, and hands-on projects to make math come alive. Many of his former students went on to become engineers, scientists, and educators themselves. His famous "Math in Motion" program is still used in schools today.',
          },
          {
            'title': 'Mentorship & Guidance',
            'snippet': 'Beyond the classroom, John was a mentor to many young people...',
            'fullText': 'Beyond the classroom, John was a mentor to many young people. He ran after-school programs, coached the math team, and provided guidance to students struggling with personal challenges. His door was always open to anyone who needed help. He had a special talent for recognizing potential in students who others had given up on, and he never stopped believing in them.',
          },
          {
            'title': 'Community Impact',
            'snippet': 'John\'s influence extended far beyond the school walls...',
            'fullText': 'John\'s influence extended far beyond the school walls. He organized community math nights, helped adults earn their GEDs, and volunteered at the local library. He believed that education was the key to breaking cycles of poverty and worked tirelessly to make learning accessible to everyone. His legacy lives on in the thousands of lives he touched and the educational programs he helped establish.',
          },
        ],
        'qr_code': 'JOHN-M-MEMORIAL-002',
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 3,
        'name': 'Sarah K.',
        'description': 'A pioneering scientist whose research advanced our understanding of renewable energy. Her groundbreaking work in solar technology and environmental advocacy continues to impact the world.',
        'category': 'Tribute',
        'version': '1.0',
        'image_path': 'assets/images/sarah_memorial.jpeg',
        'video_path': 'assets/video/sarah_memorial_video.mp4',
        'hologram_path': 'assets/animation/sarah_hologram.mp4',
        'audio_paths': ['assets/audio/sarah_scientific_talk.mp3'],
        'stories': [
          {
            'title': 'Scientific Breakthroughs & Innovation',
            'snippet': 'Sarah\'s research in solar energy technology led to several breakthrough innovations...',
            'fullText': 'Sarah\'s research in solar energy technology led to several breakthrough innovations. Her work on photovoltaic cell efficiency improved solar panel performance by 40%, making renewable energy more accessible to communities worldwide. She developed new materials and manufacturing processes that reduced costs while increasing durability. Her patents have been licensed by major solar companies and are used in installations around the globe.',
          },
          {
            'title': 'Environmental Advocacy & Leadership',
            'snippet': 'Beyond her scientific contributions, Sarah was a passionate environmental advocate...',
            'fullText': 'Beyond her scientific contributions, Sarah was a passionate environmental advocate. She spoke at international conferences, advised government agencies, and worked with communities to implement sustainable energy solutions. She founded the Global Solar Initiative, which has helped bring solar power to over 100,000 homes in developing countries. Her TED talks on renewable energy have been viewed by millions.',
          },
          {
            'title': 'Mentoring Future Scientists',
            'snippet': 'Sarah was committed to inspiring the next generation of scientists...',
            'fullText': 'Sarah was committed to inspiring the next generation of scientists. She mentored over 50 graduate students and postdoctoral researchers, many of whom have gone on to become leaders in renewable energy research. She established scholarship programs for women in STEM and regularly visited schools to encourage young people, especially girls, to pursue careers in science and engineering.',
          },
        ],
        'qr_code': 'SARAH-K-MEMORIAL-003',
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
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
    if (memorialData['image_path'] != null) {
      final imageMedia = {
        'id': memorialId * 10 + 1,
        'memorial_id': memorialId,
        'type': 'image',
        'title': '${memorialData['name']} - Main Image',
        'description': 'Primary memorial image',
        'local_path': memorialData['image_path'],
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
    if (memorialData['video_path'] != null) {
      final videoMedia = {
        'id': memorialId * 10 + 2,
        'memorial_id': memorialId,
        'type': 'video',
        'title': '${memorialData['name']} - Memorial Video',
        'description': 'Memorial tribute video',
        'local_path': memorialData['video_path'],
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
    if (memorialData['hologram_path'] != null) {
      final hologramMedia = {
        'id': memorialId * 10 + 3,
        'memorial_id': memorialId,
        'type': 'hologram',
        'title': '${memorialData['name']} - Hologram',
        'description': 'AR hologram content',
        'local_path': memorialData['hologram_path'],
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

    // Add audio media
    if (memorialData['audio_paths'] != null && (memorialData['audio_paths'] as List).isNotEmpty) {
      final audioPaths = List<String>.from(memorialData['audio_paths']);
      for (int i = 0; i < audioPaths.length; i++) {
        final audioMedia = {
          'id': memorialId * 10 + 4 + i,
          'memorial_id': memorialId,
          'type': 'audio',
          'title': '${memorialData['name']} - Audio ${i + 1}',
          'description': 'Memorial audio content',
          'local_path': audioPaths[i],
          'remote_url': '',
          'file_size': 0,
          'file_type': 'mp3',
          'mime_type': 'audio/mpeg',
          'metadata': {},
          'status': 'active',
          'sync_status': 'synced',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        _tables['media']!.add(audioMedia);
      }
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