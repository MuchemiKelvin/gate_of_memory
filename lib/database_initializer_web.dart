import 'package:flutter/foundation.dart';

Future<void> initializeDatabase() async {
  // For web platform, we'll implement a different database solution
  // The main app will handle web storage initialization separately
  print('Web platform detected - using web storage service instead of SQLite');
} 