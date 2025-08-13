import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/memorial.dart';
import 'qr_code_service.dart';
import 'memorial_service.dart';

/// Service for real-time QR code detection
class RealQRDetectionService {
  static final RealQRDetectionService _instance = RealQRDetectionService._internal();
  factory RealQRDetectionService() => _instance;
  RealQRDetectionService._internal();

  final QRCodeService _qrService = QRCodeService();
  final MemorialService _memorialService = MemorialService();
  
  bool _isDetecting = false;
  bool _isInitialized = false;
  List<Memorial> _detectedMemorials = [];
  DateTime? _lastDetectionTime;

  // Getters
  bool get isDetecting => _isDetecting;
  bool get isInitialized => _isInitialized;
  List<Memorial> get detectedMemorials => List.unmodifiable(_detectedMemorials);
  DateTime? get lastDetectionTime => _lastDetectionTime;

  /// Initialize QR detection service
  Future<bool> initialize() async {
    try {
      print('Initializing real QR detection service...');
      
      // Setup QR service listeners
      _setupDetectionListeners();
      
      _isInitialized = true;
      print('Real QR detection service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing QR detection service: $e');
      return false;
    }
  }

  /// Setup detection listeners
  void _setupDetectionListeners() {
    _qrService.statusStream.listen((status) {
      switch (status) {
        case QRScanStatus.scanning:
          _isDetecting = true;
          break;
        case QRScanStatus.success:
          _isDetecting = false;
          break;
        case QRScanStatus.error:
          _isDetecting = false;
          break;
        default:
          _isDetecting = false;
      }
    });

    _qrService.memorialStream.listen((memorial) {
      _addDetectedMemorial(memorial);
      _lastDetectionTime = DateTime.now();
      print('Memorial detected: ${memorial.name}');
    });

    _qrService.errorStream.listen((error) {
      print('QR detection error: $error');
    });
  }

  /// Add detected memorial to list
  void _addDetectedMemorial(Memorial memorial) {
    // Check if memorial already exists in list
    final existingIndex = _detectedMemorials.indexWhere((m) => m.id == memorial.id);
    
    if (existingIndex >= 0) {
      // Update existing memorial
      _detectedMemorials[existingIndex] = memorial;
    } else {
      // Add new memorial
      _detectedMemorials.add(memorial);
    }
  }

  /// Start QR detection
  Future<bool> startDetection() async {
    try {
      if (!_isInitialized) {
        print('QR detection service not initialized');
        return false;
      }

      _isDetecting = true;
      print('QR detection started');
      return true;
    } catch (e) {
      print('Error starting QR detection: $e');
      return false;
    }
  }

  /// Stop QR detection
  Future<bool> stopDetection() async {
    try {
      _isDetecting = false;
      print('QR detection stopped');
      return true;
    } catch (e) {
      print('Error stopping QR detection: $e');
      return false;
    }
  }

  /// Process QR code detection
  Future<Memorial?> processQRCode(String qrCode) async {
    try {
      if (!_isInitialized) {
        print('QR detection service not initialized');
        return null;
      }

      print('Processing QR code: $qrCode');
      
      // Use QR service to validate and process
      final memorial = await _qrService.validateQRCode(qrCode);
      
      if (memorial != null) {
        _addDetectedMemorial(memorial);
        _lastDetectionTime = DateTime.now();
        print('QR code processed successfully: ${memorial.name}');
      } else {
        print('Failed to process QR code: $qrCode');
      }
      
      return memorial;
    } catch (e) {
      print('Error processing QR code: $e');
      return null;
    }
  }

  /// Get detection statistics
  Map<String, dynamic> getDetectionStats() {
    return {
      'isInitialized': _isInitialized,
      'isDetecting': _isDetecting,
      'totalDetected': _detectedMemorials.length,
      'lastDetectionTime': _lastDetectionTime?.toIso8601String(),
      'detectedMemorials': _detectedMemorials.map((m) => {
        'id': m.id,
        'name': m.name,
        'category': m.category,
        'qrCode': m.qrCode,
      }).toList(),
    };
  }

  /// Clear detection history
  void clearDetectionHistory() {
    _detectedMemorials.clear();
    _lastDetectionTime = null;
    print('Detection history cleared');
  }

  /// Get recent detections
  List<Memorial> getRecentDetections({int limit = 10}) {
    if (_detectedMemorials.isEmpty) return [];
    
    // Sort by detection time (most recent first)
    final sorted = List<Memorial>.from(_detectedMemorials);
    sorted.sort((a, b) => (_lastDetectionTime ?? DateTime.now()).compareTo(_lastDetectionTime ?? DateTime.now()));
    
    return sorted.take(limit).toList();
  }

  /// Search detected memorials
  List<Memorial> searchDetectedMemorials(String query) {
    if (query.isEmpty) return _detectedMemorials;
    
    final lowercaseQuery = query.toLowerCase();
    return _detectedMemorials.where((memorial) {
      return memorial.name.toLowerCase().contains(lowercaseQuery) ||
             memorial.description.toLowerCase().contains(lowercaseQuery) ||
             memorial.category.toLowerCase().contains(lowercaseQuery) ||
             memorial.qrCode.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get detection health status
  Map<String, dynamic> getDetectionHealth() {
    return {
      'serviceInitialized': _isInitialized,
      'detectionActive': _isDetecting,
      'memorialsDetected': _detectedMemorials.length,
      'lastDetection': _lastDetectionTime != null 
          ? DateTime.now().difference(_lastDetectionTime!).inSeconds 
          : null,
      'qrServiceStatus': _qrService.currentStatus.toString(),
    };
  }

  /// Reset detection service
  void reset() {
    try {
      _isDetecting = false;
      _detectedMemorials.clear();
      _lastDetectionTime = null;
      _isInitialized = false;
      
      print('QR detection service reset');
    } catch (e) {
      print('Error resetting QR detection service: $e');
    }
  }

  /// Dispose detection service
  void dispose() {
    try {
      reset();
      print('QR detection service disposed');
    } catch (e) {
      print('Error disposing QR detection service: $e');
    }
  }
} 