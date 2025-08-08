import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Test Screen'),
        backgroundColor: Color(0xFF2d3a4a),
        foregroundColor: Colors.white,
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Memorial QR Codes for Testing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3a4a),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Point your AR Camera at any of these QR codes to test detection',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4a5a6a),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              
              // Naomi Memorial QR Code
              _buildQRCodeCard(
                'NAOMI-N-MEMORIAL-001',
                'Naomi N. Memorial',
                'assets/images/naomi_memorial.jpeg',
                Colors.blue,
              ),
              SizedBox(height: 20),
              
              // John Memorial QR Code
              _buildQRCodeCard(
                'JOHN-M-MEMORIAL-002',
                'John M. Memorial',
                'assets/images/john_memorial.jpeg',
                Colors.green,
              ),
              SizedBox(height: 20),
              
              // Sarah Memorial QR Code
              _buildQRCodeCard(
                'SARAH-K-MEMORIAL-003',
                'Sarah K. Memorial',
                'assets/images/sarah_memorial.jpeg',
                Colors.purple,
              ),
              SizedBox(height: 30),
              
              // Instructions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF2d3a4a),
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Testing Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3a4a),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Open AR Camera from main screen\n'
                      '2. Point camera at any QR code above\n'
                      '3. Hold steady for 2-3 seconds\n'
                      '4. Check AR Settings for detection status\n'
                      '5. Memorial content should load automatically',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4a5a6a),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeCard(String qrData, String title, String imagePath, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: QrImageView(
              data: qrData,
              size: 150,
              backgroundColor: Colors.white,
              foregroundColor: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'QR Code: $qrData',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF4a5a6a),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
} 