import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'gate_screen.dart';
import 'scan_screen.dart'; // Added import for ScanScreen
import 'qr_test_screen.dart'; // Added import for QRTestScreen

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              SizedBox(height: 20),
              Text(
                'Kardiverse Mobile',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3a4a),
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              QrImageView(
                data: 'NAOMI-N-MEMORIAL-001',
                size: 180,
                backgroundColor: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Test QR Code: NAOMI-N-MEMORIAL-001',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2d3a4a),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
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
              // Gallery Dashboard button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/dashboard');
                },
                icon: Icon(Icons.photo_library, size: 24),
                label: Text(
                  'Gallery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shadowColor: Color(0xFF4CAF50).withOpacity(0.4),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/ar-camera');
                },
                icon: Icon(Icons.view_in_ar, size: 24),
                label: Text('AR Camera', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2d3a4a),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // QR Test Screen button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QRTestScreen()),
                  );
                },
                icon: Icon(Icons.qr_code, size: 24),
                label: Text('QR Test Codes', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

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
              SizedBox(height: 20),
              Text(
                'Enter the digital sanctuary....',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4a5a6a),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
        ),
      ),
    );
  }
} 