import 'package:flutter/material.dart';
import '../widgets/qr_scanner.dart';
import '../services/qr_code_service.dart';
import '../models/memorial.dart';
import 'images_page.dart';
import 'videos_page.dart';
import 'audio_page.dart';
import 'stories_page.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final QRCodeService _qrCodeService = QRCodeService();
  Memorial? _scannedMemorial;
  bool _isProcessing = false;
  String _statusMessage = 'Align the QR code or barcode within the frame to scan.';

  @override
  void initState() {
    super.initState();
    _setupQRServiceListeners();
  }

  void _setupQRServiceListeners() {
    // Listen to QR scan status changes
    _qrCodeService.statusStream.listen((status) {
      setState(() {
        switch (status) {
          case QRScanStatus.scanning:
            _statusMessage = 'Scanning QR code...';
            _isProcessing = true;
            break;
          case QRScanStatus.success:
            _statusMessage = 'QR code validated successfully!';
            _isProcessing = false;
            break;
          case QRScanStatus.error:
            _statusMessage = _qrCodeService.getErrorMessage();
            _isProcessing = false;
            break;
          case QRScanStatus.notFound:
            _statusMessage = 'QR code not found in database';
            _isProcessing = false;
            break;
          case QRScanStatus.invalid:
            _statusMessage = 'Invalid QR code format';
            _isProcessing = false;
            break;
          default:
            _statusMessage = 'Align the QR code or barcode within the frame to scan.';
            _isProcessing = false;
        }
      });
    });

    // Listen to memorial data when QR code is validated
    _qrCodeService.memorialStream.listen((memorial) {
      setState(() {
        _scannedMemorial = memorial;
        _statusMessage = 'Found: ${memorial.name}';
      });
    });

    // Listen to error messages
    _qrCodeService.errorStream.listen((error) {
      setState(() {
        _statusMessage = error;
        _isProcessing = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  void _showSuccessAndNavigate(Memorial memorial) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Found: ${memorial.name}')),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to content after a short delay
    Future.delayed(Duration(milliseconds: 800), () {
      _navigateToContent(memorial);
    });
  }

  void _navigateToContent(Memorial memorial) {
    // Show content selection dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${memorial.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What would you like to view?'),
              SizedBox(height: 16),
              if (memorial.hasImage)
                ListTile(
                  leading: Icon(Icons.photo_library, color: Color(0xFF7bb6e7)),
                  title: Text('Images'),
                  subtitle: Text('View memorial photos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImagesPage(memorialId: memorial.id.toString()),
                      ),
                    );
                  },
                ),
              if (memorial.hasVideo)
                ListTile(
                  leading: Icon(Icons.video_library, color: Color(0xFF7bb6e7)),
                  title: Text('Videos'),
                  subtitle: Text('Watch memorial videos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideosPage(memorialId: memorial.id.toString()),
                      ),
                    );
                  },
                ),
              if (memorial.hasAudio)
                ListTile(
                  leading: Icon(Icons.audiotrack, color: Color(0xFF7bb6e7)),
                  title: Text('Audio'),
                  subtitle: Text('Listen to memorial audio'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AudioPage(memorialId: memorial.id.toString()),
                      ),
                    );
                  },
                ),
              if (memorial.hasStories)
                ListTile(
                  leading: Icon(Icons.book, color: Color(0xFF7bb6e7)),
                  title: Text('Stories'),
                  subtitle: Text('Read memorial stories'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoriesPage(memorialId: memorial.id.toString()),
                      ),
                    );
                  },
                ),
              if (!memorial.hasImage && !memorial.hasVideo && !memorial.hasAudio && !memorial.hasStories)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No content available for this memorial yet.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _onQRDetected(String code) {
    if (!_isProcessing) {
      print('QR Code detected: $code');
      _qrCodeService.validateQRCode(code);
    }
  }

  void _resetScan() {
    setState(() {
      _scannedMemorial = null;
      _isProcessing = false;
      _statusMessage = 'Align the QR code or barcode within the frame to scan.';
    });
    _qrCodeService.reset();
  }

  Widget _buildMemorialInfoCard(Memorial memorial) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and category
          Row(
            children: [
              Icon(
                Icons.person,
                color: Color(0xFF7bb6e7),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memorial.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      memorial.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7bb6e7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Description
          if (memorial.description.isNotEmpty) ...[
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              memorial.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
          ],
          
          // Content availability
          Text(
            'Available Content',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (memorial.hasImage)
                _buildContentChip('Images', Icons.photo_library, Colors.green),
              if (memorial.hasVideo)
                _buildContentChip('Videos', Icons.video_library, Colors.blue),
              if (memorial.hasAudio)
                _buildContentChip('Audio', Icons.audiotrack, Colors.orange),
              if (memorial.hasStories)
                _buildContentChip('Stories', Icons.book, Colors.purple),
              if (!memorial.hasImage && !memorial.hasVideo && !memorial.hasAudio && !memorial.hasStories)
                _buildContentChip('No Content', Icons.info_outline, Colors.grey),
            ],
          ),
          SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToContent(memorial),
                  icon: Icon(Icons.visibility),
                  label: Text('View Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7bb6e7),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetScan,
                  icon: Icon(Icons.refresh),
                  label: Text('Scan Another'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF7bb6e7),
                    side: BorderSide(color: Color(0xFF7bb6e7)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan a Kardiverse QR Code'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 4,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFeaf3fa),
              Color(0xFFfafdff),
              Color(0xFFdbeaf7),
              Color(0xFFc7e0f5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Status message
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: EdgeInsets.only(top: 16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isProcessing)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7bb6e7)),
                        ),
                      ),
                    if (_isProcessing) SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _isProcessing ? Color(0xFF7bb6e7) : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // QR Scanner or Memorial Info
            Expanded(
              child: Center(
                child: _scannedMemorial != null
                    ? _buildMemorialInfoCard(_scannedMemorial!)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Align the QR code or barcode within the frame to scan.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          QrScanner(
                            onDetect: _onQRDetected,
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

  @override
  void dispose() {
    _qrCodeService.dispose();
    super.dispose();
  }
} 