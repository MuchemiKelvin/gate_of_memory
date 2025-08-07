import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/migrations.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'kardiverse_mobile.db');
    return await openDatabase(
      path,
      version: DatabaseMigrations.currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Use the migrations system for database upgrades
    await DatabaseMigrations.runMigrations(db, oldVersion, newVersion);
  }

  Future<void> _insertDefaultCategories(Database db) async {
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
  }

  // Database operations
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'kardiverse_mobile.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Helper method to check if database exists
  Future<bool> databaseExists() async {
    String path = join(await getDatabasesPath(), 'kardiverse_mobile.db');
    return await databaseFactory.databaseExists(path);
  }

  // Helper method to get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
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
      'version': await db.getVersion(),
      'path': db.path,
      'tableCounts': tableCounts,
    };
  }

  // Reset the singleton instance
  void resetInstance() {
    _database = null;
  }
} 