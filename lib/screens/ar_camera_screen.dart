import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/real_ar_session_manager.dart';
import '../widgets/ar_overlay_widget.dart';
import '../services/database_init_service.dart';
import 'images_page.dart';
import 'videos_page.dart';
import 'audio_page.dart';
import 'stories_page.dart';

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
  bool _showQRCodePanel = false;

  @override
  void initState() {
    super.initState();
    _initializeRealAR();
    _setupNavigationCallback();
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

  void _toggleQRCodePanel() {
    setState(() {
      _showQRCodePanel = !_showQRCodePanel;
    });
  }
  
  /// Setup navigation callback for AR overlays
  void _setupNavigationCallback() {
    _realARSessionManager.overlayService.setNavigationCallback(_navigateToScreen);
  }
  
  /// Navigate to specific screen with arguments
  void _navigateToScreen(String screen, Map<String, dynamic>? arguments) {
    print('Navigating to: $screen with arguments: $arguments');
    
    // Close the AR overlay first
    _realARSessionManager.overlayService.clearOverlays();
    
    // Get memorial ID from arguments
    final memorialId = arguments?['memorialId'] as String?;
    
    // Navigate based on screen name
    switch (screen) {
      case '/images':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImagesPage(memorialId: memorialId),
          ),
        );
        break;
      case '/videos':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideosPage(memorialId: memorialId),
          ),
        );
        break;
      case '/audio':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPage(memorialId: memorialId),
          ),
        );
        break;
      case '/stories':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoriesPage(memorialId: memorialId),
          ),
        );
        break;
      case '/memorial-details':
        Navigator.pushNamed(context, '/memorial-details', arguments: arguments);
        break;
      default:
        print('Unknown screen: $screen');
    }
  }
  
  /// Show content message for unimplemented features
  void _showContentMessage(String contentType, String? memorialId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$contentType Content'),
        content: Text('$contentType content for ${_getMemorialName(memorialId)} will be displayed here.\n\nThis feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Get memorial name from ID
  String _getMemorialName(String? memorialId) {
    if (memorialId == null) return 'Unknown Memorial';
    if (memorialId.contains('NAOMI')) return 'Naomi N.';
    if (memorialId.contains('JOHN')) return 'John M.';
    if (memorialId.contains('SARAH')) return 'Sarah K.';
    return 'Unknown Memorial';
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
             body: AROverlayWidget(
         overlayService: _realARSessionManager.overlayService,
         child: Stack(
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
          
          // QR Code Panel Toggle Button
          Positioned(
            top: 100,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'qr_panel_toggle',
              onPressed: _toggleQRCodePanel,
              backgroundColor: Color(0xFF7bb6e7),
              mini: true,
              child: Icon(
                _showQRCodePanel ? Icons.qr_code_scanner : Icons.qr_code,
                color: Colors.white,
              ),
            ),
          ),
          
                     // QR Code Display Panel
           if (_showQRCodePanel)
             Positioned(
               top: 160,
               right: 20,
               child: Container(
                 width: 200,
                 height: 300, // Fixed height to prevent overflow
                 padding: EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.8),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Color(0xFF7bb6e7), width: 2),
                 ),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       'Scan These QR Codes',
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: 14,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     SizedBox(height: 12),
                     Expanded(
                       child: SingleChildScrollView(
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             _buildQRCodeItem('NAOMI-N-MEMORIAL-001', 'Naomi N.'),
                             SizedBox(height: 8),
                             _buildQRCodeItem('JOHN-M-MEMORIAL-002', 'John M.'),
                             SizedBox(height: 8),
                             _buildQRCodeItem('SARAH-K-MEMORIAL-003', 'Sarah K.'),
                           ],
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
           ],
         ),
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
            SizedBox(height: 8),
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

  Widget _buildQRCodeItem(String qrData, String title) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Color(0xFF7bb6e7), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Container(
            width: 50,
            height: 50,
            child: QrImageView(
              data: qrData,
              size: 50,
              backgroundColor: Colors.white,
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          SizedBox(height: 2),
          Text(
            qrData,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 7,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 