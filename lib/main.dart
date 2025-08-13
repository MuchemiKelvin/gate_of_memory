import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/museum_screen.dart';
import 'screens/memorial_dashboard_screen.dart';
import 'screens/memorial_details_page.dart';
import 'screens/ar_camera_screen.dart';
import 'services/database_init_service.dart';
import 'services/app_startup_service.dart';
import 'database_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start the app immediately without waiting for initialization
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kardiverse Mobile',
      initialRoute: '/',
      routes: {
        '/': (context) => StartScreen(),
        '/museum': (context) => MuseumScreen(imageAssets: [
          'assets/images/memorial_card.jpeg',
        ]),
        '/dashboard': (context) => const MemorialDashboardScreen(),
        '/memorial-details': (context) => MemorialDetailsPage(),
        '/ar-camera': (context) => const ARCameraScreen(),
      },
    ),
  );
  
  // Initialize the app in the background after app is launched
  _initializeAppInBackground();
}

Future<void> _initializeAppInBackground() async {
  try {
    print('=== STARTING BACKGROUND APP INITIALIZATION ===');
    
    // Initialize the app with startup sync
    final startupService = AppStartupService();
    await startupService.initializeApp();
    
    // Get startup statistics
    final startupStats = startupService.getStartupStats();
    print('Background Startup Statistics: $startupStats');
    
    print('=== BACKGROUND APP INITIALIZATION COMPLETED SUCCESSFULLY ===');
  } catch (e, stackTrace) {
    print('CRITICAL ERROR during background app initialization: $e');
    print('Stack trace: $stackTrace');
    
    // Don't show error to user since this runs in background
    print('Continuing with app despite background initialization error...');
  }
}


