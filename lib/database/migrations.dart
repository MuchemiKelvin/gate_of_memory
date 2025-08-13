import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static const int currentVersion = 3;

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

    // Create sync_log table
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

  static Future<void> migrateToVersion3(Database db) async {
    print('Migrating to version 3...');
    
    // Ensure sync_log table exists (fix for missing table issue)
    try {
      final syncLogExists = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table" AND name="sync_log"');
      if (syncLogExists.isEmpty) {
        print('Creating missing sync_log table...');
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
        print('sync_log table created successfully');
      } else {
        print('sync_log table already exists');
      }
    } catch (e) {
      print('Error creating sync_log table: $e');
    }
    
    // Inspect existing media table schema
    try {
      final columns = await db.rawQuery('PRAGMA table_info(media)');
      final existingColumnNames = columns.map((c) => (c['name'] as String)).toSet();

      // If media already has the new schema, skip migration
      if (existingColumnNames.contains('local_path')) {
        print('Media table already in new schema. Skipping v3 migration.');
        // Ensure any previous failed attempt leftovers are cleared
        await db.execute('DROP TABLE IF EXISTS media_new');
        print('Migration to version 3 completed (no-op)');
        return;
      }

      // Create new table with desired schema
      await db.execute('''
        CREATE TABLE IF NOT EXISTS media_new (
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

      // Determine best-effort column mapping from old schema
      final hasPath = existingColumnNames.contains('path');
      final hasSize = existingColumnNames.contains('size');

      if (hasPath || hasSize) {
        // Old schema -> map path/size into new columns
        await db.execute('''
          INSERT INTO media_new (
            id, memorial_id, type, title, description,
            local_path, remote_url, file_size, file_type, mime_type,
            metadata, status, sync_status, created_at, updated_at
          )
          SELECT
            id, memorial_id, type, title, description,
            ${hasPath ? 'path' : "''"} as local_path,
            '' as remote_url,
            ${hasSize ? 'size' : '0'} as file_size,
            '' as file_type,
            '' as mime_type,
            metadata, status, sync_status, created_at, updated_at
          FROM media
        ''');
      } else {
        // Unknown/partial schema: copy what we can (id and required fields), leave others empty
        await db.execute('''
          INSERT INTO media_new (
            id, memorial_id, type, title, description,
            local_path, remote_url, file_size, file_type, mime_type,
            metadata, status, sync_status, created_at, updated_at
          )
          SELECT
            id,
            COALESCE(memorial_id, 0),
            type,
            COALESCE(title, ''),
            COALESCE(description, ''),
            '' as local_path,
            '' as remote_url,
            0 as file_size,
            '' as file_type,
            '' as mime_type,
            COALESCE(metadata, '{}'),
            COALESCE(status, 'active'),
            COALESCE(sync_status, 'synced'),
            created_at,
            updated_at
          FROM media
        ''');
      }

      // Replace old table atomically
      await db.execute('DROP TABLE IF EXISTS media');
      await db.execute('ALTER TABLE media_new RENAME TO media');
      print('Migration to version 3 completed');
    } catch (e) {
      // If anything goes wrong, ensure we don't leave temp tables around
      print('Migration to version 3 encountered an issue: $e');
      await db.execute('DROP TABLE IF EXISTS media_new');
      // Leave existing media table untouched
      print('Migration to version 3 completed (fallback, no schema change)');
    }
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
    
    if (oldVersion < 3) {
      await migrateToVersion3(db);
    }
    
    print('Database upgrade completed');
  }
} 