import 'package:flutter/material.dart';
import '../services/ar_session_manager.dart';
import '../widgets/ar_overlay_widget.dart';

class ARCameraScreen extends StatefulWidget {
  const ARCameraScreen({super.key});

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  final ARSessionManager _arSessionManager = ARSessionManager();
  bool _isInitialized = false;
  String _statusMessage = 'Initializing AR...';
  bool _showOverlayControls = false;

  @override
  void initState() {
    super.initState();
    _initializeAR();
  }

  Future<void> _initializeAR() async {
    try {
      print('Initializing AR camera screen...');
      
      final success = await _arSessionManager.initialize();
      if (success) {
        setState(() {
          _isInitialized = true;
          _statusMessage = _arSessionManager.getSessionStatus();
        });
        
        // Start AR session
        await _arSessionManager.startSession();
        setState(() {
          _statusMessage = _arSessionManager.getSessionStatus();
        });
        
        print('AR camera screen initialized successfully');
      } else {
        setState(() {
          _statusMessage = 'Failed to initialize AR: ${_arSessionManager.errorMessage}';
        });
      }
    } catch (e) {
      print('Error initializing AR camera screen: $e');
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _arSessionManager.dispose();
    super.dispose();
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
        ],
      ),
      body: AROverlayContainer(
        overlayService: _arSessionManager.overlayService,
        child: Stack(
          children: [
            // Camera Preview (Simulated)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Simulated Camera View
                    Container(
                      width: 300,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFF7bb6e7), width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 80,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Simulated Camera',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _arSessionManager.getCameraStatus(),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 20),
                          if (!_isInitialized)
                            CircularProgressIndicator(
                              color: Color(0xFF7bb6e7),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
                      _arSessionManager.sessionState == ARSessionState.active
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Marker Detection Status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _arSessionManager.isMarkerDetected
                          ? Colors.green.withOpacity(0.8)
                          : Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _arSessionManager.isMarkerDetected
                          ? 'Marker Detected'
                          : 'Scanning...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Settings Button
                  FloatingActionButton(
                    heroTag: 'ar_settings',
                    onPressed: _showARSettings,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // AR Instructions
            if (!_arSessionManager.isMarkerDetected)
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
                      Icon(
                        Icons.qr_code_scanner,
                        color: Color(0xFF7bb6e7),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Point camera at a QR marker to view holograms in AR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '(Simulated for emulator testing)',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Overlay Controls Panel
            if (_showOverlayControls)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFF7bb6e7), width: 2),
                  ),
                  child: AROverlayControls(
                    overlayService: _arSessionManager.overlayService,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchCamera() async {
    try {
      await _arSessionManager.switchCamera();
      setState(() {
        _statusMessage = 'Camera switched';
      });
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photoPath = await _arSessionManager.takeARPhoto();
      if (photoPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo saved: $photoPath')),
        );
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  Future<void> _toggleARSession() async {
    try {
      if (_arSessionManager.sessionState == ARSessionState.active) {
        await _arSessionManager.pauseSession();
      } else if (_arSessionManager.sessionState == ARSessionState.paused) {
        await _arSessionManager.resumeSession();
      }
      setState(() {
        _statusMessage = _arSessionManager.getSessionStatus();
      });
    } catch (e) {
      print('Error toggling AR session: $e');
    }
  }

  void _toggleOverlayControls() {
    setState(() {
      _showOverlayControls = !_showOverlayControls;
    });
  }

  void _showARSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AR Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('AR Session State'),
              subtitle: Text(_arSessionManager.sessionState.toString()),
            ),
            ListTile(
              title: Text('Camera Status'),
              subtitle: Text(_arSessionManager.getCameraStatus()),
            ),
            ListTile(
              title: Text('Marker Detected'),
              subtitle: Text(_arSessionManager.isMarkerDetected ? 'Yes' : 'No'),
            ),
            if (_arSessionManager.isMarkerDetected)
              ListTile(
                title: Text('Current Marker'),
                subtitle: Text(_arSessionManager.currentMarkerId),
              ),
            ListTile(
              title: Text('AR Supported'),
              subtitle: Text(_arSessionManager.isARSupported ? 'Yes' : 'No'),
            ),
            ListTile(
              title: Text('Active Overlays'),
              subtitle: Text('${_arSessionManager.overlayService.visibleOverlays.length}'),
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
} 