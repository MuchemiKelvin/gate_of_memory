import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/real_ar_session_manager.dart';
import '../services/qr_code_service.dart';
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
  final QRCodeService _qrCodeService = QRCodeService();
  
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


  
  /// Setup navigation callback for AR overlays
  void _setupNavigationCallback() {
    _realARSessionManager.overlayService.setNavigationCallback(_navigateToScreen);
  }

  void _handleRealQRScan(BarcodeCapture capture) {
    try {
      final List<Barcode> barcodes = capture.barcodes;
      
      if (barcodes.isEmpty) return;

      for (final barcode in barcodes) {
        final qrCode = barcode.rawValue;
        
        if (qrCode != null && qrCode.isNotEmpty) {
          print('QR Code detected: $qrCode');
          _processRealQRCode(qrCode);
          return; // Process only the first valid QR code
        }
      }
    } catch (e) {
      print('Error in QR scanning: $e');
    }
  }

  Future<void> _processRealQRCode(String qrCode) async {
    try {
      // Validate QR code against database
      final memorial = await _qrCodeService.validateQRCode(qrCode);
      
      if (memorial != null) {
        // Valid memorial found - trigger AR content loading through session manager
        print('Valid memorial found: ${memorial.name}');
        
        // Use the AR session manager's QR detection handler
        await _realARSessionManager.onQRDetected({
          'qrCode': qrCode,
          'confidence': 0.9,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'position': {
            'x': 0.5,
            'y': 0.5,
            'width': 0.2,
            'height': 0.2,
          },
        });
      } else {
        // Invalid QR code - show error
        _realARSessionManager.overlayService.showError(_qrCodeService.getErrorMessage());
        print('Invalid QR code: ${_qrCodeService.lastError}');
      }
    } catch (e) {
      print('Error processing real QR code: $e');
      _realARSessionManager.overlayService.showError('Error processing QR code: $e');
    }
  }
  
  /// Navigate to specific screen with arguments
  void _navigateToScreen(String screen, Map<String, dynamic>? arguments) {
    print('Navigating to: $screen with arguments: $arguments');
    
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
        ).then((_) {
          // When returning from the content page, keep the AR overlay visible
          // Only clear overlays if we're not in an active AR session
          if (_realARSessionManager.sessionState != RealARSessionState.active) {
            _realARSessionManager.overlayService.clearOverlays();
          }
        });
        break;
      case '/videos':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideosPage(memorialId: memorialId),
          ),
        ).then((_) {
          // When returning from the content page, keep the AR overlay visible
          if (_realARSessionManager.sessionState != RealARSessionState.active) {
            _realARSessionManager.overlayService.clearOverlays();
          }
        });
        break;
      case '/audio':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPage(memorialId: memorialId),
          ),
        ).then((_) {
          // When returning from the content page, keep the AR overlay visible
          if (_realARSessionManager.sessionState != RealARSessionState.active) {
            _realARSessionManager.overlayService.clearOverlays();
          }
        });
        break;
      case '/stories':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoriesPage(memorialId: memorialId),
          ),
        ).then((_) {
          // When returning from the content page, keep the AR overlay visible
          if (_realARSessionManager.sessionState != RealARSessionState.active) {
            _realARSessionManager.overlayService.clearOverlays();
          }
        });
        break;
      case '/memorial-details':
        Navigator.pushNamed(context, '/memorial-details', arguments: arguments).then((_) {
          // When returning from the content page, keep the AR overlay visible
          if (_realARSessionManager.sessionState != RealARSessionState.active) {
            _realARSessionManager.overlayService.clearOverlays();
          }
        });
        break;
      case '/close':
        // Only clear overlays when explicitly closing
        _realARSessionManager.overlayService.clearOverlays();
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
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _showARSettings,
            tooltip: 'AR Settings',
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

    // Use MobileScanner for QR scanning
    return MobileScanner(
      onDetect: _handleRealQRScan,
      controller: MobileScannerController(),
    );
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


} 