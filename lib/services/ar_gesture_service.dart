import 'package:flutter/material.dart';
import 'dart:async';

class ARGestureService {
  static final ARGestureService _instance = ARGestureService._internal();
  factory ARGestureService() => _instance;
  ARGestureService._internal();

  bool _isActive = false;
  bool _isListening = false;
  
  // Gesture recognition settings
  double _tapThreshold = 300.0; // milliseconds
  double _doubleTapThreshold = 500.0; // milliseconds
  double _longPressThreshold = 1000.0; // milliseconds
  double _swipeThreshold = 50.0; // pixels
  
  // Gesture state
  DateTime? _lastTapTime;
  int _tapCount = 0;
  Offset? _lastTapPosition;
  Timer? _tapTimer;
  Timer? _longPressTimer;
  
  // Gesture callbacks
  Function(Offset position)? _onTap;
  Function(Offset position)? _onDoubleTap;
  Function(Offset position)? _onLongPress;
  Function(Offset start, Offset end)? _onSwipe;
  Function(Offset position, double scale)? _onPinch;
  Function(Offset position, double rotation)? _onRotate;
  
  // Stream controllers for gesture events
  final StreamController<ARGestureEvent> _gestureController = StreamController<ARGestureEvent>.broadcast();

  // Getters
  bool get isActive => _isActive;
  bool get isListening => _isListening;
  Stream<ARGestureEvent> get gestureStream => _gestureController.stream;

  /// Start gesture recognition
  Future<void> startGestureRecognition() async {
    try {
      print('Starting AR gesture recognition...');
      _isActive = true;
      _isListening = true;
      
      print('AR gesture recognition started');
    } catch (e) {
      print('Error starting gesture recognition: $e');
    }
  }

  /// Stop gesture recognition
  Future<void> stopGestureRecognition() async {
    try {
      _isActive = false;
      _isListening = false;
      _clearTimers();
      print('AR gesture recognition stopped');
    } catch (e) {
      print('Error stopping gesture recognition: $e');
    }
  }

  /// Process tap gesture
  void processTap(Offset position) {
    if (!_isListening) return;
    
    try {
      print('Processing tap at position: $position');
      
      final now = DateTime.now();
      
      if (_lastTapTime != null && 
          now.difference(_lastTapTime!).inMilliseconds < _tapThreshold &&
          _lastTapPosition != null &&
          (position - _lastTapPosition!).distance < 50) {
        
        // Double tap detected
        _tapCount++;
        if (_tapCount == 2) {
          _onDoubleTap?.call(position);
          _emitGestureEvent(ARGestureType.doubleTap, position);
          _resetTapState();
        }
      } else {
        // Single tap
        _tapCount = 1;
        _lastTapTime = now;
        _lastTapPosition = position;
        
        // Start tap timer
        _tapTimer?.cancel();
        _tapTimer = Timer(Duration(milliseconds: _tapThreshold.toInt()), () {
          if (_tapCount == 1) {
            _onTap?.call(position);
            _emitGestureEvent(ARGestureType.tap, position);
          }
          _resetTapState();
        });
        
        // Start long press timer
        _longPressTimer?.cancel();
        _longPressTimer = Timer(Duration(milliseconds: _longPressThreshold.toInt()), () {
          if (_tapCount == 1) {
            _onLongPress?.call(position);
            _emitGestureEvent(ARGestureType.longPress, position);
            _resetTapState();
          }
        });
      }
      
    } catch (e) {
      print('Error processing tap: $e');
    }
  }

  /// Process swipe gesture
  void processSwipe(Offset start, Offset end) {
    if (!_isListening) return;
    
    try {
      final distance = (end - start).distance;
      if (distance >= _swipeThreshold) {
        print('Processing swipe from $start to $end');
        
        _onSwipe?.call(start, end);
        _emitGestureEvent(ARGestureType.swipe, start, end: end);
      }
    } catch (e) {
      print('Error processing swipe: $e');
    }
  }

  /// Process pinch gesture
  void processPinch(Offset position, double scale) {
    if (!_isListening) return;
    
    try {
      print('Processing pinch at position: $position with scale: $scale');
      
      _onPinch?.call(position, scale);
      _emitGestureEvent(ARGestureType.pinch, position, scale: scale);
    } catch (e) {
      print('Error processing pinch: $e');
    }
  }

  /// Process rotate gesture
  void processRotate(Offset position, double rotation) {
    if (!_isListening) return;
    
    try {
      print('Processing rotate at position: $position with rotation: $rotation');
      
      _onRotate?.call(position, rotation);
      _emitGestureEvent(ARGestureType.rotate, position, rotation: rotation);
    } catch (e) {
      print('Error processing rotate: $e');
    }
  }

  /// Reset tap state
  void _resetTapState() {
    _tapCount = 0;
    _lastTapTime = null;
    _lastTapPosition = null;
    _clearTimers();
  }

  /// Clear timers
  void _clearTimers() {
    _tapTimer?.cancel();
    _longPressTimer?.cancel();
  }

