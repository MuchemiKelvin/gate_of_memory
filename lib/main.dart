import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/gate_screen.dart';
import 'screens/museum_screen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Gate of Memory',
    initialRoute: '/',
    routes: {
      '/': (context) => StartScreen(),
      '/museum': (context) => MuseumScreen(imageAssets: [
        'assets/images/memorial_card.jpeg',
        // Add more image asset paths here if available
      ]),
    },
  ));
}
