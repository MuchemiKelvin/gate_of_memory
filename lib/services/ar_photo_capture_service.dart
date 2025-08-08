import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;

class ARPhotoCaptureService {
  static final ARPhotoCaptureService _instance = ARPhotoCaptureService._internal();
  factory ARPhotoCaptureService() => _instance;
  ARPhotoCaptureService._internal();

  bool _isActive = false;
  bool _isCapturing = false;
  
  // Photo capture settings
  String _photoFormat = 'jpg';
  int _photoQuality = 90;
  double _photoAspectRatio = 16.0 / 9.0;
  bool _includeMetadata = true;
  bool _autoSave = true;
  
  // Photo storage
  List<ARPhoto> _capturedPhotos = [];
  String? _lastCapturedPhotoPath;
  DateTime? _lastCaptureTime;
  
  // Capture state
  Timer? _captureTimer;
  int _captureCount = 0;
  
  // Stream controllers for photo events
  final StreamController<ARPhotoCaptureEvent> _captureController = StreamController<ARPhotoCaptureEvent>.broadcast();

  // Getters
  bool get isActive => _isActive;
  bool get isCapturing => _isCapturing;
  List<ARPhoto> get capturedPhotos => List.unmodifiable(_capturedPhotos);
  String? get lastCapturedPhotoPath => _lastCapturedPhotoPath;
  DateTime? get lastCaptureTime => _lastCaptureTime;
  int get captureCount => _captureCount;
  Stream<ARPhotoCaptureEvent> get captureStream => _captureController.stream;

  /// Initialize photo capture service
  Future<void> initialize() async {
    try {
      print('Initializing AR photo capture service...');
      _isActive = true;
      
      // Create photos directory if it doesn't exist
      await _createPhotosDirectory();
      
      print('AR photo capture service initialized successfully');
    } catch (e) {
      print('Error initializing AR photo capture service: $e');
    }
  }

  /// Create photos directory
  Future<void> _createPhotosDirectory() async {
    try {
      // This would create a directory for storing AR photos
      // For now, we'll simulate this
      print('Photos directory ready');
    } catch (e) {
      print('Error creating photos directory: $e');
    }
  }

