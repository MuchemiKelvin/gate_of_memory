import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/memorial.dart';
import 'real_camera_service.dart';
import 'qr_code_service.dart';

/// Manager for AR session operations
class RealARSessionManager {
  static final RealARSessionManager _instance = RealARSessionManager._internal();
  factory RealARSessionManager() => _instance;
  RealARSessionManager._internal();

  final RealCameraService _cameraService = RealCameraService();
  final QRCodeService _qrService = QRCodeService();
  
  bool _isSessionActive = false;
  bool _isTracking = false;
  Memorial? _currentMemorial;
  DateTime? _sessionStartTime;

  // Getters
  bool get isSessionActive => _isSessionActive;
  bool get isTracking => _isTracking;
  Memorial? get currentMemorial => _currentMemorial;
  DateTime? get sessionStartTime => _sessionStartTime;

  /// Initialize AR session
  Future<bool> initializeSession() async {
    try {
      print('Initializing AR session...');
      
      // Initialize camera service
      final cameraInitialized = await _cameraService.initialize();
      if (!cameraInitialized) {
        print('Failed to initialize camera service');
        return false;
      }

      // Setup QR service listeners
      _setupQRServiceListeners();
      
      _isSessionActive = true;
      _sessionStartTime = DateTime.now();
      
      print('AR session initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing AR session: $e');
      return false;
    }
  }

  /// Setup QR service listeners
  void _setupQRServiceListeners() {
    _qrService.statusStream.listen((status) {
      switch (status) {
        case QRScanStatus.scanning:
          _isTracking = true;
          break;
        case QRScanStatus.success:
          _isTracking = false;
          break;
        case QRScanStatus.error:
          _isTracking = false;
          break;
        default:
          _isTracking = false;
      }
    });

    _qrService.memorialStream.listen((memorial) {
      _currentMemorial = memorial;
      print('Memorial detected in AR session: ${memorial.name}');
    });

    _qrService.errorStream.listen((error) {
      print('AR session error: $error');
    });
  }

  /// Start AR tracking
  Future<bool> startTracking() async {
    try {
      if (!_isSessionActive) {
        print('AR session not active');
        return false;
      }

      final cameraStarted = await _cameraService.startCamera();
      if (cameraStarted) {
        _isTracking = true;
        print('AR tracking started');
        return true;
      } else {
        print('Failed to start camera for tracking');
        return false;
      }
    } catch (e) {
      print('Error starting AR tracking: $e');
      return false;
    }
  }

  /// Stop AR tracking
  Future<bool> stopTracking() async {
    try {
      final cameraStopped = await _cameraService.stopCamera();
      if (cameraStopped) {
        _isTracking = false;
        print('AR tracking stopped');
        return true;
      } else {
        print('Failed to stop camera for tracking');
        return false;
      }
    } catch (e) {
      print('Error stopping AR tracking: $e');
      return false;
    }
  }

  /// Pause AR session
  Future<bool> pauseSession() async {
    try {
      if (_isTracking) {
        await stopTracking();
      }
      
      print('AR session paused');
      return true;
    } catch (e) {
      print('Error pausing AR session: $e');
      return false;
    }
  }

  /// Resume AR session
  Future<bool> resumeSession() async {
    try {
      if (_isSessionActive && !_isTracking) {
        return await startTracking();
      }
      
      print('AR session resumed');
      return true;
    } catch (e) {
      print('Error resuming AR session: $e');
      return false;
    }
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    final now = DateTime.now();
    final sessionDuration = _sessionStartTime != null 
        ? now.difference(_sessionStartTime!).inSeconds 
        : 0;

    return {
      'isSessionActive': _isSessionActive,
      'isTracking': _isTracking,
      'sessionStartTime': _sessionStartTime?.toIso8601String(),
      'sessionDuration': sessionDuration,
      'currentMemorial': _currentMemorial?.name,
      'cameraStatus': _cameraService.getCameraStatus(),
    };
  }

  /// Reset session
  void resetSession() {
    try {
      _isSessionActive = false;
      _isTracking = false;
      _currentMemorial = null;
      _sessionStartTime = null;
      
      _cameraService.reset();
      
      print('AR session reset');
    } catch (e) {
      print('Error resetting AR session: $e');
    }
  }

  /// End AR session
  Future<void> endSession() async {
    try {
      print('Ending AR session...');
      
      // Stop tracking if active
      if (_isTracking) {
        await stopTracking();
      }
      
      // Dispose camera service
      _cameraService.dispose();
      
      // Reset session state
      resetSession();
      
      print('AR session ended successfully');
    } catch (e) {
      print('Error ending AR session: $e');
    }
  }

  /// Get session health status
  Map<String, dynamic> getSessionHealth() {
    return {
      'sessionActive': _isSessionActive,
      'trackingActive': _isTracking,
      'cameraInitialized': _cameraService.isInitialized,
      'cameraPermission': _cameraService.hasPermission,
      'memorialDetected': _currentMemorial != null,
      'sessionDuration': _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inSeconds 
          : 0,
    };
  }
} 