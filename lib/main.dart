import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/gate_screen.dart';
import 'screens/museum_screen.dart';
import 'screens/location_settings_screen.dart';
import 'screens/location_debug_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'screens/geo_blocker.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gate of Memory',
      initialRoute: '/',
      builder: (context, child) => GeoBlocker(child: child ?? Container()),
      routes: {
        '/': (context) => StartScreen(),
        '/museum': (context) => MuseumScreen(imageAssets: [
          'assets/images/memorial_card.jpeg',
        ]),
        '/location-settings': (context) => LocationSettingsScreen(),
        '/location-debug': (context) => LocationDebugScreen(),
        // ...other routes...
      },
    ),
  );
}