  /// Capture AR photo
  Future<ARPhoto?> capturePhoto({
    String? markerId,
    Map<String, dynamic>? arContent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isActive || _isCapturing) {
        print('Photo capture not available');
        return null;
      }

      _isCapturing = true;
      print('Capturing AR photo...');
      
      // Simulate photo capture delay
      await Future.delayed(Duration(milliseconds: 500));
      
      // Generate photo path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final photoPath = 'ar_photo_${timestamp}.$_photoFormat';
      
      // Create photo metadata
      final photoMetadata = {
        'timestamp': timestamp,
        'markerId': markerId,
        'arContent': arContent,
        'format': _photoFormat,
        'quality': _photoQuality,
        'aspectRatio': _photoAspectRatio,
        'includeMetadata': _includeMetadata,
        ...?metadata,
      };
      
      // Create AR photo object
      final photo = ARPhoto(
        id: 'photo_$timestamp',
        path: photoPath,
        timestamp: DateTime.now(),
        markerId: markerId,
        arContent: arContent,
        metadata: photoMetadata,
        format: _photoFormat,
        quality: _photoQuality,
        size: _generatePhotoSize(), // Simulated size
      );
      
      // Add to captured photos list
      _capturedPhotos.add(photo);
      _lastCapturedPhotoPath = photoPath;
      _lastCaptureTime = DateTime.now();
      _captureCount++;
      
      // Emit capture event
      _emitCaptureEvent(ARPhotoCaptureType.photo, photo);
      
      _isCapturing = false;
      print('AR photo captured: $photoPath');
      return photo;
      
    } catch (e) {
      print('Error capturing AR photo: $e');
      _isCapturing = false;
      return null;
    }
  }

  /// Capture burst photos
  Future<List<ARPhoto>> captureBurstPhotos({
    int count = 3,
    Duration interval = const Duration(milliseconds: 500),
    String? markerId,
    Map<String, dynamic>? arContent,
  }) async {
    try {
      print('Capturing burst photos: $count photos');
      
      final photos = <ARPhoto>[];
      
      for (int i = 0; i < count; i++) {
        final photo = await capturePhoto(
          markerId: markerId,
          arContent: arContent,
          metadata: {'burstIndex': i, 'burstCount': count},
        );
        
        if (photo != null) {
          photos.add(photo);
        }
        
        if (i < count - 1) {
          await Future.delayed(interval);
        }
      }
      
      print('Burst capture completed: ${photos.length} photos');
      return photos;
      
    } catch (e) {
      print('Error capturing burst photos: $e');
      return [];
    }
  }

  /// Start continuous capture
  Future<void> startContinuousCapture({
    Duration interval = const Duration(seconds: 1),
    int maxPhotos = 10,
    String? markerId,
    Map<String, dynamic>? arContent,
  }) async {
    try {
      if (_captureTimer != null) {
        print('Continuous capture already active');
        return;
      }
      
      print('Starting continuous capture...');
      
      _captureTimer = Timer.periodic(interval, (timer) async {
        if (_capturedPhotos.length >= maxPhotos) {
          stopContinuousCapture();
          return;
        }
        
        await capturePhoto(
          markerId: markerId,
          arContent: arContent,
          metadata: {'continuousCapture': true},
        );
      });
      
    } catch (e) {
      print('Error starting continuous capture: $e');
    }
  }

  /// Stop continuous capture
  void stopContinuousCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
    print('Continuous capture stopped');
  }

  /// Get photo by ID
  ARPhoto? getPhotoById(String photoId) {
    try {
      return _capturedPhotos.firstWhere((photo) => photo.id == photoId);
    } catch (e) {
      return null;
    }
  }

  /// Delete photo
  Future<bool> deletePhoto(String photoId) async {
    try {
      final photo = getPhotoById(photoId);
      if (photo != null) {
        _capturedPhotos.remove(photo);
        print('Photo deleted: $photoId');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }

  /// Clear all photos
  Future<void> clearAllPhotos() async {
    try {
      _capturedPhotos.clear();
      _lastCapturedPhotoPath = null;
      _lastCaptureTime = null;
      _captureCount = 0;
      print('All photos cleared');
    } catch (e) {
      print('Error clearing photos: $e');
    }
  }

  /// Set photo capture settings
  void setCaptureSettings({
    String? format,
    int? quality,
    double? aspectRatio,
    bool? includeMetadata,
    bool? autoSave,
  }) {
    if (format != null) _photoFormat = format;
    if (quality != null) _photoQuality = quality.clamp(1, 100);
    if (aspectRatio != null) _photoAspectRatio = aspectRatio;
    if (includeMetadata != null) _includeMetadata = includeMetadata;
    if (autoSave != null) _autoSave = autoSave;
    
    print('Photo capture settings updated');
  }

  /// Generate simulated photo size
  int _generatePhotoSize() {
    // Simulate photo file size (in bytes)
    return 1024 * 1024 + (DateTime.now().millisecondsSinceEpoch % 500000);
  }

  /// Emit capture event
  void _emitCaptureEvent(ARPhotoCaptureType type, ARPhoto photo) {
    final event = ARPhotoCaptureEvent(
      type: type,
      photo: photo,
      timestamp: DateTime.now(),
    );
    
    _captureController.add(event);
  }

  /// Get capture statistics
  Map<String, dynamic> getCaptureStats() {
    return {
      'isActive': _isActive,
      'isCapturing': _isCapturing,
      'captureCount': _captureCount,
      'totalPhotos': _capturedPhotos.length,
      'lastCaptureTime': _lastCaptureTime?.toIso8601String(),
      'lastCapturedPhotoPath': _lastCapturedPhotoPath,
      'photoFormat': _photoFormat,
      'photoQuality': _photoQuality,
      'photoAspectRatio': _photoAspectRatio,
      'includeMetadata': _includeMetadata,
      'autoSave': _autoSave,
    };
  }

  /// Dispose photo capture service
  void dispose() {
    stopContinuousCapture();
    _captureController.close();
    print('AR photo capture service disposed');
  }
}

/// AR Photo Capture Types
enum ARPhotoCaptureType {
  photo,
  burst,
  continuous,
}

/// AR Photo Model
class ARPhoto {
  final String id;
  final String path;
  final DateTime timestamp;
  final String? markerId;
  final Map<String, dynamic>? arContent;
  final Map<String, dynamic> metadata;
  final String format;
  final int quality;
  final int size;

  ARPhoto({
    required this.id,
    required this.path,
    required this.timestamp,
    this.markerId,
    this.arContent,
    required this.metadata,
    required this.format,
    required this.quality,
    required this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'timestamp': timestamp.toIso8601String(),
      'markerId': markerId,
      'arContent': arContent,
      'metadata': metadata,
      'format': format,
      'quality': quality,
      'size': size,
    };
  }

  @override
  String toString() {
    return 'ARPhoto(id: $id, path: $path, timestamp: $timestamp)';
  }
}

/// AR Photo Capture Event
class ARPhotoCaptureEvent {
  final ARPhotoCaptureType type;
  final ARPhoto photo;
  final DateTime timestamp;

  ARPhotoCaptureEvent({
    required this.type,
    required this.photo,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'photo': photo.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ARPhotoCaptureEvent(type: $type, photo: ${photo.id}, timestamp: $timestamp)';
  }
} 