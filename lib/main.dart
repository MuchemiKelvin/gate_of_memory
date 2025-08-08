import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/start_screen.dart';
import 'screens/museum_screen.dart';
import 'screens/memorial_dashboard_screen.dart';
import 'screens/location_settings_screen.dart';
import 'screens/location_debug_screen.dart';
import 'screens/geo_blocker.dart';
import 'screens/ar_camera_screen.dart';

// Conditional import for desktop platforms only
import 'database_initializer.dart' if (dart.library.html) 'database_initializer_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database based on platform
  await initializeDatabase();
  
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
        // ...other routes...
      },
    ),
  );
}
