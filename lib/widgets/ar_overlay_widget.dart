import 'package:flutter/material.dart';
import '../services/ar_overlay_service.dart';
import 'dart:math' as math;

class AROverlayWidget extends StatefulWidget {
  final Widget child;
  final AROverlayService overlayService;

  const AROverlayWidget({
    super.key,
    required this.child,
    required this.overlayService,
  });

  @override
  State<AROverlayWidget> createState() => _AROverlayWidgetState();
}

class _AROverlayWidgetState extends State<AROverlayWidget> {
  @override
  void initState() {
    super.initState();
    widget.overlayService.addListener(_onOverlayChanged);
  }

  @override
  void dispose() {
    widget.overlayService.removeListener(_onOverlayChanged);
    super.dispose();
  }

  void _onOverlayChanged() {
    setState(() {
      // Rebuild when overlays change
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera view or background
        widget.child,
        
        // AR Overlays
        ...widget.overlayService.visibleOverlays.map((overlay) {
          return Positioned(
            left: overlay.position.dx,
            top: overlay.position.dy,
            child: Transform.scale(
              scale: overlay.scale,
              child: Transform.rotate(
                angle: overlay.rotation * math.pi / 180,
                child: _buildOverlayWidget(overlay),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildOverlayWidget(AROverlay overlay) {
    // Add animation for overlay appearance
    return AnimatedOpacity(
      opacity: overlay.isVisible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        child: overlay.widget,
      ),
    );
  }
}

/// AR Overlay Container Widget
class AROverlayContainer extends StatelessWidget {
  final Widget child;
  final AROverlayService overlayService;

  const AROverlayContainer({
    super.key,
    required this.child,
    required this.overlayService,
  });

  @override
  Widget build(BuildContext context) {
    return AROverlayWidget(
      overlayService: overlayService,
      child: child,
    );
  }
}

/// AR Overlay Controls Widget
class AROverlayControls extends StatelessWidget {
  final AROverlayService overlayService;

  const AROverlayControls({
    super.key,
    required this.overlayService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overlay Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Show Marker Detection
              ElevatedButton.icon(
                onPressed: () {
                  overlayService.showMarkerDetection('test_marker_123');
                },
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Marker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Show Hologram
              ElevatedButton.icon(
                onPressed: () {
                  overlayService.showHologram('hologram_001');
                },
                icon: Icon(Icons.view_in_ar),
                label: Text('Hologram'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7bb6e7),
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Show Info
              ElevatedButton.icon(
                onPressed: () {
                  overlayService.showInfo('AR Info Message');
                },
                icon: Icon(Icons.info),
                label: Text('Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Show Loading
              ElevatedButton.icon(
                onPressed: () {
                  overlayService.showLoading('Loading AR content...');
                },
                icon: Icon(Icons.hourglass_empty),
                label: Text('Loading'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Show Error
              ElevatedButton.icon(
                onPressed: () {
                  overlayService.showError('AR Error occurred');
                },
                icon: Icon(Icons.error),
                label: Text('Error'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Clear All
              ElevatedButton.icon(
                onPressed: () {
                  overlayService.clearOverlays();
                },
                icon: Icon(Icons.clear_all),
                label: Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Overlay Count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Overlays: ${overlayService.visibleOverlays.length}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 