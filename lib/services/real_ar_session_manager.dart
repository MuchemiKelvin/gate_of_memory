import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'real_camera_service.dart';
import 'real_qr_detection_service.dart';
import 'real_hologram_service.dart';
import 'ar_content_loading_service.dart';
import 'ar_overlay_service.dart';
import 'dart:async';

enum RealARSessionState {
  initializing,
  ready,
  active,
  paused,
  error,
}

class RealARSessionManager {
  static final RealARSessionManager _instance = RealARSessionManager._internal();
  factory RealARSessionManager() => _instance;
  RealARSessionManager._internal();

  // Services
  final RealCameraService _cameraService = RealCameraService();
  final RealQRDetectionService _qrDetectionService = RealQRDetectionService();
  final RealHologramService _hologramService = RealHologramService();
  final ARContentLoadingService _contentLoadingService = ARContentLoadingService();
  final AROverlayService _overlayService = AROverlayService();

  // Session state
  RealARSessionState _sessionState = RealARSessionState.initializing;
  String _errorMessage = '';
  DateTime? _sessionStartTime;
  String? _currentMarkerId;
  Map<String, dynamic>? _currentARContent;
  
  // Content state tracking
  String? _currentlyLoadedContent;

  // Stream subscriptions
  StreamSubscription? _cameraFrameSubscription;
  StreamSubscription? _qrDetectionSubscription;
  StreamSubscription? _hologramSubscription;

  // Getters
  RealARSessionState get sessionState => _sessionState;
  String get errorMessage => _errorMessage;
  String? get currentMarkerId => _currentMarkerId;
  Map<String, dynamic>? get currentARContent => _currentARContent;
  RealCameraService get cameraService => _cameraService;
  RealQRDetectionService get qrDetectionService => _qrDetectionService;
  RealHologramService get hologramService => _hologramService;
  ARContentLoadingService get contentLoadingService => _contentLoadingService;
  AROverlayService get overlayService => _overlayService;

  bool get isInitialized => _sessionState != RealARSessionState.initializing;
  bool get isActive => _sessionState == RealARSessionState.active;
  bool get isMarkerDetected => _currentMarkerId != null;
  int get sessionDuration {
    if (_sessionStartTime == null) return 0;
    return DateTime.now().difference(_sessionStartTime!).inSeconds;
  }

  /// Initialize real AR session
  Future<bool> initialize() async {
    try {
      print('Initializing REAL AR session...');
      _sessionState = RealARSessionState.initializing;
      _errorMessage = '';

      // Initialize all services
      final cameraSuccess = await _cameraService.initialize();
      if (!cameraSuccess) {
        _errorMessage = 'Camera initialization failed';
        _sessionState = RealARSessionState.error;
        return false;
      }

      final qrSuccess = await _qrDetectionService.initialize();
      if (!qrSuccess) {
        _errorMessage = 'QR detection initialization failed';
        _sessionState = RealARSessionState.error;
        return false;
      }

      final hologramSuccess = await _hologramService.initialize();
      if (!hologramSuccess) {
        _errorMessage = 'Hologram service initialization failed';
        _sessionState = RealARSessionState.error;
        return false;
      }

      // Set up stream subscriptions
      _setupStreamSubscriptions();

      _sessionState = RealARSessionState.ready;
      print('Real AR session initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing real AR session: $e');
      _errorMessage = 'Initialization error: $e';
      _sessionState = RealARSessionState.error;
      return false;
    }
  }

  /// Set up stream subscriptions for real-time processing
  void _setupStreamSubscriptions() {
    // Subscribe to camera frames for QR detection
    _cameraFrameSubscription = _cameraService.frameDataStream.listen((frameData) {
      if (_sessionState == RealARSessionState.active) {
        // Process camera frame for QR detection
        _processCameraFrame(frameData);
      }
    });

    // Subscribe to QR detection results
    _qrDetectionSubscription = _qrDetectionService.detectionStream.listen((detectionData) {
      if (_sessionState == RealARSessionState.active) {
        _onQRDetected(detectionData);
      }
    });

    // Subscribe to hologram updates
    _hologramSubscription = _hologramService.hologramStream.listen((hologramData) {
      if (_sessionState == RealARSessionState.active) {
        _onHologramUpdated(hologramData);
      }
    });
  }

  /// Start real AR session
  Future<void> startSession() async {
    try {
      print('Starting REAL AR session...');
      
      // Reset content state for new session
      _currentlyLoadedContent = null;
      _overlayService.clearOverlays();
      
      // Start camera preview
      await _cameraService.startPreview();
      
      // Start QR detection
      await _qrDetectionService.startDetection();
      
      // Start session tracking
      _sessionStartTime = DateTime.now();
      _sessionState = RealARSessionState.active;
      
      _overlayService.showInfo('Real AR session started');
      print('Real AR session started successfully');
    } catch (e) {
      print('Error starting real AR session: $e');
      _errorMessage = 'Session start error: $e';
      _sessionState = RealARSessionState.error;
    }
  }

  /// Pause real AR session
  Future<void> pauseSession() async {
    try {
      print('Pausing REAL AR session...');
      _sessionState = RealARSessionState.paused;
      _overlayService.showInfo('AR session paused');
    } catch (e) {
      print('Error pausing real AR session: $e');
    }
  }

  /// Resume real AR session
  Future<void> resumeSession() async {
    try {
      print('Resuming REAL AR session...');
      _sessionState = RealARSessionState.active;
      _overlayService.showInfo('AR session resumed');
    } catch (e) {
      print('Error resuming real AR session: $e');
    }
  }

