import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initializeDatabase() async {
  // Initialize SQLite FFI for desktop platforms
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
} 