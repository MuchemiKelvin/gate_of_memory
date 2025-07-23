import 'package:flutter/material.dart';
import '../widgets/qr_scanner.dart';

class ScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan a Memorial QR Code'),
      ),
      body: Center(
        child: QrScanner(
          onDetect: (code) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('QR Code: $code')),
            );
            // Optionally, navigate to a memorial page:
            // Navigator.pushNamed(context, '/memorial/$code');
          },
        ),
      ),
    );
  }
} 