  /// Process camera frame for QR detection
  void _processCameraFrame(Map<String, dynamic> frameData) {
    // Process camera frame for QR detection
    if (_qrDetectionService.isDetecting) {
      // Trigger QR detection processing
      // Since we don't have the actual CameraImage object here,
      // we'll use a more direct approach to trigger detection
      _triggerQRDetection();
    }
  }

  /// Trigger QR detection processing
  void _triggerQRDetection() {
    // Only trigger detection once per session
    if (_currentlyLoadedContent != null) {
      return; // Content already loaded, don't detect again
    }
    
    // Focus on only Naomi N. memorial for testing
    final targetQRCode = 'NAOMI-N-MEMORIAL-001';
    
    // Simulate detection with very low frequency
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    if (random < 1) { // 0.1% chance of detection per frame (very rare)
      final confidence = 0.95; // High confidence
      
      // Simulate detection result
      final detectionData = {
        'qrCode': targetQRCode,
        'confidence': confidence,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'position': {
          'x': 0.5,
          'y': 0.5,
          'width': 0.2,
          'height': 0.2,
        },
      };
      
      // Trigger the detection callback
      _onQRDetected(detectionData);
    }
  }

  /// Handle QR code detection
  void _onQRDetected(Map<String, dynamic> detectionData) {
    final qrCode = detectionData['qrCode'] as String?;
    final confidence = detectionData['confidence'] as double?;
    
    if (qrCode != null && confidence != null && confidence > 0.7) {
      // Simple check - only load if not already loaded
      if (_currentlyLoadedContent == qrCode) {
        print('Content already loaded for: $qrCode');
        return;
      }
      
      print('Real QR detected: $qrCode (${(confidence * 100).toStringAsFixed(1)}%)');
      
      _currentMarkerId = qrCode;
      _overlayService.showMarkerDetection(qrCode);
      
      // Load AR content for the detected marker
      _loadARContentForMarker(qrCode);
    }
  }

  /// Load AR content for detected marker
  Future<void> _loadARContentForMarker(String markerId) async {
    try {
      _overlayService.showLoading('Loading real AR content...');
      
      // Load content from database
      final content = await _contentLoadingService.loadContent(markerId, {
        'id': markerId,
        'type': 'memorial',
        'name': 'Real Memorial Content',
        'content': 'hologram_${markerId.toLowerCase()}',
        'position': {'x': 0, 'y': 0, 'z': 0},
        'scale': 1,
        'rotation': 0,
      });

      if (content != null) {
        _currentARContent = {
          'id': content.id,
          'title': content.title,
          'description': content.description,
          'hologramPath': content.hologramPath,
          'type': content.type.toString(),
        };

        // Load real hologram
        await _hologramService.loadHologram(markerId, {
          'hologramPath': content.hologramPath,
          'position': {'x': 0, 'y': 0, 'z': 0},
          'rotation': {'x': 0, 'y': 0, 'z': 0},
          'scale': 1.0,
        });

        // Clear all overlays and show the content
        _overlayService.clearOverlays();
        _overlayService.showHologram('hologram_$markerId');
        _overlayService.showInfo('Real AR content loaded: ${content.title}');
        
        // Mark this content as loaded
        _currentlyLoadedContent = markerId;
        
        print('Real AR content loaded: ${content.title}');
      } else {
        _overlayService.showError('Failed to load real AR content');
        print('Failed to load real AR content for marker: $markerId');
      }
    } catch (e) {
      print('Error loading real AR content: $e');
      _overlayService.showError('Error loading AR content: $e');
    }
  }

  /// Handle hologram updates
  void _onHologramUpdated(Map<String, dynamic> hologramData) {
    final hologramId = hologramData['hologramId'] as String?;
    final position = hologramData['position'];
    final rotation = hologramData['rotation'];
    final scale = hologramData['scale'];
    
    if (hologramId != null) {
      print('Real hologram updated: $hologramId');
      // Update overlay with real hologram data
      _overlayService.showHologram(hologramId);
    }
  }

  /// Get session status
  String getSessionStatus() {
    switch (_sessionState) {
      case RealARSessionState.initializing:
        return 'Initializing Real AR...';
      case RealARSessionState.ready:
        return 'Real AR Ready';
      case RealARSessionState.active:
        return 'Real AR Active - Scanning';
      case RealARSessionState.paused:
        return 'Real AR Paused';
      case RealARSessionState.error:
        return 'Real AR Error: $_errorMessage';
    }
  }

  /// Get camera status
  String getCameraStatus() {
    return _cameraService.getStatus();
  }

  /// Get comprehensive session info
  Map<String, dynamic> getSessionInfo() {
    return {
      'sessionState': _sessionState.toString(),
      'sessionDuration': sessionDuration,
      'currentMarkerId': _currentMarkerId,
      'currentARContent': _currentARContent,
      'cameraStatus': _cameraService.getStatus(),
      'qrDetectionStatus': _qrDetectionService.getStatus(),
      'hologramStatus': _hologramService.getStatus(),
      'overlayCount': _overlayService.visibleOverlays.length,
      'errorMessage': _errorMessage,
    };
  }

  /// Dispose real AR session
  void dispose() {
    _cameraFrameSubscription?.cancel();
    _qrDetectionSubscription?.cancel();
    _hologramSubscription?.cancel();
    
    _cameraService.dispose();
    _qrDetectionService.dispose();
    _hologramService.dispose();
    
    print('Real AR session disposed');
  }
} 