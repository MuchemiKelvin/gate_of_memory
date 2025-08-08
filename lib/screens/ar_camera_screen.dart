import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/real_ar_session_manager.dart';
import '../widgets/ar_overlay_widget.dart';
import '../services/database_init_service.dart';

class ARCameraScreen extends StatefulWidget {
  const ARCameraScreen({super.key});

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  final RealARSessionManager _realARSessionManager = RealARSessionManager();
  
  bool _isInitialized = false;
  String _statusMessage = 'Initializing Real AR...';
  bool _showOverlayControls = false;
  bool _showCameraControls = false;
  bool _showContentInfo = false;
  bool _cameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRealAR();
  }

  Future<void> _initializeRealAR() async {
    try {
      print('Initializing REAL AR system...');
      setState(() {
        _statusMessage = 'Initializing Real AR...';
      });
      
      // Initialize real AR session
      final success = await _realARSessionManager.initialize();
      if (!success) {
        setState(() {
          _statusMessage = 'Failed to initialize Real AR: ${_realARSessionManager.errorMessage}';
        });
        return;
      }
      
      // Test database connection
      await _realARSessionManager.contentLoadingService.testDatabaseConnection();
      
      // Start real AR session
      await _realARSessionManager.startSession();
      
      setState(() {
        _isInitialized = true;
        _cameraInitialized = true;
        _statusMessage = 'Real AR Active - Point camera at QR marker';
      });
      
      print('Real AR system initialized successfully');
    } catch (e) {
      print('Error initializing real AR: $e');
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _realARSessionManager.dispose();
    super.dispose();
  }

  void _switchCamera() {
    _realARSessionManager.cameraService.switchCamera();
    setState(() {});
  }

  void _takePhoto() async {
    await _realARSessionManager.cameraService.takePhoto();
  }

  void _toggleOverlayControls() {
    setState(() {
      _showOverlayControls = !_showOverlayControls;
    });
  }

  void _toggleCameraControls() {
    setState(() {
      _showCameraControls = !_showCameraControls;
    });
  }

  void _showARSettings() {
    // Show AR settings dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AR Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Marker Detection'),
              subtitle: Text(_realARSessionManager.isMarkerDetected ? 'Active' : 'Inactive'),
            ),
            ListTile(
              title: Text('Session State'),
              subtitle: Text(_realARSessionManager.sessionState.toString().split('.').last),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleARSession() {
    if (_realARSessionManager.sessionState == RealARSessionState.active) {
      _realARSessionManager.pauseSession();
    } else {
      _realARSessionManager.resumeSession();
    }
    setState(() {});
  }

  void _testQRDetection() {
    _realARSessionManager.qrDetectionService.triggerTestDetection();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AR Camera',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera, color: Colors.white),
            onPressed: _switchCamera,
            tooltip: 'Switch Camera',
          ),
          IconButton(
            icon: Icon(Icons.camera_alt, color: Colors.white),
            onPressed: _takePhoto,
            tooltip: 'Take Photo',
          ),
          IconButton(
            icon: Icon(Icons.layers, color: Colors.white),
            onPressed: _toggleOverlayControls,
            tooltip: 'Overlay Controls',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _showARSettings,
            tooltip: 'AR Settings',
          ),
          IconButton(
            icon: Icon(Icons.qr_code, color: Colors.white),
            onPressed: _testQRDetection,
            tooltip: 'Test QR Detection',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          Container(
            width: double.infinity,
            height: double.infinity,
            child: _cameraInitialized
                ? _buildCameraPreview()
                : _buildCameraLoadingView(),
          ),
          
          // AR Status Overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // AR Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pause/Resume Button
                FloatingActionButton(
                  heroTag: 'ar_pause_resume',
                  onPressed: _toggleARSession,
                  backgroundColor: Color(0xFF7bb6e7),
                  child: Icon(
                    _realARSessionManager.sessionState == RealARSessionState.active
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                
                // Marker Detection Status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _realARSessionManager.isMarkerDetected
                        ? Colors.green.withOpacity(0.8)
                        : Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _realARSessionManager.isMarkerDetected
                        ? 'Marker Detected'
                        : 'Scanning...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Camera Controls Toggle
                FloatingActionButton(
                  heroTag: 'ar_camera_controls',
                  onPressed: _toggleCameraControls,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // AR Instructions
          if (!_realARSessionManager.isMarkerDetected)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Point camera at QR marker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hold steady to detect marker',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final cameraController = _realARSessionManager.cameraService.cameraController;
    
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Camera Ready',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Point at QR code to scan',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return CameraPreview(cameraController);
  }

  Widget _buildCameraLoadingView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF7bb6e7),
            ),
            SizedBox(height: 16),
            Text(
              'Initializing Real Camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please grant camera permission',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 