import 'package:flutter/material.dart';
import 'ar_camera_service.dart';
import 'ar_overlay_service.dart';
import 'ar_marker_detection_service.dart';
import 'ar_content_loading_service.dart';
import 'dart:async';

enum ARSessionState {
  initializing,
  ready,
  active,
  paused,
  error,
  disposed,
}

class ARSessionManager {
  static final ARSessionManager _instance = ARSessionManager._internal();
  factory ARSessionManager() => _instance;
  ARSessionManager._internal();

  final ARCameraService _cameraService = ARCameraService();
  final AROverlayService _overlayService = AROverlayService();
  final ARMarkerDetectionService _markerDetectionService = ARMarkerDetectionService();
  final ARContentLoadingService _contentLoadingService = ARContentLoadingService();
  
  ARSessionState _sessionState = ARSessionState.initializing;
  bool _isARSupported = false;
  String _errorMessage = '';
  
  // AR Session properties
  bool _isMarkerDetected = false;
  String _currentMarkerId = '';
  Map<String, dynamic> _arContent = {};
  ARContent? _currentARContent;
  
  // Session management
  StreamSubscription<ARMarkerDetection>? _markerDetectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _frameDataSubscription;
  Timer? _sessionTimer;
  DateTime? _sessionStartTime;
  int _sessionDuration = 0;

  // Getters
  ARSessionState get sessionState => _sessionState;
  bool get isARSupported => _isARSupported;
  String get errorMessage => _errorMessage;
  bool get isMarkerDetected => _isMarkerDetected;
  String get currentMarkerId => _currentMarkerId;
  Map<String, dynamic> get arContent => _arContent;
  ARContent? get currentARContent => _currentARContent;
  AROverlayService get overlayService => _overlayService;
  ARMarkerDetectionService get markerDetectionService => _markerDetectionService;
  ARContentLoadingService get contentLoadingService => _contentLoadingService;
  int get sessionDuration => _sessionDuration;

  /// Initialize AR session
  Future<bool> initialize() async {
    try {
      print('Initializing AR session...');
      _setSessionState(ARSessionState.initializing);

      // Initialize camera service
      final cameraInitialized = await _cameraService.initialize();
      if (!cameraInitialized) {
        _setError('Failed to initialize camera service');
        return false;
      }

      // Check AR support
      _isARSupported = await _cameraService.checkARSupport();
      if (!_isARSupported) {
        _setError('AR not supported on this device');
        return false;
      }

      // Initialize marker detection service
      await _initializeMarkerDetection();

      // Preload common content
      await _preloadCommonContent();

      // Show initialization overlay
      _overlayService.showInfo('AR Session Initialized');

      _setSessionState(ARSessionState.ready);
      print('AR session initialized successfully');
      return true;
    } catch (e) {
      _setError('Error initializing AR session: $e');
      return false;
    }
  }

  /// Initialize marker detection
  Future<void> _initializeMarkerDetection() async {
    try {
      // Subscribe to marker detection events
      _markerDetectionSubscription = _markerDetectionService.detectionStream.listen(
        _onMarkerDetected,
        onError: (error) {
          print('Marker detection error: $error');
          _overlayService.showError('Marker detection error: $error');
        },
      );

      // Subscribe to camera frame data
      _frameDataSubscription = _cameraService.frameDataStream.listen(
        _onFrameDataReceived,
        onError: (error) {
          print('Frame data error: $error');
        },
      );

      print('Marker detection initialized');
    } catch (e) {
      print('Error initializing marker detection: $e');
    }
  }

  /// Preload common content
  Future<void> _preloadCommonContent() async {
    try {
      print('Preloading common AR content...');
      
      // Get known markers and preload their content
      final knownMarkers = _markerDetectionService.getKnownMarkers();
      final markerIds = knownMarkers.keys.toList();
      
      await _contentLoadingService.preloadContent(markerIds);
      
      print('Common content preloaded');
    } catch (e) {
      print('Error preloading content: $e');
    }
  }

  /// Start AR session
  Future<bool> startSession() async {
    try {
      if (_sessionState != ARSessionState.ready) {
        print('AR session not ready');
        return false;
      }

      print('Starting AR session...');
      _setSessionState(ARSessionState.active);
      _sessionStartTime = DateTime.now();

      // Start camera preview
      await _cameraService.startPreview();
      
      // Start marker detection
      await _markerDetectionService.startDetection();
      
      // Start session timer
      _startSessionTimer();
      
      // Show session start overlay
      _overlayService.showInfo('AR Session Started');
      
      print('AR session started successfully');
      return true;
    } catch (e) {
      _setError('Error starting AR session: $e');
      return false;
    }
  }

