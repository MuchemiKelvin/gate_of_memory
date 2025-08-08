import 'package:flutter/material.dart';
import 'ar_camera_service.dart';
import 'ar_overlay_service.dart';

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
  
  ARSessionState _sessionState = ARSessionState.initializing;
  bool _isARSupported = false;
  String _errorMessage = '';
  
  // AR Session properties
  bool _isMarkerDetected = false;
  String _currentMarkerId = '';
  Map<String, dynamic> _arContent = {};

  // Getters
  ARSessionState get sessionState => _sessionState;
  bool get isARSupported => _isARSupported;
  String get errorMessage => _errorMessage;
  bool get isMarkerDetected => _isMarkerDetected;
  String get currentMarkerId => _currentMarkerId;
  Map<String, dynamic> get arContent => _arContent;
  AROverlayService get overlayService => _overlayService;

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

  /// Start AR session
  Future<bool> startSession() async {
    try {
      if (_sessionState != ARSessionState.ready) {
        print('AR session not ready');
        return false;
      }

      print('Starting AR session...');
      _setSessionState(ARSessionState.active);

      // Start camera preview
      await _cameraService.startPreview();
      
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
      
      // Clear overlays
      _overlayService.clearOverlays();
      
      // Reset AR state
      _isMarkerDetected = false;
      _currentMarkerId = '';
      _arContent.clear();
      
      _setSessionState(ARSessionState.ready);
      print('AR session stopped');
    } catch (e) {
      print('Error stopping AR session: $e');
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
      
      // Trigger AR content loading
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
      
      // Simulate loading delay
      await Future.delayed(Duration(seconds: 2));
      
      // Clear loading overlay
      _overlayService.clearOverlaysByType(AROverlayType.loading);
      
      // Show hologram overlay
      _overlayService.showHologram('hologram_$markerId');
      
      // TODO: Load actual hologram content based on marker data
      // This will be enhanced in Task 17: Implement AR Content Loading
      
      // For now, just log the marker data
      print('Marker data: $markerData');
      
    } catch (e) {
      print('Error loading AR content: $e');
      _overlayService.showError('Failed to load AR content: $e');
    }
  }

  /// Clear marker detection
  void clearMarkerDetection() {
    _isMarkerDetected = false;
    _currentMarkerId = '';
    _arContent.clear();
    
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
      
      // Stop camera service
      await _cameraService.dispose();
      
      // Dispose overlay service
      _overlayService.dispose();
      
      // Clear state
      _isMarkerDetected = false;
      _currentMarkerId = '';
      _arContent.clear();
      
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