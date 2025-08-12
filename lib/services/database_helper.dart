import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/migrations.dart';
import 'package:flutter/foundation.dart';

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
    try {
      // Check if we're on web platform
      if (kIsWeb) {
        throw UnsupportedError('SQLite database is not supported on web platform. Use web storage instead.');
      }
      
      String path = join(await getDatabasesPath(), 'kardiverse_mobile.db');
      print('Initializing database at: $path');
      
      return await openDatabase(
        path,
        version: DatabaseMigrations.currentVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('❌ Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database with version $version');
    
    if (version >= 1) {
      await DatabaseMigrations.migrateToVersion1(db);
    }
    
    if (version >= 2) {
      await DatabaseMigrations.migrateToVersion2(db);
    }

    if (version >= 3) {
      await DatabaseMigrations.migrateToVersion3(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    await DatabaseMigrations.onUpgrade(db, oldVersion, newVersion);
  }

  /// Reset database instance (for testing)
  static void resetInstance() {
    _database = null;
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await database;
      final version = await db.getVersion();
      
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      final tableNames = tables.map((row) => row['name'] as String).toList();
      
      Map<String, int> tableCounts = {};
      for (final tableName in tableNames) {
        if (tableName != 'sqlite_master' && tableName != 'android_metadata') {
          final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName')) ?? 0;
          tableCounts[tableName] = count;
        }
      }
      
      return {
        'version': version,
        'tables': tableNames,
        'tableCounts': tableCounts,
        'totalRecords': tableCounts.values.fold(0, (sum, count) => sum + count),
      };
    } catch (e) {
      print('Error getting database stats: $e');
      return {
        'version': 0,
        'tables': [],
        'tableCounts': {},
        'totalRecords': 0,
        'error': e.toString(),
      };
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('Database closed');
    }
  }
} 