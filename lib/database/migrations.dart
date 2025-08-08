import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static const int currentVersion = 2;

  static Future<void> migrateToVersion1(Database db) async {
    print('Migrating to version 1...');
    
    // Create categories table
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

    // Create memorials table
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

    // Create media table
    await db.execute('''
      CREATE TABLE media (
        id INTEGER PRIMARY KEY,
        memorial_id INTEGER,
        type TEXT NOT NULL,
        path TEXT NOT NULL,
        title TEXT,
        description TEXT,
        duration INTEGER,
        size INTEGER,
        metadata TEXT,
        status TEXT DEFAULT 'active',
        sync_status TEXT DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (memorial_id) REFERENCES memorials (id)
      )
    ''');

    print('Migration to version 1 completed');
  }

  static Future<void> migrateToVersion2(Database db) async {
    print('Migrating to version 2...');
    
    // Create AR markers table
    await db.execute('''
      CREATE TABLE ar_markers (
        id INTEGER PRIMARY KEY,
        marker_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        content_id TEXT,
        position_x REAL DEFAULT 0.0,
        position_y REAL DEFAULT 0.0,
        position_z REAL DEFAULT 0.0,
        scale REAL DEFAULT 1.0,
        rotation REAL DEFAULT 0.0,
        description TEXT,
        metadata TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create AR photos table
    await db.execute('''
      CREATE TABLE ar_photos (
        id INTEGER PRIMARY KEY,
        photo_id TEXT UNIQUE NOT NULL,
        path TEXT NOT NULL,
        marker_id TEXT,
        ar_content TEXT,
        metadata TEXT,
        format TEXT DEFAULT 'jpg',
        quality INTEGER DEFAULT 90,
        size INTEGER,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create AR sessions table
    await db.execute('''
      CREATE TABLE ar_sessions (
        id INTEGER PRIMARY KEY,
        session_id TEXT UNIQUE NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration INTEGER,
        marker_count INTEGER DEFAULT 0,
        photo_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    print('Migration to version 2 completed');
  }

  static Future<void> getMigrationStatus(Database db) async {
    try {
      final version = await db.getVersion();
      print('Current database version: $version');
      
      // Check if tables exist
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      final tableNames = tables.map((row) => row['name'] as String).toList();
      
      print('Existing tables: $tableNames');
      
      // Check table counts
      for (final tableName in tableNames) {
        if (tableName != 'sqlite_master' && tableName != 'android_metadata') {
          final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName')) ?? 0;
          print('Table $tableName: $count records');
        }
      }
      
    } catch (e) {
      print('Error getting migration status: $e');
    }
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 1) {
      await migrateToVersion1(db);
    }
    
    if (oldVersion < 2) {
      await migrateToVersion2(db);
    }
    
    print('Database upgrade completed');
  }
} 