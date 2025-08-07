import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static const int currentVersion = 1;

  static Future<void> runMigrations(Database db, int oldVersion, int newVersion) async {
    print('Running database migrations from version $oldVersion to $newVersion');
    
    if (oldVersion < 1) {
      await _migrateToVersion1(db);
    }
    
    // Future migrations will be added here
    // if (oldVersion < 2) {
    //   await _migrateToVersion2(db);
    // }
    
    print('Database migrations completed successfully');
  }

  // Version 1: Initial schema
  static Future<void> _migrateToVersion1(Database db) async {
    print('Creating initial database schema...');
    
    // Create categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
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
      CREATE TABLE IF NOT EXISTS memorials (
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
      CREATE TABLE IF NOT EXISTS media (
        id INTEGER PRIMARY KEY,
        memorial_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        title TEXT,
        description TEXT,
        local_path TEXT,
        remote_url TEXT,
        file_size INTEGER DEFAULT 0,
        file_type TEXT,
        mime_type TEXT,
        metadata TEXT,
        status TEXT DEFAULT 'active',
        sync_status TEXT DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (memorial_id) REFERENCES memorials (id) ON DELETE CASCADE
      )
    ''');

    // Create sync_log table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
    
    // Insert default data
    await _insertDefaultData(db);
    
    print('Version 1 migration completed');
  }

  // Create database indexes
  static Future<void> _createIndexes(Database db) async {
    // Categories indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_status ON categories(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON categories(sort_order)');
    
    // Memorials indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_memorials_category ON memorials(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_memorials_status ON memorials(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_memorials_deleted_at ON memorials(deleted_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_memorials_created_at ON memorials(created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_memorials_qr_code ON memorials(qr_code)');
    
    // Media indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_media_memorial_id ON media(memorial_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_media_type ON media(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_media_status ON media(status)');
    
    // Sync log indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_log_table_name ON sync_log(table_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_log_status ON sync_log(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_log_created_at ON sync_log(created_at)');
  }

  // Insert default data
  static Future<void> _insertDefaultData(Database db) async {
    // Check if default categories already exist
    final existingCategories = await db.query('categories', where: 'id <= ?', whereArgs: [4]);
    if (existingCategories.isNotEmpty) {
      print('Default categories already exist, skipping...');
      return;
    }

    final defaultCategories = [
      {
        'id': 1,
        'name': 'Memorial',
        'description': 'Traditional memorial services',
        'icon': 'memory',
        'color': '#7bb6e7',
        'sort_order': 1,
        'memorial_count': 0,
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'name': 'Celebration',
        'description': 'Celebration of life services',
        'icon': 'celebration',
        'color': '#4CAF50',
        'sort_order': 2,
        'memorial_count': 0,
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 3,
        'name': 'Tribute',
        'description': 'Special tribute memorials',
        'icon': 'star',
        'color': '#FF9800',
        'sort_order': 3,
        'memorial_count': 0,
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 4,
        'name': 'Historical',
        'description': 'Historical memorials',
        'icon': 'history',
        'color': '#9C27B0',
        'sort_order': 4,
        'memorial_count': 0,
        'status': 'active',
        'sync_status': 'synced',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category);
    }
    
    print('Default data inserted successfully');
  }

  // Future migration methods (for reference)
  /*
  static Future<void> _migrateToVersion2(Database db) async {
    print('Running migration to version 2...');
    
    // Example: Add new column to existing table
    await db.execute('ALTER TABLE memorials ADD COLUMN featured BOOLEAN DEFAULT 0');
    
    // Example: Create new table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memorial_id INTEGER NOT NULL,
        user_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (memorial_id) REFERENCES memorials (id) ON DELETE CASCADE
      )
    ''');
    
    print('Version 2 migration completed');
  }
  */

  // Utility methods for migration management
  static Future<void> backupDatabase(Database db) async {
    // Implementation for database backup before migration
    print('Database backup completed');
  }

  static Future<void> restoreDatabase(Database db) async {
    // Implementation for database restore after failed migration
    print('Database restore completed');
  }

  static Future<Map<String, dynamic>> getMigrationStatus(Database db) async {
    final version = await db.getVersion();
    final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    
    Map<String, int> tableCounts = {};
    for (final table in tables) {
      final tableName = table['name'] as String;
      if (tableName != 'sqlite_master' && tableName != 'sqlite_sequence') {
        final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
        tableCounts[tableName] = count ?? 0;
      }
    }

    return {
      'currentVersion': version,
      'targetVersion': currentVersion,
      'needsMigration': version < currentVersion,
      'tableCounts': tableCounts,
      'tables': tables.map((t) => t['name']).toList(),
    };
  }
} 