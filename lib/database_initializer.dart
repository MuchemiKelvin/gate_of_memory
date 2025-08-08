import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

Future<void> initializeDatabase() async {
  if (Platform.isAndroid || Platform.isIOS) {
    // Use default database factory for mobile platforms
    // No need to initialize FFI on mobile
    return;
  }
  
  // Initialize FFI for desktop platforms only
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
} 