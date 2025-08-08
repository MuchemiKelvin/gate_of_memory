import 'package:flutter/material.dart';
import 'dart:math' as math;

enum AROverlayType {
  marker,
  hologram,
  info,
  instruction,
  loading,
  error,
}

class AROverlay {
  final String id;
  final AROverlayType type;
  final Widget widget;
  final Offset position;
  final double scale;
  final double rotation;
  final bool isVisible;
  final Duration? autoHideDuration;

  AROverlay({
    required this.id,
    required this.type,
    required this.widget,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isVisible = true,
    this.autoHideDuration,
  });

  AROverlay copyWith({
    String? id,
    AROverlayType? type,
    Widget? widget,
    Offset? position,
    double? scale,
    double? rotation,
    bool? isVisible,
    Duration? autoHideDuration,
  }) {
    return AROverlay(
      id: id ?? this.id,
      type: type ?? this.type,
      widget: widget ?? this.widget,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isVisible: isVisible ?? this.isVisible,
      autoHideDuration: autoHideDuration ?? this.autoHideDuration,
    );
  }
}

class AROverlayService {
  static final AROverlayService _instance = AROverlayService._internal();
  factory AROverlayService() => _instance;
  AROverlayService._internal();

  final Map<String, AROverlay> _overlays = {};
  final List<Function()> _listeners = [];

  // Getters
  Map<String, AROverlay> get overlays => Map.unmodifiable(_overlays);
  List<AROverlay> get visibleOverlays => _overlays.values.where((overlay) => overlay.isVisible).toList();

  /// Add overlay listener
  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  /// Remove overlay listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  /// Notify listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Add AR overlay
  void addOverlay(AROverlay overlay) {
    _overlays[overlay.id] = overlay;
    _notifyListeners();

    // Auto-hide if duration is specified
    if (overlay.autoHideDuration != null) {
      Future.delayed(overlay.autoHideDuration!, () {
        removeOverlay(overlay.id);
      });
    }

    print('AR overlay added: ${overlay.id} (${overlay.type})');
  }

  /// Remove AR overlay
  void removeOverlay(String id) {
    if (_overlays.containsKey(id)) {
      _overlays.remove(id);
      _notifyListeners();
      print('AR overlay removed: $id');
    }
  }

  /// Update AR overlay
  void updateOverlay(String id, AROverlay overlay) {
    if (_overlays.containsKey(id)) {
      _overlays[id] = overlay;
      _notifyListeners();
      print('AR overlay updated: $id');
    }
  }

  /// Clear all overlays
  void clearOverlays() {
    _overlays.clear();
    _notifyListeners();
    print('All AR overlays cleared');
  }

  /// Clear overlays by type
  void clearOverlaysByType(AROverlayType type) {
    _overlays.removeWhere((key, overlay) => overlay.type == type);
    _notifyListeners();
    print('AR overlays cleared for type: $type');
  }

  /// Show marker detection overlay
  void showMarkerDetection(String markerId, {Offset? position}) {
    final overlay = AROverlay(
      id: 'marker_$markerId',
      type: AROverlayType.marker,
      widget: _buildMarkerDetectionWidget(markerId),
      position: position ?? Offset.zero,
      autoHideDuration: Duration(seconds: 3),
    );
    addOverlay(overlay);
  }

  /// Show hologram overlay
  void showHologram(String hologramId, {Offset? position, double? scale}) {
    final overlay = AROverlay(
      id: 'hologram_$hologramId',
      type: AROverlayType.hologram,
      widget: _buildHologramWidget(hologramId),
      position: position ?? Offset.zero,
      scale: scale ?? 1.0,
    );
    addOverlay(overlay);
  }

  /// Show info overlay
  void showInfo(String message, {Duration? duration}) {
    final overlay = AROverlay(
      id: 'info_${DateTime.now().millisecondsSinceEpoch}',
      type: AROverlayType.info,
      widget: _buildInfoWidget(message),
      position: Offset(0, -100),
      autoHideDuration: duration ?? Duration(seconds: 5),
    );
    addOverlay(overlay);
  }

  /// Show instruction overlay
  void showInstruction(String instruction) {
    final overlay = AROverlay(
      id: 'instruction_${DateTime.now().millisecondsSinceEpoch}',
      type: AROverlayType.instruction,
      widget: _buildInstructionWidget(instruction),
      position: Offset(0, 100),
    );
    addOverlay(overlay);
  }

  /// Show loading overlay
  void showLoading(String message) {
    final overlay = AROverlay(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      type: AROverlayType.loading,
      widget: _buildLoadingWidget(message),
      position: Offset.zero,
    );
    addOverlay(overlay);
  }

  /// Show error overlay
  void showError(String error) {
    final overlay = AROverlay(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      type: AROverlayType.error,
      widget: _buildErrorWidget(error),
      position: Offset(0, 50),
      autoHideDuration: Duration(seconds: 5),
    );
    addOverlay(overlay);
  }

  /// Build marker detection widget
  Widget _buildMarkerDetectionWidget(String markerId) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Marker Detected!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'ID: $markerId',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build hologram widget
  Widget _buildHologramWidget(String hologramId) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7bb6e7).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Hologram placeholder
              Center(
                child: Icon(
                  Icons.view_in_ar,
                  size: 80,
                  color: Color(0xFF7bb6e7),
                ),
              ),
              // Hologram ID
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hologramId,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build info widget
  Widget _buildInfoWidget(String message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build instruction widget
  Widget _buildInstructionWidget(String instruction) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF7bb6e7), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF7bb6e7),
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            instruction,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build loading widget
  Widget _buildLoadingWidget(String message) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF7bb6e7),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget(String error) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dispose overlay service
  void dispose() {
    _overlays.clear();
    _listeners.clear();
    print('AR overlay service disposed');
  }
} 