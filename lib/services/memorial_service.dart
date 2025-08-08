import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/memorial.dart';
import '../models/category.dart';
import '../models/media.dart';
import 'database_helper.dart';

class MemorialService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Category Operations
  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'sort_order ASC',
    );
    return List.generate(maps.length, (i) => Category.fromJson(maps[i]));
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromJson(maps.first);
    }
    return null;
  }

  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toJson());
  }

  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categories',
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Memorial Operations
  Future<List<Memorial>> getAllMemorials() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memorials',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => _mapToMemorial(maps[i]));
  }

  Future<List<Memorial>> getMemorialsByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memorials',
      where: 'category = ? AND deleted_at IS NULL',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => _mapToMemorial(maps[i]));
  }

  Future<Memorial?> getMemorialById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memorials',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _mapToMemorial(maps.first);
    }
    return null;
  }

  /// Get memorial by QR code
  Future<Memorial?> getMemorialByQRCode(String qrCode) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'memorials',
        where: 'qr_code = ? AND deleted_at IS NULL',
        whereArgs: [qrCode],
      );
      if (maps.isNotEmpty) {
        return _mapToMemorial(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting memorial by QR code: $e');
      return null;
    }
  }

  /// Validate QR code exists in database
  Future<bool> isValidQRCode(String qrCode) async {
    try {
      final memorial = await getMemorialByQRCode(qrCode);
      return memorial != null;
    } catch (e) {
      print('Error validating QR code: $e');
      return false;
    }
  }

  Future<int> insertMemorial(Memorial memorial) async {
    final db = await _dbHelper.database;
    return await db.insert('memorials', _memorialToMap(memorial));
  }

  Future<int> updateMemorial(Memorial memorial) async {
    final db = await _dbHelper.database;
    return await db.update(
      'memorials',
      _memorialToMap(memorial),
      where: 'id = ?',
      whereArgs: [memorial.id],
    );
  }

  Future<int> deleteMemorial(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'memorials',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hardDeleteMemorial(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'memorials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Media Operations
  Future<List<Media>> getMediaByMemorialId(int memorialId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media',
      where: 'memorial_id = ? AND status = ?',
      whereArgs: [memorialId, 'active'],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => _mapToMedia(maps[i]));
  }

  Future<Media?> getMediaById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _mapToMedia(maps.first);
    }
    return null;
  }

  Future<int> insertMedia(Media media) async {
    final db = await _dbHelper.database;
    return await db.insert('media', _mediaToMap(media));
  }

  Future<int> updateMedia(Media media) async {
    final db = await _dbHelper.database;
    return await db.update(
      'media',
      _mediaToMap(media),
      where: 'id = ?',
      whereArgs: [media.id],
    );
  }

  Future<int> deleteMedia(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'media',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search Operations
  Future<List<Memorial>> searchMemorials(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memorials',
      where: '(name LIKE ? OR description LIKE ?) AND deleted_at IS NULL',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => _mapToMemorial(maps[i]));
  }

  // Statistics
  Future<Map<String, int>> getMemorialStatistics() async {
    final db = await _dbHelper.database;
    final totalMemorials = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM memorials WHERE deleted_at IS NULL')
    ) ?? 0;
    
    final totalMedia = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM media WHERE status = ?', ['active'])
    ) ?? 0;
    
    final totalCategories = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories WHERE status = ?', ['active'])
    ) ?? 0;

    return {
      'totalMemorials': totalMemorials,
      'totalMedia': totalMedia,
      'totalCategories': totalCategories,
    };
  }

  // Helper methods for data conversion
  Memorial _mapToMemorial(Map<String, dynamic> map) {
    return Memorial(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      category: map['category'] ?? 'memorial',
      version: map['version'] ?? '1.0',
      imagePath: map['image_path'] ?? '',
      videoPath: map['video_path'] ?? '',
      hologramPath: map['hologram_path'] ?? '',
      audioPaths: _parseStringList(map['audio_paths']),
      stories: _parseStories(map['stories']),
      qrCode: map['qr_code'] ?? '',
      status: map['status'] ?? 'active',
      syncStatus: map['sync_status'] ?? 'synced',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  Map<String, dynamic> _memorialToMap(Memorial memorial) {
    return {
      'id': memorial.id,
      'name': memorial.name,
      'description': memorial.description,
      'category': memorial.category,
      'version': memorial.version,
      'image_path': memorial.imagePath,
      'video_path': memorial.videoPath,
      'hologram_path': memorial.hologramPath,
      'audio_paths': jsonEncode(memorial.audioPaths),
      'stories': jsonEncode(memorial.stories.map((s) => s.toJson()).toList()),
      'qr_code': memorial.qrCode,
      'status': memorial.status,
      'sync_status': memorial.syncStatus,
      'created_at': memorial.createdAt.toIso8601String(),
      'updated_at': memorial.updatedAt.toIso8601String(),
      'deleted_at': memorial.deletedAt?.toIso8601String(),
    };
  }

  Media _mapToMedia(Map<String, dynamic> map) {
    return Media(
      id: map['id'],
      memorialId: map['memorial_id'],
      type: MediaType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MediaType.image,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      localPath: map['local_path'] ?? '',
      remoteUrl: map['remote_url'] ?? '',
      fileSize: map['file_size'] ?? 0,
      fileType: map['file_type'] ?? '',
      mimeType: map['mime_type'] ?? '',
      metadata: _parseMetadata(map['metadata']),
      status: map['status'] ?? 'active',
      syncStatus: map['sync_status'] ?? 'synced',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> _mediaToMap(Media media) {
    return {
      'id': media.id,
      'memorial_id': media.memorialId,
      'type': media.type.toString().split('.').last,
      'title': media.title,
      'description': media.description,
      'local_path': media.localPath,
      'remote_url': media.remoteUrl,
      'file_size': media.fileSize,
      'file_type': media.fileType,
      'mime_type': media.mimeType,
      'metadata': jsonEncode(media.metadata),
      'status': media.status,
      'sync_status': media.syncStatus,
      'created_at': media.createdAt.toIso8601String(),
      'updated_at': media.updatedAt.toIso8601String(),
    };
  }

  List<String> _parseStringList(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  List<Story> _parseStories(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => Story.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _parseMetadata(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      return {};
    }
  }
} 