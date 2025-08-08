import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/migrations.dart';
import '../services/database_helper.dart';

class ARMarkerDatabaseService {
  static final ARMarkerDatabaseService _instance = ARMarkerDatabaseService._internal();
  factory ARMarkerDatabaseService() => _instance;
  ARMarkerDatabaseService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Initialize marker database
  Future<void> initialize() async {
    try {
      print('Initializing AR marker database...');
      
      final db = await _dbHelper.database;
      
      // Create markers table if it doesn't exist
      await _createMarkersTable(db);
      
      // Seed initial markers
      await _seedInitialMarkers(db);
      
      print('AR marker database initialized successfully');
    } catch (e) {
      print('Error initializing AR marker database: $e');
      rethrow;
    }
  }

  /// Create markers table
  Future<void> _createMarkersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ar_markers (
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
  }

  /// Seed initial markers
  Future<void> _seedInitialMarkers(Database db) async {
    try {
      // Check if markers already exist
      final existingMarkers = await db.query('ar_markers');
      if (existingMarkers.isNotEmpty) {
        print('Markers already seeded, skipping...');
        return;
      }

      final now = DateTime.now().toIso8601String();
      
      // Insert initial markers
      await db.insert('ar_markers', {
        'marker_id': 'memorial_001',
        'name': 'Naomi Memorial',
        'type': 'memorial',
        'content_id': 'memorial_001',
        'position_x': 0.0,
        'position_y': 0.0,
        'position_z': 0.0,
        'scale': 1.0,
        'rotation': 0.0,
        'description': 'Memorial for Naomi',
        'metadata': '{"hologram": "naomi_hologram", "category": "family"}',
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('ar_markers', {
        'marker_id': 'memorial_002',
        'name': 'John Memorial',
        'type': 'memorial',
        'content_id': 'memorial_002',
        'position_x': 0.0,
        'position_y': 0.0,
        'position_z': 0.0,
        'scale': 1.0,
        'rotation': 0.0,
        'description': 'Memorial for John',
        'metadata': '{"hologram": "john_hologram", "category": "family"}',
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('ar_markers', {
        'marker_id': 'memorial_003',
        'name': 'Sarah Memorial',
        'type': 'memorial',
        'content_id': 'memorial_003',
        'position_x': 0.0,
        'position_y': 0.0,
        'position_z': 0.0,
        'scale': 1.0,
        'rotation': 0.0,
        'description': 'Memorial for Sarah',
        'metadata': '{"hologram": "sarah_hologram", "category": "family"}',
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('ar_markers', {
        'marker_id': 'test_marker_123',
        'name': 'Test Marker',
        'type': 'test',
        'content_id': 'test_content',
        'position_x': 0.0,
        'position_y': 0.0,
        'position_z': 0.0,
        'scale': 1.0,
        'rotation': 0.0,
        'description': 'Test AR marker for development',
        'metadata': '{"hologram": "test_hologram", "category": "test"}',
        'created_at': now,
        'updated_at': now,
      });

      print('Initial markers seeded successfully');
    } catch (e) {
      print('Error seeding initial markers: $e');
    }
  }

  /// Get all markers
  Future<List<ARMarker>> getAllMarkers() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query('ar_markers', where: 'status = ?', whereArgs: ['active']);
      
      return results.map((row) => ARMarker.fromMap(row)).toList();
    } catch (e) {
      print('Error getting all markers: $e');
      return [];
    }
  }

  /// Get marker by ID
  Future<ARMarker?> getMarkerById(String markerId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'ar_markers',
        where: 'marker_id = ? AND status = ?',
        whereArgs: [markerId, 'active'],
      );
      
      if (results.isNotEmpty) {
        return ARMarker.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Error getting marker by ID: $e');
      return null;
    }
  }

  /// Get markers by type
  Future<List<ARMarker>> getMarkersByType(String type) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'ar_markers',
        where: 'type = ? AND status = ?',
        whereArgs: [type, 'active'],
      );
      
      return results.map((row) => ARMarker.fromMap(row)).toList();
    } catch (e) {
      print('Error getting markers by type: $e');
      return [];
    }
  }

  /// Add new marker
  Future<bool> addMarker(ARMarker marker) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      
      await db.insert('ar_markers', {
        'marker_id': marker.markerId,
        'name': marker.name,
        'type': marker.type,
        'content_id': marker.contentId,
        'position_x': marker.position['x'],
        'position_y': marker.position['y'],
        'position_z': marker.position['z'],
        'scale': marker.scale,
        'rotation': marker.rotation,
        'description': marker.description,
        'metadata': marker.metadata,
        'created_at': now,
        'updated_at': now,
      });
      
