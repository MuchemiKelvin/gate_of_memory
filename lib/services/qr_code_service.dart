import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'memorial_service.dart';
import '../models/memorial.dart';
import 'dart:async';
import 'sync_service.dart';
import 'template_service.dart';

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
  final SyncService _syncService = SyncService.instance;
  final TemplateService _templateService = TemplateService.instance;
  
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

  /// Validate QR code against database and trigger sync
  Future<Memorial?> validateQRCode(String qrCode) async {
    print('=== QR CODE VALIDATION DEBUG ===');
    print('Scanned QR Code: "$qrCode"');
    
    try {
      _updateStatus(QRScanStatus.scanning);
      
      // Check if QR code is empty or null
      if (qrCode.isEmpty) {
        print('❌ QR code is empty or invalid');
        _handleError('QR code is empty or invalid');
        return null;
      }

      // Validate QR code format (basic check)
      if (!_isValidQRFormat(qrCode)) {
        print('❌ Invalid QR code format: $qrCode');
        _handleError('Invalid QR code format');
        return null;
      }

      print('✓ QR code format is valid, checking database...');
      
      // Check if QR code exists in database
      final memorial = await _memorialService.getMemorialByQRCode(qrCode);
      
      if (memorial == null) {
        print('❌ QR code not found in database: $qrCode');
        _updateStatus(QRScanStatus.notFound);
        _handleError('QR code not found in database: $qrCode');
        return null;
      }

      print('✓ Memorial found in database:');
      print('  - ID: ${memorial.id}');
      print('  - Name: ${memorial.name}');
      print('  - QR Code: ${memorial.qrCode}');
      print('  - Has Image: ${memorial.hasImage}');
      print('  - Has Video: ${memorial.hasVideo}');
      print('  - Has Audio: ${memorial.hasAudio}');
      print('  - Has Stories: ${memorial.hasStories}');

      // Success - memorial found, now trigger sync
      _lastScannedMemorial = memorial;
      _updateStatus(QRScanStatus.success);
      _memorialController.add(memorial);
      
      print('✓ QR Code validated successfully: ${memorial.name} (${memorial.qrCode})');
      
      // 🔄 NEW: Automatically trigger sync after successful QR validation
      await _triggerSyncAfterQRValidation(memorial);
      
      return memorial;

    } catch (e) {
      print('❌ Database error during QR validation: $e');
      _handleError('Database error: $e');
      return null;
    }
    
    print('=== END QR CODE VALIDATION DEBUG ===');
  }

  /// Trigger sync operations after QR validation
  Future<void> _triggerSyncAfterQRValidation(Memorial memorial) async {
    try {
      print('Triggering sync after QR validation for memorial: ${memorial.name}');
      
      // Step 1: Check if we need to sync templates
      final needsSync = await _checkIfSyncNeeded(memorial);
      if (needsSync) {
        print('Sync needed, starting template synchronization...');
        
        // Step 2: Start template sync
        final syncSuccess = await _syncService.syncTemplates();
        if (syncSuccess) {
          print('Template sync completed successfully');
          
          // Step 3: Download specific memorial template if available
          await _downloadMemorialTemplate(memorial);
        } else {
          print('Template sync failed, but memorial is still accessible');
        }
      } else {
        print('No sync needed, memorial content is up to date');
      }
      
    } catch (e) {
      print('Error during sync trigger: $e');
      // Don't fail the QR validation if sync fails
      // Memorial is still accessible from local database
    }
  }

  /// Check if sync is needed for this memorial
  Future<bool> _checkIfSyncNeeded(Memorial memorial) async {
    try {
      // Check if we have recent sync data
      final lastSync = _syncService.lastSyncAttempt;
      if (lastSync == null) {
        print('No previous sync found, sync needed');
        return true;
      }
      
      // Check if sync is older than 1 hour
      final timeSinceLastSync = DateTime.now().difference(lastSync);
      if (timeSinceLastSync.inHours > 1) {
        print('Last sync was ${timeSinceLastSync.inHours} hours ago, sync needed');
        return true;
      }
      
      // Check if memorial content needs updating
      final hasRecentContent = await _checkMemorialContentFreshness(memorial);
      if (!hasRecentContent) {
        print('Memorial content is stale, sync needed');
        return true;
      }
      
      print('Memorial content is fresh, no sync needed');
      return false;
      
    } catch (e) {
      print('Error checking sync need: $e, defaulting to sync needed');
      return true; // Default to sync if we can't determine
    }
  }

  /// Check if memorial content is fresh
  Future<bool> _checkMemorialContentFreshness(Memorial memorial) async {
    try {
      // Check if memorial was updated recently (within last 24 hours)
      final memorialAge = DateTime.now().difference(memorial.updatedAt);
      if (memorialAge.inHours > 24) {
        print('Memorial is ${memorialAge.inHours} hours old, sync needed');
        return false;
      }
      
      print('Memorial is fresh (${memorialAge.inHours} hours old)');
      return true;
      
    } catch (e) {
      print('Error checking content freshness: $e');
      return false; // Default to needing sync if we can't determine
    }
  }

  /// Download memorial-specific template
  Future<void> _downloadMemorialTemplate(Memorial memorial) async {
    try {
      print('Checking for templates related to memorial: ${memorial.name}');
      
      // Get templates by category that match this memorial
      final templates = await _templateService.fetchTemplatesByCategory(memorial.category);
      if (templates != null && templates.isNotEmpty) {
        print('Found ${templates.length} templates for category: ${memorial.category}');
        
        // Download the first template as an example
        final template = templates.first;
        final downloadSuccess = await _templateService.downloadTemplate(template.id);
        if (downloadSuccess) {
          print('Template downloaded successfully for ${memorial.name}');
        } else {
          print('Template download failed for ${memorial.name}');
        }
      } else {
        print('No templates found for category: ${memorial.category}');
      }
    } catch (e) {
      print('Error downloading memorial template: $e');
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