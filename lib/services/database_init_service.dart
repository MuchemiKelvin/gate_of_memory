import 'package:sqflite/sqflite.dart';
import '../database/migrations.dart';
import '../models/memorial.dart';
import '../models/media.dart';
import 'database_helper.dart';
import 'memorial_service.dart';
import '../models/category.dart';
import 'package:flutter/foundation.dart';
import 'web_storage_service.dart';

class DatabaseInitService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MemorialService _memorialService = MemorialService();
  final WebStorageService _webStorage = WebStorageService.instance;

  // Initialize the complete database system
  Future<void> initializeDatabase() async {
    try {
      print('Starting database initialization...');
      
      if (kIsWeb) {
        // Use web storage for web platform
        print('Web platform detected, using web storage service');
        await _webStorage.initialize();
        print('Web storage initialized successfully');
      } else {
        // Use SQLite for mobile/desktop platforms
        print('Native platform detected, using SQLite database');
        
        // Get database instance (this will trigger migrations if needed)
        final db = await _dbHelper.database;
        
        // Check migration status
        await DatabaseMigrations.getMigrationStatus(db);
        
        // Validate database integrity
        await _validateDatabaseIntegrity(db);
        
        // Seed initial data if needed
        await _seedInitialData();
      }
      
      print('Database initialization completed successfully');
    } catch (e) {
      print('Error during database initialization: $e');
      rethrow;
    }
  }

  // Validate database integrity
  Future<void> _validateDatabaseIntegrity(Database db) async {
    print('Validating database integrity...');
    
    // Check if all required tables exist
    final requiredTables = ['categories', 'memorials', 'media', 'sync_log'];
    final existingTables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    final tableNames = existingTables.map((t) => t['name'] as String).toList();
    
    for (final table in requiredTables) {
      if (!tableNames.contains(table)) {
        print('Warning: Required table "$table" is missing from database. Attempting to create...');
        try {
          await _createMissingTable(db, table);
          print('Successfully created missing table: $table');
        } catch (e) {
          print('Failed to create missing table $table: $e');
          throw Exception('Required table "$table" is missing from database and could not be created: $e');
        }
      }
    }
    
    // Check if default categories exist
    final categories = await _memorialService.getAllCategories();
    if (categories.isEmpty) {
      print('Warning: No categories found in database');
    }
    
    print('Database integrity validation passed');
  }

  // Create missing table if needed
  Future<void> _createMissingTable(Database db, String tableName) async {
    switch (tableName) {
      case 'sync_log':
        await db.execute('''
          CREATE TABLE sync_log (
            id INTEGER PRIMARY KEY,
            operation TEXT NOT NULL,
            table_name TEXT NOT NULL,
            record_id INTEGER,
            status TEXT NOT NULL,
            error_message TEXT,
            sync_timestamp TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        break;
      case 'categories':
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            icon TEXT,
            color TEXT,
            sort_order INTEGER DEFAULT 0,
            memorial_count INTEGER DEFAULT 0,
            status TEXT DEFAULT 'active',
            sync_status TEXT DEFAULT 'synced',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        break;
      case 'memorials':
        await db.execute('''
          CREATE TABLE memorials (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            category TEXT DEFAULT 'memorial',
            version TEXT DEFAULT '1.0',
            image_path TEXT,
            video_path TEXT,
            hologram_path TEXT,
            audio_paths TEXT,
            stories TEXT,
            qr_code TEXT,
            status TEXT DEFAULT 'active',
            sync_status TEXT DEFAULT 'synced',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');
        break;
      case 'media':
        await db.execute('''
          CREATE TABLE media (
            id INTEGER PRIMARY KEY,
            memorial_id INTEGER,
            type TEXT NOT NULL,
            title TEXT,
            description TEXT,
            local_path TEXT,
            remote_url TEXT,
            file_size INTEGER,
            file_type TEXT,
            mime_type TEXT,
            metadata TEXT,
            status TEXT DEFAULT 'active',
            sync_status TEXT DEFAULT 'synced',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (memorial_id) REFERENCES memorials (id)
          )
        ''');
        break;
      default:
        throw Exception('Unknown table type: $tableName');
    }
  }

  // Seed initial data
  Future<void> _seedInitialData() async {
    print('Seeding initial data...');
    
    // Seed default categories if none exist
    try {
      final existingCategories = await _memorialService.getAllCategories();
      if (existingCategories.isEmpty) {
        print('No categories found. Seeding default categories...');
        for (final category in PredefinedCategories.defaultCategories) {
          await _memorialService.insertCategory(category);
          print('Inserted category: ${category.name}');
        }
      }
    } catch (e) {
      print('Error seeding default categories: $e');
    }

    // Check if we need to seed demo memorials
    final existingMemorials = await _memorialService.getAllMemorials();
    print('Existing memorials found: ${existingMemorials.length}');
    
    if (existingMemorials.isEmpty) {
      await _seedDemoMemorials();
    } else {
      print('Memorials already exist, skipping seeding. Use resetDatabase() to re-seed.');
      // For debugging, let's check what's in the database
      await _checkDatabaseContents();
    }
    
    print('Initial data seeding completed');
  }

  // Force re-seed database (for debugging)
  Future<void> forceReseed() async {
    print('Force re-seeding database...');
    
    final db = await _dbHelper.database;
    
    // Clear existing data
    await db.delete('media');
    await db.delete('memorials');
    print('Cleared existing memorial and media data');
    
    // Re-seed
    await _seedDemoMemorials();
    print('Force re-seeding completed');
  }

  // Seed demo memorials for testing
  Future<void> _seedDemoMemorials() async {
    print('Seeding demo memorials...');
    
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
      },
    ];

    for (final memorialData in demoMemorials) {
      try {
        print('Inserting memorial: ${memorialData['name']}');
        final memorial = _createMemorialFromData(memorialData);
        final memorialId = await _memorialService.insertMemorial(memorial);
        print('Inserted memorial with ID: $memorialId');
        
        // Add associated media
        await _addMemorialMedia(memorial.id, memorialData);
        print('Added media for memorial: ${memorialData['name']}');
      } catch (e) {
        print('Error inserting memorial ${memorialData['name']}: $e');
      }
    }
    
    // Check what was actually inserted
    await _checkDatabaseContents();
    
    print('Demo memorials seeded successfully');
  }

  // Debug method to check database contents
  Future<void> _checkDatabaseContents() async {
    print('=== DATABASE CONTENTS CHECK ===');
    
    final db = await _dbHelper.database;
    
    // Check memorials
    final memorials = await db.query('memorials');
    print('Memorials in database: ${memorials.length}');
    for (final memorial in memorials) {
      print('  - ID: ${memorial['id']}, Name: ${memorial['name']}, Category: ${memorial['category']}');
      print('    Image Path: "${memorial['image_path']}"');
      print('    Video Path: "${memorial['video_path']}"');
      print('    Hologram Path: "${memorial['hologram_path']}"');
      print('    Audio Paths: "${memorial['audio_paths']}"');
      print('    Stories: "${memorial['stories']}"');
      print('    QR Code: "${memorial['qr_code']}"');
    }
    
    // Check media
    final media = await db.query('media');
    print('Media in database: ${media.length}');
    for (final item in media) {
      print('  - ID: ${item['id']}, Memorial ID: ${item['memorial_id']}, Type: ${item['type']}, Title: ${item['title']}');
      print('    Local Path: "${item['local_path']}"');
    }
    
    // Check categories
    final categories = await db.query('categories');
    print('Categories in database: ${categories.length}');
    for (final category in categories) {
      print('  - ID: ${category['id']}, Name: ${category['name']}');
    }
    
    print('=== END DATABASE CONTENTS CHECK ===');
  }

  // Helper method to create Memorial object from data
  Memorial _createMemorialFromData(Map<String, dynamic> data) {
    print('=== CREATING MEMORIAL OBJECT ===');
    print('Raw data: $data');
    
    final memorial = Memorial(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      category: data['category'],
      version: data['version'],
      imagePath: data['image_path'] ?? data['imagePath'] ?? '',
      videoPath: data['video_path'] ?? data['videoPath'] ?? '',
      hologramPath: data['hologram_path'] ?? data['hologramPath'] ?? '',
      audioPaths: List<String>.from(data['audio_paths'] ?? data['audioPaths'] ?? []),
      stories: (data['stories'] as List?)?.map((storyData) => Story(
        title: storyData['title'],
        snippet: storyData['snippet'],
        fullText: storyData['fullText'],
      )).toList() ?? [],
      qrCode: data['qr_code'] ?? data['qrCode'] ?? '',
      status: data['status'],
      syncStatus: data['sync_status'] ?? data['syncStatus'] ?? 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    print('Created Memorial object:');
    print('  - ID: ${memorial.id}');
    print('  - Name: ${memorial.name}');
    print('  - Image Path: "${memorial.imagePath}"');
    print('  - Video Path: "${memorial.videoPath}"');
    print('  - Hologram Path: "${memorial.hologramPath}"');
    print('  - Audio Paths: ${memorial.audioPaths}');
    print('  - Stories: ${memorial.stories.length}');
    print('  - QR Code: ${memorial.qrCode}');
    print('=== END MEMORIAL OBJECT ===');
    
    return memorial;
  }

  // Helper method to add media for a memorial
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
      await _memorialService.insertMedia(Media.fromJson(imageMedia));
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
      await _memorialService.insertMedia(Media.fromJson(videoMedia));
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
      await _memorialService.insertMedia(Media.fromJson(hologramMedia));
    }
  }

  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    if (kIsWeb) {
      // Return web storage statistics
      return _webStorage.getDatabaseStatistics();
    } else {
      // Return SQLite database statistics
      final db = await _dbHelper.database;
      await DatabaseMigrations.getMigrationStatus(db);
      final memorialStats = await _memorialService.getMemorialStatistics();
      
      return {
        ...memorialStats,
        'databasePath': db.path,
        'databaseVersion': await db.getVersion(),
      };
    }
  }

  // Reset database (for development/testing)
  Future<void> resetDatabase() async {
    print('Resetting database...');
    
    try {
      if (kIsWeb) {
        // Reset web storage
        print('Web platform detected, resetting web storage');
        await _webStorage.resetDatabase();
      } else {
        // Reset SQLite database
        print('Native platform detected, resetting SQLite database');
        
        print('Step 1: Closing existing database connection...');
        // Close existing database connection
        await _dbHelper.close();
        DatabaseHelper.resetInstance();
        print('✓ Database connection closed and instance reset');
        
        print('Step 2: Re-initializing database system...');
        // Re-initialize the database system (not the platform factory)
        await initializeDatabase();
        print('✓ Database system re-initialized');
      }
      
      print('✓ Database reset completed successfully');
    } catch (e, stackTrace) {
      print('❌ Error during database reset: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Backup database
  Future<void> backupDatabase() async {
    print('Creating database backup...');
    final db = await _dbHelper.database;
    // TODO: Implement backup functionality
    print('Database backup completed');
  }
} 