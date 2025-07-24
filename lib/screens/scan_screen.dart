import 'package:flutter/material.dart';
import '../widgets/qr_scanner.dart';
import 'gate_screen.dart';

class ScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan a Memorial QR Code'),
        // Use theme color
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Align the QR code or barcode within the frame to scan.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              QrScanner(
                onDetect: (code) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Scan successful!'),
                        ],
                      ),
                      backgroundColor: Colors.green[100],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Future.delayed(Duration(milliseconds: 600), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GateScreen()),
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 