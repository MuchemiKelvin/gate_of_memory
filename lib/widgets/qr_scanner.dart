import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanner extends StatefulWidget {
  final void Function(String code) onDetect;

  const QrScanner({Key? key, required this.onDetect}) : super(key: key);

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  bool _flashOn = false;
  bool _hasDetected = false;
  final MobileScannerController _controller = MobileScannerController();

  void _toggleFlash() async {
    await _controller.toggleTorch();
    final enabled = await _controller.torchEnabled;
    setState(() {
      _flashOn = enabled;
    });
  }

  void _resetScanner() {
    setState(() {
      _hasDetected = false;
    });
    _controller.start();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 320,
          height: 420,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_hasDetected) return; // Prevent multiple detections
                
                print('Detected: ${capture.barcodes}');
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    setState(() {
                      _hasDetected = true;
                    });
                    
                    // Stop scanning temporarily
                    _controller.stop();
                    
                    // Call the detection callback
                    widget.onDetect(code);
                  }
                }
              },
            ),
          ),
        ),
        // Scan area overlay
        Positioned(
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasDetected ? Colors.green : Colors.white, 
                  width: 3
                ),
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Flashlight toggle
        Positioned(
          bottom: 24,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.yellowAccent),
            label: Text(_flashOn ? 'Flashlight On' : 'Flashlight Off'),
            onPressed: _toggleFlash,
          ),
        ),
        // Reset scanner button (shown after detection)
        if (_hasDetected)
          Positioned(
            top: 24,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: Icon(Icons.refresh, size: 20),
              label: Text('Scan Again'),
              onPressed: _resetScanner,
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 