  /// Emit gesture event
  void _emitGestureEvent(ARGestureType type, Offset position, {Offset? end, double? scale, double? rotation}) {
    final event = ARGestureEvent(
      type: type,
      position: position,
      end: end,
      scale: scale,
      rotation: rotation,
      timestamp: DateTime.now(),
    );
    
    _gestureController.add(event);
  }

  /// Set tap callback
  void setTapCallback(Function(Offset position) callback) {
    _onTap = callback;
  }

  /// Set double tap callback
  void setDoubleTapCallback(Function(Offset position) callback) {
    _onDoubleTap = callback;
  }

  /// Set long press callback
  void setLongPressCallback(Function(Offset position) callback) {
    _onLongPress = callback;
  }

  /// Set swipe callback
  void setSwipeCallback(Function(Offset start, Offset end) callback) {
    _onSwipe = callback;
  }

  /// Set pinch callback
  void setPinchCallback(Function(Offset position, double scale) callback) {
    _onPinch = callback;
  }

  /// Set rotate callback
  void setRotateCallback(Function(Offset position, double rotation) callback) {
    _onRotate = callback;
  }

  /// Set gesture thresholds
  void setGestureThresholds({
    double? tapThreshold,
    double? doubleTapThreshold,
    double? longPressThreshold,
    double? swipeThreshold,
  }) {
    if (tapThreshold != null) _tapThreshold = tapThreshold;
    if (doubleTapThreshold != null) _doubleTapThreshold = doubleTapThreshold;
    if (longPressThreshold != null) _longPressThreshold = longPressThreshold;
    if (swipeThreshold != null) _swipeThreshold = swipeThreshold;
    
    print('Gesture thresholds updated');
  }

  /// Get gesture statistics
  Map<String, dynamic> getGestureStats() {
    return {
      'isActive': _isActive,
      'isListening': _isListening,
      'tapThreshold': _tapThreshold,
      'doubleTapThreshold': _doubleTapThreshold,
      'longPressThreshold': _longPressThreshold,
      'swipeThreshold': _swipeThreshold,
      'tapCount': _tapCount,
      'lastTapTime': _lastTapTime?.toIso8601String(),
      'lastTapPosition': _lastTapPosition?.toString(),
    };
  }

  /// Clear all callbacks
  void clearCallbacks() {
    _onTap = null;
    _onDoubleTap = null;
    _onLongPress = null;
    _onSwipe = null;
    _onPinch = null;
    _onRotate = null;
    print('Gesture callbacks cleared');
  }

  /// Dispose gesture service
  void dispose() {
    _clearTimers();
    _gestureController.close();
    clearCallbacks();
    print('AR gesture service disposed');
  }
}

/// AR Gesture Types
enum ARGestureType {
  tap,
  doubleTap,
  longPress,
  swipe,
  pinch,
  rotate,
}

/// AR Gesture Event
class ARGestureEvent {
  final ARGestureType type;
  final Offset position;
  final Offset? end;
  final double? scale;
  final double? rotation;
  final DateTime timestamp;

  ARGestureEvent({
    required this.type,
    required this.position,
    this.end,
    this.scale,
    this.rotation,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'position': {'x': position.dx, 'y': position.dy},
      'end': end != null ? {'x': end!.dx, 'y': end!.dy} : null,
      'scale': scale,
      'rotation': rotation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ARGestureEvent(type: $type, position: $position, timestamp: $timestamp)';
  }
}

/// AR Gesture Widget
class ARGestureDetector extends StatefulWidget {
  final Widget child;
  final ARGestureService gestureService;
  final Function(Offset position)? onTap;
  final Function(Offset position)? onDoubleTap;
  final Function(Offset position)? onLongPress;
  final Function(Offset start, Offset end)? onSwipe;
  final Function(Offset position, double scale)? onPinch;
  final Function(Offset position, double rotation)? onRotate;

  const ARGestureDetector({
    super.key,
    required this.child,
    required this.gestureService,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSwipe,
    this.onPinch,
    this.onRotate,
  });

  @override
  State<ARGestureDetector> createState() => _ARGestureDetectorState();
}

class _ARGestureDetectorState extends State<ARGestureDetector> {
  @override
  void initState() {
    super.initState();
    _setupGestureCallbacks();
  }

  void _setupGestureCallbacks() {
    if (widget.onTap != null) {
      widget.gestureService.setTapCallback(widget.onTap!);
    }
    if (widget.onDoubleTap != null) {
      widget.gestureService.setDoubleTapCallback(widget.onDoubleTap!);
    }
    if (widget.onLongPress != null) {
      widget.gestureService.setLongPressCallback(widget.onLongPress!);
    }
    if (widget.onSwipe != null) {
      widget.gestureService.setSwipeCallback(widget.onSwipe!);
    }
    if (widget.onPinch != null) {
      widget.gestureService.setPinchCallback(widget.onPinch!);
    }
    if (widget.onRotate != null) {
      widget.gestureService.setRotateCallback(widget.onRotate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        widget.gestureService.processTap(details.localPosition);
      },
      onPanUpdate: (details) {
        // Handle swipe gestures
        // This is a simplified implementation
        if (details.delta.distance > 10) {
          widget.gestureService.processSwipe(
            details.localPosition - details.delta,
            details.localPosition,
          );
        }
      },
      child: widget.child,
    );
  }
} 