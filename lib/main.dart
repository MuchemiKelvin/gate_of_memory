import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/museum_screen.dart';
import 'screens/memorial_dashboard_screen.dart';
import 'screens/location_settings_screen.dart';
import 'screens/location_debug_screen.dart';
import 'screens/ar_camera_screen.dart';
import 'screens/memorial_details_page.dart';
import 'screens/geo_blocker.dart';
import 'services/database_init_service.dart';
import 'database_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('=== STARTING DATABASE INITIALIZATION ===');
    
    // Step 1: Initialize platform-specific database factory
    print('Step 1: Initializing platform-specific database factory...');
    await initializeDatabase();
    print('✓ Platform-specific database factory initialization completed');
    
    // Step 2: Initialize database system and seed data
    print('Step 2: Initializing database system...');
    final dbInitService = DatabaseInitService();
    await dbInitService.initializeDatabase();
    print('✓ Database system initialized and seeded');
    
    // Step 3: Test database functionality
    print('Step 3: Testing database functionality...');
    final stats = await dbInitService.getDatabaseStatistics();
    print('✓ Database statistics: $stats');
    
    print('=== DATABASE INITIALIZATION COMPLETED SUCCESSFULLY ===');
  } catch (e, stackTrace) {
    print('❌ CRITICAL ERROR during database initialization: $e');
    print('Stack trace: $stackTrace');
    
    // Show error dialog or fallback behavior
    print('Continuing with app launch despite database error...');
  }

  // Start the app with GeoBlocker for location verification
  runApp(
    GeoBlocker(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kardiverse Mobile',
        initialRoute: '/',
        routes: {
          '/': (context) => StartScreen(),
          '/museum': (context) => MuseumScreen(imageAssets: [
            'assets/images/memorial_card.jpeg',
          ]),
          '/dashboard': (context) => const MemorialDashboardScreen(),
          '/location-settings': (context) => LocationSettingsScreen(),
          '/location-debug': (context) => LocationDebugScreen(),
          '/ar-camera': (context) => ARCameraScreen(),
          '/memorial-details': (context) => MemorialDetailsPage(),
        },
      ),
    ),
  );
}


