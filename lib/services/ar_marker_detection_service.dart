import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class ARMarkerDetectionService {
  static final ARMarkerDetectionService _instance = ARMarkerDetectionService._internal();
  factory ARMarkerDetectionService() => _instance;
  ARMarkerDetectionService._internal();

  bool _isActive = false;
  bool _isDetecting = false;
  String? _lastDetectedMarker;
  DateTime? _lastDetectionTime;
  
  // Detection settings
  double _detectionConfidence = 0.8;
  Duration _detectionTimeout = Duration(seconds: 5);
  int _minDetectionCount = 3;
  
  // Detection state
  int _currentDetectionCount = 0;
  Timer? _detectionTimer;
  final StreamController<ARMarkerDetection> _detectionController = StreamController<ARMarkerDetection>.broadcast();
  
  // Known markers database (simulated)
  final Map<String, Map<String, dynamic>> _knownMarkers = {
    'NAOMI-N-MEMORIAL-001': {
      'id': 'NAOMI-N-MEMORIAL-001',
      'type': 'memorial',
      'name': 'Naomi Memorial',
      'content': 'hologram_naomi',
      'position': {'x': 0.0, 'y': 0.0, 'z': 0.0},
      'scale': 1.0,
      'rotation': 0.0,
    },
    'JOHN-M-MEMORIAL-002': {
      'id': 'JOHN-M-MEMORIAL-002',
      'type': 'memorial',
      'name': 'John Memorial',
      'content': 'hologram_john',
      'position': {'x': 0.0, 'y': 0.0, 'z': 0.0},
      'scale': 1.0,
      'rotation': 0.0,
    },
    'SARAH-K-MEMORIAL-003': {
      'id': 'SARAH-K-MEMORIAL-003',
      'type': 'memorial',
      'name': 'Sarah Memorial',
      'content': 'hologram_sarah',
      'position': {'x': 0.0, 'y': 0.0, 'z': 0.0},
      'scale': 1.0,
      'rotation': 0.0,
    },
    'test_marker_123': {
      'id': 'test_marker_123',
      'type': 'test',
      'name': 'Test Marker',
      'content': 'test_hologram',
      'position': {'x': 0.0, 'y': 0.0, 'z': 0.0},
      'scale': 1.0,
      'rotation': 0.0,
    },
  };

  // Getters
  bool get isActive => _isActive;
  bool get isDetecting => _isDetecting;
  String? get lastDetectedMarker => _lastDetectedMarker;
  DateTime? get lastDetectionTime => _lastDetectionTime;
  double get detectionConfidence => _detectionConfidence;
  Stream<ARMarkerDetection> get detectionStream => _detectionController.stream;

  /// Start marker detection
  Future<void> startDetection() async {
    try {
      print('Starting AR marker detection...');
      _isActive = true;
      _isDetecting = true;
      
      // Start detection simulation
      _startDetectionSimulation();
      
      print('AR marker detection started');
    } catch (e) {
      print('Error starting marker detection: $e');
    }
  }

  /// Stop marker detection
  Future<void> stopDetection() async {
    try {
      _isActive = false;
      _isDetecting = false;
      _stopDetectionSimulation();
      print('AR marker detection stopped');
    } catch (e) {
      print('Error stopping marker detection: $e');
    }
  }

  /// Start detection simulation
  void _startDetectionSimulation() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_isDetecting) {
        _simulateMarkerDetection();
      }
    });
  }

  /// Stop detection simulation
  void _stopDetectionSimulation() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
  }

  /// Simulate marker detection
  void _simulateMarkerDetection() {
    // Simulate random marker detection
    final random = math.Random();
    final detectionChance = random.nextDouble();
    
    if (detectionChance < 0.3) { // 30% chance of detection
      final markerIds = _knownMarkers.keys.toList();
      final randomMarkerId = markerIds[random.nextInt(markerIds.length)];
      
      _processMarkerDetection(randomMarkerId);
    }
  }

  /// Process detected marker
  void _processMarkerDetection(String markerId) {
    try {
      print('Processing marker detection: $markerId');
      
      if (!_knownMarkers.containsKey(markerId)) {
        print('Unknown marker detected: $markerId');
        return;
      }
      
      final markerData = _knownMarkers[markerId]!;
      final detection = ARMarkerDetection(
        markerId: markerId,
        markerData: markerData,
        confidence: _detectionConfidence,
        timestamp: DateTime.now(),
        position: _getRandomPosition(),
        boundingBox: _getRandomBoundingBox(),
      );
      
      // Update detection state
      _lastDetectedMarker = markerId;
      _lastDetectionTime = DateTime.now();
      _currentDetectionCount++;
      
      // Emit detection event
      _detectionController.add(detection);
      
      print('Marker detection processed: $markerId (confidence: ${_detectionConfidence})');
      
    } catch (e) {
      print('Error processing marker detection: $e');
    }
  }

  /// Get random position for simulation
  Map<String, double> _getRandomPosition() {
    final random = math.Random();
    return {
      'x': (random.nextDouble() - 0.5) * 2.0,
      'y': (random.nextDouble() - 0.5) * 2.0,
      'z': random.nextDouble() * 2.0,
    };
  }

  /// Get random bounding box for simulation
  Map<String, double> _getRandomBoundingBox() {
    final random = math.Random();
    return {
      'x': random.nextDouble() * 0.8,
      'y': random.nextDouble() * 0.8,
      'width': 0.1 + random.nextDouble() * 0.2,
      'height': 0.1 + random.nextDouble() * 0.2,
    };
  }

  /// Add known marker to database
  void addKnownMarker(String markerId, Map<String, dynamic> markerData) {
    _knownMarkers[markerId] = markerData;
    print('Added known marker: $markerId');
  }

  /// Remove known marker from database
  void removeKnownMarker(String markerId) {
    _knownMarkers.remove(markerId);
    print('Removed known marker: $markerId');
  }

  /// Get all known markers
  Map<String, Map<String, dynamic>> getKnownMarkers() {
    return Map.unmodifiable(_knownMarkers);
  }

  /// Check if marker is known
  bool isKnownMarker(String markerId) {
    return _knownMarkers.containsKey(markerId);
  }

  /// Get marker data
  Map<String, dynamic>? getMarkerData(String markerId) {
    return _knownMarkers[markerId];
  }

  /// Set detection confidence
  void setDetectionConfidence(double confidence) {
    _detectionConfidence = confidence.clamp(0.0, 1.0);
    print('Detection confidence set to: $_detectionConfidence');
  }

  /// Set detection timeout
  void setDetectionTimeout(Duration timeout) {
    _detectionTimeout = timeout;
    print('Detection timeout set to: $_detectionTimeout');
  }

  /// Set minimum detection count
  void setMinDetectionCount(int count) {
    _minDetectionCount = count;
    print('Minimum detection count set to: $_minDetectionCount');
  }

  /// Clear detection state
  void clearDetectionState() {
    _lastDetectedMarker = null;
    _lastDetectionTime = null;
    _currentDetectionCount = 0;
    print('Detection state cleared');
  }

  /// Get detection statistics
  Map<String, dynamic> getDetectionStats() {
    return {
      'isActive': _isActive,
      'isDetecting': _isDetecting,
      'lastDetectedMarker': _lastDetectedMarker,
      'lastDetectionTime': _lastDetectionTime?.toIso8601String(),
      'currentDetectionCount': _currentDetectionCount,
      'detectionConfidence': _detectionConfidence,
      'detectionTimeout': _detectionTimeout.inSeconds,
      'minDetectionCount': _minDetectionCount,
      'knownMarkersCount': _knownMarkers.length,
    };
  }

  /// Dispose detection service
  void dispose() {
    _stopDetectionSimulation();
    _detectionController.close();
    print('AR marker detection service disposed');
  }
}

/// AR Marker Detection Event
class ARMarkerDetection {
  final String markerId;
  final Map<String, dynamic> markerData;
  final double confidence;
  final DateTime timestamp;
  final Map<String, double> position;
  final Map<String, double> boundingBox;

  ARMarkerDetection({
    required this.markerId,
    required this.markerData,
    required this.confidence,
    required this.timestamp,
    required this.position,
    required this.boundingBox,
  });

  Map<String, dynamic> toJson() {
    return {
      'markerId': markerId,
      'markerData': markerData,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'position': position,
      'boundingBox': boundingBox,
    };
  }

  @override
  String toString() {
    return 'ARMarkerDetection(markerId: $markerId, confidence: $confidence, timestamp: $timestamp)';
  }
} 