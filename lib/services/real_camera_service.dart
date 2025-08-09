import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'real_qr_detection_service.dart';

class RealCameraService {
  static final RealCameraService _instance = RealCameraService._internal();
  factory RealCameraService() => _instance;
  RealCameraService._internal();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isPreviewActive = false;
  double _zoomLevel = 1.0;
  bool _flashEnabled = false;
  bool _autoFocusEnabled = true;
  DateTime? _lastFrameProcessedAt;

  // Stream controllers
  final StreamController<Map<String, dynamic>> _frameDataController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  bool get isPreviewActive => _isPreviewActive;
  CameraController? get cameraController => _cameraController;
  List<CameraDescription> get cameras => _cameras;
  int get selectedCameraIndex => _selectedCameraIndex;
  double get zoomLevel => _zoomLevel;
  bool get flashEnabled => _flashEnabled;
  bool get autoFocusEnabled => _autoFocusEnabled;
  Stream<Map<String, dynamic>> get frameDataStream => _frameDataController.stream;
  Stream<String> get statusStream => _statusController.stream;

  /// Initialize real camera service
  Future<bool> initialize() async {
    try {
      print('Initializing real camera service...');
      
      // Check camera permission first
      var status = await Permission.camera.status;
      if (status == PermissionStatus.denied) {
        // Request camera permission
        status = await Permission.camera.request();
      }
      
      if (status != PermissionStatus.granted) {
        print('Camera permission denied');
        _statusController.add('Camera permission denied');
        return false;
      }
      
      _hasPermission = true;
      _statusController.add('Camera permission granted');

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print('No cameras available');
        _statusController.add('No cameras available');
        return false;
      }

      print('Found ${_cameras.length} cameras');
      _statusController.add('Found ${_cameras.length} cameras');

      // Initialize camera controller
      await _initializeCameraController();
      
      _isInitialized = true;
      _statusController.add('Camera initialized successfully');
      print('Real camera service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing real camera service: $e');
      _statusController.add('Camera initialization failed: $e');
      return false;
    }
  }

  /// Initialize camera controller
  Future<void> _initializeCameraController() async {
    try {
      _cameraController?.dispose();
      
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      // Set initial camera settings (with error handling)
      try {
        await _cameraController!.setZoomLevel(_zoomLevel);
      } catch (e) {
        print('Zoom setting failed (non-critical): $e');
      }
      
      try {
        await _cameraController!.setFlashMode(_flashEnabled ? FlashMode.torch : FlashMode.off);
      } catch (e) {
        print('Flash setting failed (non-critical): $e');
      }
      
      print('Camera controller initialized');
      _statusController.add('Camera controller ready');
    } catch (e) {
      print('Error initializing camera controller: $e');
      _statusController.add('Camera controller failed: $e');
      rethrow;
    }
  }

  /// Start camera preview
  Future<void> startPreview() async {
    if (!_isInitialized || _cameraController == null) {
      print('Camera not initialized');
      return;
    }

    try {
      // Start image stream for QR detection
      await _cameraController!.startImageStream(_onImageStream);
      _isPreviewActive = true;
      _statusController.add('Camera preview started');
      print('Real camera preview started');
    } catch (e) {
      print('Error starting camera preview: $e');
      _statusController.add('Camera preview failed: $e');
      
      // Try alternative approach without image stream
      try {
        print('Trying alternative camera preview...');
        _isPreviewActive = true;
        _statusController.add('Camera preview started (basic mode)');
        print('Real camera preview started (basic mode)');
      } catch (e2) {
        print('Alternative camera preview also failed: $e2');
        _statusController.add('Camera preview failed completely: $e2');
      }
    }
  }

  /// Stop camera preview
  Future<void> stopPreview() async {
    try {
      await _cameraController?.stopImageStream();
      _isPreviewActive = false;
      _statusController.add('Camera preview stopped');
      print('Real camera preview stopped');
    } catch (e) {
      print('Error stopping camera preview: $e');
      _statusController.add('Camera stop failed: $e');
    }
  }

  /// Process camera image stream
  void _onImageStream(CameraImage image) {
    if (!_isPreviewActive) return;

    try {
      // Process image for AR marker detection
      final frameData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'width': image.width,
        'height': image.height,
        'format': image.format.raw,
        'planes': image.planes.length,
        'zoom': _zoomLevel,
        'flash': _flashEnabled,
        'autoFocus': _autoFocusEnabled,
      };

      _frameDataController.add(frameData);

      // Throttle and forward frames to QR detection service when active
      final now = DateTime.now();
      final shouldProcess = _lastFrameProcessedAt == null ||
          now.difference(_lastFrameProcessedAt!).inMilliseconds > 150;
      if (shouldProcess) {
        _lastFrameProcessedAt = now;
        try {
          final qrService = RealQRDetectionService();
          if (qrService.isInitialized && qrService.isDetecting) {
            qrService.processFrame(image);
          }
        } catch (e) {
          print('Error passing frame to QR detection: $e');
        }
      }
    } catch (e) {
      print('Error processing camera frame: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      print('Only one camera available');
      _statusController.add('Only one camera available');
      return;
    }

    try {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      await _initializeCameraController();
      
      if (_isPreviewActive) {
        await startPreview();
      }
      
      _statusController.add('Camera switched to ${_cameras[_selectedCameraIndex].name}');
      print('Camera switched to ${_cameras[_selectedCameraIndex].name}');
    } catch (e) {
      print('Error switching camera: $e');
      _statusController.add('Camera switch failed: $e');
    }
  }

  /// Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    try {
      _zoomLevel = zoom.clamp(1.0, 10.0);
      await _cameraController?.setZoomLevel(_zoomLevel);
      _statusController.add('Zoom set to ${_zoomLevel.toStringAsFixed(1)}x');
      print('Zoom set to ${_zoomLevel.toStringAsFixed(1)}x');
    } catch (e) {
      print('Error setting zoom: $e');
      _statusController.add('Zoom setting failed: $e');
    }
  }

  /// Toggle flash
  Future<void> toggleFlash() async {
    try {
      _flashEnabled = !_flashEnabled;
      await _cameraController?.setFlashMode(_flashEnabled ? FlashMode.torch : FlashMode.off);
      _statusController.add('Flash ${_flashEnabled ? 'enabled' : 'disabled'}');
      print('Flash ${_flashEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('Error toggling flash: $e');
      _statusController.add('Flash toggle failed: $e');
    }
  }

  /// Toggle auto focus
  Future<void> toggleAutoFocus() async {
    try {
      _autoFocusEnabled = !_autoFocusEnabled;
      await _cameraController?.setFocusMode(_autoFocusEnabled ? FocusMode.auto : FocusMode.locked);
      _statusController.add('Auto focus ${_autoFocusEnabled ? 'enabled' : 'disabled'}');
      print('Auto focus ${_autoFocusEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('Error toggling auto focus: $e');
      _statusController.add('Auto focus toggle failed: $e');
    }
  }

  /// Take photo
  Future<String?> takePhoto() async {
    if (!_isPreviewActive || _cameraController == null) {
      print('Camera not ready for photo');
      return null;
    }

    try {
      final image = await _cameraController!.takePicture();
      _statusController.add('Photo captured: ${image.path}');
      print('Photo captured: ${image.path}');
      return image.path;
    } catch (e) {
      print('Error taking photo: $e');
      _statusController.add('Photo capture failed: $e');
      return null;
    }
  }

  /// Get camera status
  String getStatus() {
    if (!_isInitialized) return 'Not initialized';
    if (!_hasPermission) return 'No permission';
    if (_cameraController == null) return 'No camera controller';
    if (!_isPreviewActive) return 'Preview not active';
    return 'Active - ${_cameras[_selectedCameraIndex].name}';
  }

  /// Get camera info
  Map<String, dynamic> getCameraInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasPermission': _hasPermission,
      'isPreviewActive': _isPreviewActive,
      'cameraCount': _cameras.length,
      'currentCamera': _cameras.isNotEmpty ? _cameras[_selectedCameraIndex].name : 'None',
      'zoomLevel': _zoomLevel,
      'flashEnabled': _flashEnabled,
      'autoFocusEnabled': _autoFocusEnabled,
    };
  }

  /// Dispose camera service
  void dispose() {
    _cameraController?.dispose();
    // Don't close stream controllers for singleton pattern
    // _frameDataController.close();
    // _statusController.close();
    print('Real camera service disposed');
  }
} 