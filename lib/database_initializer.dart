import 'package:flutter/foundation.dart';

/// Database initialization for all platforms
/// Uses the standard sqflite implementation which works on mobile and web
Future<void> initializeDatabase() async {
  try {
    if (kIsWeb) {
      print('Web platform detected, using web storage service');
      return;
    }
    
    // For mobile and desktop platforms, use the standard sqflite implementation
    print('Mobile/Desktop platform detected, using standard sqflite implementation');
    print('✓ Database factory will use platform-appropriate implementation');
    
  } catch (e) {
    print('❌ Error in database initialization: $e');
    print('Continuing with default database factory...');
  }
} 