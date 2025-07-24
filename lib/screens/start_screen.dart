import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'gate_screen.dart';
import 'scan_screen.dart'; // Added import for ScanScreen

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 32),
              Text(
                'Gate Of Memory',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3a4a),
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              QrImageView(
                data: 'GATE-OF-MEMORY-QR',
                size: 180,
                backgroundColor: Colors.white,
              ),
              SizedBox(height: 32),
              // Modern Scan QR/Barcode button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ScanScreen()),
                  );
                },
                icon: Icon(Icons.qr_code_scanner, size: 24),
                label: Text(
                  'Scan QR/Barcode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2d3a4a),
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shadowColor: Color(0xFF2d3a4a).withOpacity(0.3),
                ),
              ),
              SizedBox(height: 16),
              // Existing Scan button for GateScreen
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GateScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7bb6e7),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                  shadowColor: Color(0xFF7bb6e7).withOpacity(0.4),
                ),
                child: Text(
                  'Enter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Enter the digital sanctuary....',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4a5a6a),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 