import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/start_screen.dart';
import 'screens/museum_screen.dart';
import 'screens/memorial_dashboard_screen.dart';
import 'screens/location_settings_screen.dart';
import 'screens/location_debug_screen.dart';
import 'screens/geo_blocker.dart';
import 'screens/ar_camera_screen.dart';
import 'screens/images_page.dart';
import 'screens/videos_page.dart';
import 'screens/audio_page.dart';
import 'screens/stories_page.dart';
import 'screens/memorial_details_page.dart';

import 'services/database_init_service.dart';

// Conditional import for desktop platforms only
import 'database_initializer.dart' if (dart.library.html) 'database_initializer_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database based on platform
  await initializeDatabase();
  
  // Test database initialization
  try {
    print('=== TESTING DATABASE INITIALIZATION ===');
    final dbInitService = DatabaseInitService();
    final stats = await dbInitService.getDatabaseStatistics();
    print('Database statistics: $stats');
    print('=== END DATABASE TEST ===');
  } catch (e) {
    print('Database test error: $e');
  }
  
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kardiverse Mobile',
      initialRoute: '/',
      builder: (context, child) => GeoBlocker(child: child ?? Container()),
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
  );
}
