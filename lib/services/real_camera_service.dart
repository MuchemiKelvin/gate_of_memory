import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/memorial.dart';
import 'qr_code_service.dart';

/// Service for handling real camera operations
class RealCameraService {
  static final RealCameraService _instance = RealCameraService._internal();
  factory RealCameraService() => _instance;
  RealCameraService._internal();

  final QRCodeService _qrService = QRCodeService();
  MobileScannerController? _controller;
  bool _isInitialized = false;
  bool _hasPermission = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  MobileScannerController? get controller => _controller;

  /// Initialize the camera service
  Future<bool> initialize() async {
    try {
      print('Initializing real camera service...');
      
      // Create controller
      _controller = MobileScannerController();
      
      // Check permissions
      _hasPermission = await _checkCameraPermission();
      
      if (_hasPermission) {
        _isInitialized = true;
        print('Real camera service initialized successfully');
        return true;
      } else {
        print('Camera permission denied');
        return false;
      }
    } catch (e) {
      print('Error initializing real camera service: $e');
      return false;
    }
  }

  /// Check camera permission
  Future<bool> _checkCameraPermission() async {
    try {
      // For mobile_scanner, permissions are handled automatically
      // This is a placeholder for future permission handling
      return true;
    } catch (e) {
      print('Error checking camera permission: $e');
      return false;
    }
  }

  /// Start camera preview
  Future<bool> startCamera() async {
    try {
      if (!_isInitialized || _controller == null) {
        print('Camera service not initialized');
        return false;
      }

      await _controller!.start();
      print('Camera started successfully');
      return true;
    } catch (e) {
      print('Error starting camera: $e');
      return false;
    }
  }

  /// Stop camera preview
  Future<bool> stopCamera() async {
    try {
      if (_controller == null) {
        return false;
      }

      await _controller!.stop();
      print('Camera stopped successfully');
      return true;
    } catch (e) {
      print('Error stopping camera: $e');
      return false;
    }
  }

  /// Toggle camera flash
  Future<bool> toggleFlash() async {
    try {
      if (_controller == null) {
        return false;
      }

      await _controller!.toggleTorch();
      print('Flash toggled successfully');
      return true;
    } catch (e) {
      print('Error toggling flash: $e');
      return false;
    }
  }

  /// Switch camera (front/back)
  Future<bool> switchCamera() async {
    try {
      if (_controller == null) {
        return false;
      }

      await _controller!.switchCamera();
      print('Camera switched successfully');
      return true;
    } catch (e) {
      print('Error switching camera: $e');
      return false;
    }
  }

  /// Capture image
  Future<String?> captureImage() async {
    try {
      if (_controller == null) {
        return null;
      }

      // For mobile_scanner, we capture QR codes, not images
      // This method is a placeholder for future image capture functionality
      print('Image capture not implemented for QR scanner');
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  /// Get camera status
  Map<String, dynamic> getCameraStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasPermission': _hasPermission,
      'controllerExists': _controller != null,
      'isRunning': _controller?.isStarting ?? false,
    };
  }

  /// Dispose camera resources
  void dispose() {
    try {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      print('Real camera service disposed');
    } catch (e) {
      print('Error disposing camera service: $e');
    }
  }

  /// Reset camera service
  void reset() {
    dispose();
    _hasPermission = false;
  }
} 