      print('Marker added successfully: ${marker.markerId}');
      return true;
    } catch (e) {
      print('Error adding marker: $e');
      return false;
    }
  }

  /// Update marker
  Future<bool> updateMarker(ARMarker marker) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      
      await db.update(
        'ar_markers',
        {
          'name': marker.name,
          'type': marker.type,
          'content_id': marker.contentId,
          'position_x': marker.position['x'],
          'position_y': marker.position['y'],
          'position_z': marker.position['z'],
          'scale': marker.scale,
          'rotation': marker.rotation,
          'description': marker.description,
          'metadata': marker.metadata,
          'updated_at': now,
        },
        where: 'marker_id = ?',
        whereArgs: [marker.markerId],
      );
      
      print('Marker updated successfully: ${marker.markerId}');
      return true;
    } catch (e) {
      print('Error updating marker: $e');
      return false;
    }
  }

  /// Delete marker
  Future<bool> deleteMarker(String markerId) async {
    try {
      final db = await _dbHelper.database;
      
      await db.update(
        'ar_markers',
        {'status': 'deleted', 'updated_at': DateTime.now().toIso8601String()},
        where: 'marker_id = ?',
        whereArgs: [markerId],
      );
      
      print('Marker deleted successfully: $markerId');
      return true;
    } catch (e) {
      print('Error deleting marker: $e');
      return false;
    }
  }

  /// Search markers
  Future<List<ARMarker>> searchMarkers(String query) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'ar_markers',
        where: '(name LIKE ? OR description LIKE ?) AND status = ?',
        whereArgs: ['%$query%', '%$query%', 'active'],
      );
      
      return results.map((row) => ARMarker.fromMap(row)).toList();
    } catch (e) {
      print('Error searching markers: $e');
      return [];
    }
  }

  /// Get marker statistics
  Future<Map<String, dynamic>> getMarkerStats() async {
    try {
      final db = await _dbHelper.database;
      
      final totalMarkers = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ar_markers WHERE status = ?', ['active'])
      ) ?? 0;
      
      final memorialMarkers = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ar_markers WHERE type = ? AND status = ?', ['memorial', 'active'])
      ) ?? 0;
      
      final testMarkers = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ar_markers WHERE type = ? AND status = ?', ['test', 'active'])
      ) ?? 0;
      
      return {
        'totalMarkers': totalMarkers,
        'memorialMarkers': memorialMarkers,
        'testMarkers': testMarkers,
        'activeMarkers': totalMarkers,
      };
    } catch (e) {
      print('Error getting marker stats: $e');
      return {
        'totalMarkers': 0,
        'memorialMarkers': 0,
        'testMarkers': 0,
        'activeMarkers': 0,
      };
    }
  }

  /// Clear all markers
  Future<void> clearAllMarkers() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('ar_markers');
      print('All markers cleared');
    } catch (e) {
      print('Error clearing markers: $e');
    }
  }

  /// Dispose database service
  void dispose() {
    print('AR marker database service disposed');
  }
}

/// AR Marker Model
class ARMarker {
  final int? id;
  final String markerId;
  final String name;
  final String type;
  final String? contentId;
  final Map<String, double> position;
  final double scale;
  final double rotation;
  final String? description;
  final String? metadata;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ARMarker({
    this.id,
    required this.markerId,
    required this.name,
    required this.type,
    this.contentId,
    required this.position,
    required this.scale,
    required this.rotation,
    this.description,
    this.metadata,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ARMarker.fromMap(Map<String, dynamic> map) {
    return ARMarker(
      id: map['id'],
      markerId: map['marker_id'],
      name: map['name'],
      type: map['type'],
      contentId: map['content_id'],
      position: {
        'x': map['position_x'] ?? 0.0,
        'y': map['position_y'] ?? 0.0,
        'z': map['position_z'] ?? 0.0,
      },
      scale: map['scale'] ?? 1.0,
      rotation: map['rotation'] ?? 0.0,
      description: map['description'],
      metadata: map['metadata'],
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'marker_id': markerId,
      'name': name,
      'type': type,
      'content_id': contentId,
      'position_x': position['x'],
      'position_y': position['y'],
      'position_z': position['z'],
      'scale': scale,
      'rotation': rotation,
      'description': description,
      'metadata': metadata,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'markerId': markerId,
      'name': name,
      'type': type,
      'contentId': contentId,
      'position': position,
      'scale': scale,
      'rotation': rotation,
      'description': description,
      'metadata': metadata,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ARMarker(markerId: $markerId, name: $name, type: $type)';
  }
} 