  /// Pause AR session
  Future<void> pauseSession() async {
    try {
      if (_sessionState == ARSessionState.active) {
        print('Pausing AR session...');
        _setSessionState(ARSessionState.paused);
        
        // Stop camera preview
        await _cameraService.stopPreview();
        
        // Stop marker detection
        await _markerDetectionService.stopDetection();
        
        // Stop session timer
        _stopSessionTimer();
        
        // Show pause overlay
        _overlayService.showInfo('AR Session Paused');
        
        print('AR session paused');
      }
    } catch (e) {
      print('Error pausing AR session: $e');
    }
  }

  /// Resume AR session
  Future<bool> resumeSession() async {
    try {
      if (_sessionState == ARSessionState.paused) {
        print('Resuming AR session...');
        _setSessionState(ARSessionState.active);
        
        // Restart camera preview
        await _cameraService.startPreview();
        
        // Restart marker detection
        await _markerDetectionService.startDetection();
        
        // Restart session timer
        _startSessionTimer();
        
        // Show resume overlay
        _overlayService.showInfo('AR Session Resumed');
        
        print('AR session resumed');
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error resuming AR session: $e');
      return false;
    }
  }

  /// Stop AR session
  Future<void> stopSession() async {
    try {
      print('Stopping AR session...');
      
      // Stop camera preview
      await _cameraService.stopPreview();
      
      // Stop marker detection
      await _markerDetectionService.stopDetection();
      
      // Stop session timer
      _stopSessionTimer();
      
      // Clear overlays
      _overlayService.clearOverlays();
      
      // Reset AR state
      _isMarkerDetected = false;
      _currentMarkerId = '';
      _arContent.clear();
      _currentARContent = null;
      
      _setSessionState(ARSessionState.ready);
      print('AR session stopped');
    } catch (e) {
      print('Error stopping AR session: $e');
    }
  }

  /// Start session timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_sessionState == ARSessionState.active) {
        _sessionDuration++;
      }
    });
  }

  /// Stop session timer
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Handle marker detection events
  void _onMarkerDetected(ARMarkerDetection detection) {
    try {
      print('Marker detected in session: ${detection.markerId}');
      
      _isMarkerDetected = true;
      _currentMarkerId = detection.markerId;
      _arContent = detection.markerData;
      
      // Show marker detection overlay
      _overlayService.showMarkerDetection(detection.markerId);
      
      // Load AR content for the detected marker
      _loadARContent(detection.markerId, detection.markerData);
      
    } catch (e) {
      print('Error handling marker detection: $e');
    }
  }

  /// Handle camera frame data
  void _onFrameDataReceived(Map<String, dynamic> frameData) {
    // Process frame data for AR marker detection
    // This is where we would integrate with the marker detection service
    if (_sessionState == ARSessionState.active) {
      // Frame data processing for AR
      // print('Processing frame data: ${frameData['timestamp']}');
    }
  }

  /// Process AR marker detection
  void processMarkerDetection(String markerId, Map<String, dynamic> markerData) {
    try {
      print('Processing AR marker: $markerId');
      
      _isMarkerDetected = true;
      _currentMarkerId = markerId;
      _arContent = markerData;
      
      // Show marker detection overlay
      _overlayService.showMarkerDetection(markerId);
      
      // Load AR content for the detected marker
      _loadARContent(markerId, markerData);
      
    } catch (e) {
      print('Error processing marker detection: $e');
    }
  }

  /// Load AR content for detected marker
  Future<void> _loadARContent(String markerId, Map<String, dynamic> markerData) async {
    try {
      print('Loading AR content for marker: $markerId');
      
      // Show loading overlay
      _overlayService.showLoading('Loading hologram content...');
      
      // Load content using content loading service
      final content = await _contentLoadingService.loadContent(markerId, markerData);
      
      if (content != null) {
        _currentARContent = content;
        
        // Clear loading overlay
        _overlayService.clearOverlaysByType(AROverlayType.loading);
        
        // Show hologram overlay with content info
        _overlayService.showHologram('hologram_$markerId');
        
        // Show content info overlay
        _overlayService.showInfo('${content.title} loaded successfully');
        
        print('AR content loaded: ${content.title}');
      } else {
        // Show error overlay
        _overlayService.clearOverlaysByType(AROverlayType.loading);
        _overlayService.showError('Failed to load AR content for marker: $markerId');
        print('Failed to load AR content for marker: $markerId');
      }
      
    } catch (e) {
      print('Error loading AR content: $e');
      _overlayService.clearOverlaysByType(AROverlayType.loading);
      _overlayService.showError('Failed to load AR content: $e');
    }
  }

  /// Clear marker detection
  void clearMarkerDetection() {
    _isMarkerDetected = false;
    _currentMarkerId = '';
    _arContent.clear();
    _currentARContent = null;
    
    // Clear marker overlays
    _overlayService.clearOverlaysByType(AROverlayType.marker);
    _overlayService.clearOverlaysByType(AROverlayType.hologram);
    
    print('Marker detection cleared');
  }

  /// Switch camera
  Future<void> switchCamera() async {
    try {
      await _cameraService.switchCamera();
      _overlayService.showInfo('Camera switched');
      print('Camera switched in AR session');
    } catch (e) {
      print('Error switching camera: $e');
      _overlayService.showError('Failed to switch camera: $e');
    }
  }

  /// Take AR photo
  Future<String?> takeARPhoto() async {
    try {
      final photoPath = await _cameraService.takePhoto();
      if (photoPath != null) {
        _overlayService.showInfo('Photo captured successfully');
        print('AR photo taken: $photoPath');
        return photoPath;
      }
      return null;
    } catch (e) {
      print('Error taking AR photo: $e');
      _overlayService.showError('Failed to take photo: $e');
      return null;
    }
  }

  /// Get camera status for UI
  String getCameraStatus() {
    return _cameraService.getCameraStatus();
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    return {
      'sessionState': _sessionState.toString(),
      'sessionDuration': _sessionDuration,
      'isMarkerDetected': _isMarkerDetected,
      'currentMarkerId': _currentMarkerId,
      'currentARContent': _currentARContent?.title,
      'cameraStatus': _cameraService.getCameraStatus(),
      'markerDetectionStats': _markerDetectionService.getDetectionStats(),
      'contentLoadingStats': _contentLoadingService.getLoadingStatus(),
      'overlayCount': _overlayService.visibleOverlays.length,
    };
  }

  /// Set session state
  void _setSessionState(ARSessionState state) {
    _sessionState = state;
    print('AR session state changed to: $state');
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _setSessionState(ARSessionState.error);
    _overlayService.showError(message);
    print('AR session error: $message');
  }

  /// Clear error
  void clearError() {
    _errorMessage = '';
    if (_sessionState == ARSessionState.error) {
      _setSessionState(ARSessionState.ready);
    }
  }

  /// Dispose AR session
  Future<void> dispose() async {
    try {
      print('Disposing AR session...');
      
      // Stop session timer
      _stopSessionTimer();
      
      // Cancel subscriptions
      _markerDetectionSubscription?.cancel();
      _frameDataSubscription?.cancel();
      
      // Stop camera service
      await _cameraService.dispose();
      
      // Dispose marker detection service
      _markerDetectionService.dispose();
      
      // Dispose content loading service
      _contentLoadingService.dispose();
      
      // Dispose overlay service
      _overlayService.dispose();
      
      // Clear state
      _isMarkerDetected = false;
      _currentMarkerId = '';
      _arContent.clear();
      _currentARContent = null;
      
      _setSessionState(ARSessionState.disposed);
      print('AR session disposed');
    } catch (e) {
      print('Error disposing AR session: $e');
    }
  }

  /// Get session status string
  String getSessionStatus() {
    switch (_sessionState) {
      case ARSessionState.initializing:
        return 'Initializing AR...';
      case ARSessionState.ready:
        return 'AR Ready';
      case ARSessionState.active:
        return _isMarkerDetected ? 'Marker Detected' : 'Scanning for markers...';
      case ARSessionState.paused:
        return 'AR Paused';
      case ARSessionState.error:
        return 'AR Error: $_errorMessage';
      case ARSessionState.disposed:
        return 'AR Disposed';
    }
  }
} 