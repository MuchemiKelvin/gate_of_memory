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
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overlay Controls - First Row
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              // Show Marker Detection
              _buildControlButton(
                onPressed: () {
                  overlayService.showMarkerDetection('test_marker_123');
                },
                icon: Icons.qr_code_scanner,
                label: 'Marker',
                color: Colors.green,
              ),
              
              // Show Hologram
              _buildControlButton(
                onPressed: () {
                  overlayService.showHologram('hologram_001');
                },
                icon: Icons.view_in_ar,
                label: 'Hologram',
                color: Color(0xFF7bb6e7),
              ),
              
              // Show Info
              _buildControlButton(
                onPressed: () {
                  overlayService.showInfo('AR Info Message');
                },
                icon: Icons.info,
                label: 'Info',
                color: Colors.blue,
              ),
            ],
          ),
          
          SizedBox(height: 4),
          
          // Second Row
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              // Show Loading
              _buildControlButton(
                onPressed: () {
                  overlayService.showLoading('Loading AR content...');
                },
                icon: Icons.hourglass_empty,
                label: 'Loading',
                color: Colors.orange,
              ),
              
              // Show Error
              _buildControlButton(
                onPressed: () {
                  overlayService.showError('AR Error occurred');
                },
                icon: Icons.error,
                label: 'Error',
                color: Colors.red,
              ),
              
              // Clear All
              _buildControlButton(
                onPressed: () {
                  overlayService.clearOverlays();
                },
                icon: Icons.clear_all,
                label: 'Clear',
                color: Colors.grey,
              ),
            ],
          ),
          
          SizedBox(height: 4),
          
          // Overlay Count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Overlays: ${overlayService.visibleOverlays.length}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: TextStyle(fontSize: 10),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size(0, 0),
        ),
      ),
    );
  }
} 