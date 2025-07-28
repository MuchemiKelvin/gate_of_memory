import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'dart:ui';

class LocationDebugScreen extends StatefulWidget {
  @override
  _LocationDebugScreenState createState() => _LocationDebugScreenState();
}

class _LocationDebugScreenState extends State<LocationDebugScreen> {
  bool _isLoading = true;
  LocationResult? _result;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Starting location check...\n';
    });

    try {
      // Get device locale info
      final locale = window.locale;
      _debugInfo += '🌍 Device Locale:\n';
      _debugInfo += '   Language: ${locale.languageCode}\n';
      _debugInfo += '   Country: ${locale.countryCode}\n';
      _debugInfo += '   Script: ${locale.scriptCode}\n';
      _debugInfo += '   Full: ${locale.toString()}\n\n';

      // Check location access
      final result = await LocationService.checkLocationAccess();
      
      _debugInfo += '🎯 Location Check Result:\n';
      _debugInfo += '   Allowed: ${result.isAllowed}\n';
      _debugInfo += '   Country: ${result.country ?? 'null'}\n';
      _debugInfo += '   City: ${result.city ?? 'null'}\n';
      _debugInfo += '   Error: ${result.error?.message ?? 'none'}\n\n';
      
      _debugInfo += '📋 Detection Methods:\n';
      for (String method in result.detectionMethods) {
        _debugInfo += '   • $method\n';
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _debugInfo += '💥 Error: $e\n';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Debug'),
        backgroundColor: Color(0xFF7bb6e7),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkLocation,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFeaf3fa),
              Color(0xFFc7e0f5),
              Color(0xFF7bb6e7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7bb6e7)))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _result?.isAllowed == true ? Icons.check_circle : Icons.cancel,
                                  color: _result?.isAllowed == true ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Access Status',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2d3a4a),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _result?.isAllowed == true 
                                  ? '✅ Access Granted - You are in Kenya'
                                  : '❌ Access Denied - Location not in Kenya',
                              style: TextStyle(
                                fontSize: 16,
                                color: _result?.isAllowed == true ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Location Details Card
                    if (_result != null) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2d3a4a),
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildDetailRow('Country', _result!.country ?? 'Unknown'),
                              _buildDetailRow('City', _result!.city ?? 'Unknown'),
                              if (_result!.error != null)
                                _buildDetailRow('Error', _result!.error!.message, isError: true),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                    ],
                    
                    // Debug Information Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bug_report, color: Color(0xFF7bb6e7)),
                                SizedBox(width: 8),
                                Text(
                                  'Debug Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2d3a4a),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFf8f9fa),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color(0xFFe9ecef)),
                              ),
                              child: SelectableText(
                                _debugInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF2d3a4a),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _checkLocation,
                            icon: Icon(Icons.refresh),
                            label: Text('Refresh Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7bb6e7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/location-settings'),
                            icon: Icon(Icons.settings),
                            label: Text('Location Settings'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF7bb6e7),
                              side: BorderSide(color: Color(0xFF7bb6e7)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4a5a6a),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isError ? Colors.red : Color(0xFF2d3a4a),
                fontWeight: isError ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 