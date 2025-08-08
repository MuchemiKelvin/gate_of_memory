import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'memorial_service.dart';
import '../models/memorial.dart';
import 'dart:async';

enum QRScanStatus {
  idle,
  scanning,
  success,
  error,
  invalid,
  notFound,
}

class QRCodeService {
  static final QRCodeService _instance = QRCodeService._internal();
  factory QRCodeService() => _instance;
  QRCodeService._internal();

  final MemorialService _memorialService = MemorialService();
  final StreamController<QRScanStatus> _statusController = StreamController<QRScanStatus>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<Memorial> _memorialController = StreamController<Memorial>.broadcast();

  QRScanStatus _currentStatus = QRScanStatus.idle;
  String? _lastError;
  Memorial? _lastScannedMemorial;

  // Getters
  Stream<QRScanStatus> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Memorial> get memorialStream => _memorialController.stream;
  QRScanStatus get currentStatus => _currentStatus;
  String? get lastError => _lastError;
  Memorial? get lastScannedMemorial => _lastScannedMemorial;

  /// Validate QR code against database
  Future<Memorial?> validateQRCode(String qrCode) async {
    try {
      _updateStatus(QRScanStatus.scanning);
      
      // Check if QR code is empty or null
      if (qrCode.isEmpty) {
        _handleError('QR code is empty or invalid');
        return null;
      }

      // Validate QR code format (basic check)
      if (!_isValidQRFormat(qrCode)) {
        _handleError('Invalid QR code format');
        return null;
      }

      // Check if QR code exists in database
      final memorial = await _memorialService.getMemorialByQRCode(qrCode);
      
      if (memorial == null) {
        _updateStatus(QRScanStatus.notFound);
        _handleError('QR code not found in database: $qrCode');
        return null;
      }

      // Success - memorial found
      _lastScannedMemorial = memorial;
      _updateStatus(QRScanStatus.success);
      _memorialController.add(memorial);
      
      print('QR Code validated successfully: ${memorial.name} (${memorial.qrCode})');
      return memorial;

    } catch (e) {
      _handleError('Database error: $e');
      return null;
    }
  }

  /// Check if QR code format is valid
  bool _isValidQRFormat(String qrCode) {
    // Basic validation - QR code should not be empty and should contain valid characters
    if (qrCode.isEmpty) return false;
    
    // Check for basic format (should contain letters, numbers, and hyphens)
    final validPattern = RegExp(r'^[A-Z0-9\-]+$');
    return validPattern.hasMatch(qrCode);
  }

  /// Handle QR code scanning from mobile scanner
  void handleQRScan(BarcodeCapture capture) {
    try {
      final List<Barcode> barcodes = capture.barcodes;
      
      if (barcodes.isEmpty) {
        _handleError('No QR code detected');
        return;
      }

      for (final barcode in barcodes) {
        final qrCode = barcode.rawValue;
        
        if (qrCode != null && qrCode.isNotEmpty) {
          print('QR Code detected: $qrCode');
          validateQRCode(qrCode);
          return; // Process only the first valid QR code
        }
      }

      _handleError('Invalid QR code format');

    } catch (e) {
      _handleError('QR scanning error: $e');
    }
  }

  /// Handle database connection errors
  Future<void> handleDatabaseError() async {
    try {
      // Test database connection
      final memorials = await _memorialService.getAllMemorials();
      if (memorials.isEmpty) {
        _handleError('Database is empty or not accessible');
      }
    } catch (e) {
      _handleError('Database connection failed: $e');
    }
  }

  /// Handle camera permission errors
  void handleCameraError(String error) {
    _handleError('Camera error: $error');
  }

  /// Get all available QR codes from database for testing
  Future<List<Map<String, dynamic>>> getAvailableQRCodes() async {
    try {
      final memorials = await _memorialService.getAllMemorials();
      return memorials.map((memorial) => {
        'qrCode': memorial.qrCode,
        'name': memorial.name,
        'description': memorial.description,
        'id': memorial.id,
      }).toList();
    } catch (e) {
      print('Error getting available QR codes: $e');
      return [];
    }
  }

  /// Test QR code validation (for development/testing)
  Future<void> testQRCode(String qrCode) async {
    print('Testing QR code: $qrCode');
    await validateQRCode(qrCode);
  }

  /// Update scan status
  void _updateStatus(QRScanStatus status) {
    _currentStatus = status;
    _statusController.add(status);
    print('QR Scan Status: $status');
  }

  /// Handle errors
  void _handleError(String error) {
    _lastError = error;
    _updateStatus(QRScanStatus.error);
    _errorController.add(error);
    print('QR Error: $error');
  }

  /// Reset service state
  void reset() {
    _currentStatus = QRScanStatus.idle;
    _lastError = null;
    _lastScannedMemorial = null;
    _updateStatus(QRScanStatus.idle);
  }

  /// Get error message for display
  String getErrorMessage() {
    switch (_currentStatus) {
      case QRScanStatus.error:
        return _lastError ?? 'Unknown error occurred';
      case QRScanStatus.invalid:
        return 'Invalid QR code format';
      case QRScanStatus.notFound:
        return 'QR code not found in database';
      case QRScanStatus.scanning:
        return 'Scanning QR code...';
      case QRScanStatus.success:
        return 'QR code validated successfully';
      case QRScanStatus.idle:
        return 'Ready to scan';
    }
  }

  /// Dispose service
  void dispose() {
    _statusController.close();
    _errorController.close();
    _memorialController.close();
  }
} 