import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';
import 'template_service.dart';
import 'auth_service.dart';
import 'database_init_service.dart';

/// Service to handle app startup operations including automatic sync
class AppStartupService {
  static final AppStartupService _instance = AppStartupService._internal();
  factory AppStartupService() => _instance;
  AppStartupService._internal();

  final SyncService _syncService = SyncService.instance;
  final TemplateService _templateService = TemplateService.instance;
  final AuthService _authService = AuthService.instance;
  final DatabaseInitService _dbInitService = DatabaseInitService();

  bool _isInitialized = false;
  bool _isStartupSyncComplete = false;
  DateTime? _startupTime;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isStartupSyncComplete => _isStartupSyncComplete;
  DateTime? get startupTime => _startupTime;

  /// Initialize the app with startup sync
  Future<void> initializeApp() async {
    try {
      print('Starting app initialization...');
      _startupTime = DateTime.now();

      // Step 1: Initialize database
      print('Step 1: Initializing database...');
      await _dbInitService.initializeDatabase();
      print('Database initialization completed');

      // Step 2: Check connectivity
      print('Step 2: Checking connectivity...');
      final hasConnectivity = await _checkConnectivity();
      print('Connectivity check completed: ${hasConnectivity ? 'Online' : 'Offline'}');

      // Step 3: Initialize sync service
      print('Step 3: Initializing sync service...');
      await _initializeSyncService();
      print('Sync service initialization completed');

      // Step 4: Perform startup sync if online
      if (hasConnectivity) {
        print('Step 4: Performing startup sync...');
        await _performStartupSync();
        print('Startup sync completed');
      } else {
        print('Step 4: Skipping startup sync (offline)');
        _isStartupSyncComplete = true;
      }

      // Step 5: Initialize background sync
      print('Step 5: Initializing background sync...');
      await _initializeBackgroundSync();
      print('Background sync initialization completed');

      _isInitialized = true;
      print('App initialization completed successfully!');
      print('Total initialization time: ${DateTime.now().difference(_startupTime!).inMilliseconds}ms');

    } catch (e) {
      print('Error during app initialization: $e');
      // Continue with app launch even if initialization fails
      _isInitialized = true;
    }
  }

  /// Check if device has internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false; // Default to offline if we can't determine
    }
  }

  /// Initialize sync service
  Future<void> _initializeSyncService() async {
    try {
      // Check if user is authenticated
      if (_authService.isAuthenticated) {
        print('User authenticated, sync service ready');
      } else {
        print('User not authenticated, sync service in limited mode');
      }

      // Initialize sync status
      await _syncService.checkSyncStatus();
      print('Sync status initialized');
      
    } catch (e) {
      print('Error initializing sync service: $e');
    }
  }

  /// Perform startup sync operations
  Future<void> _performStartupSync() async {
    try {
      print('Starting startup sync...');
      
      // Check if we need to sync
      final needsSync = await _checkStartupSyncNeed();
      if (!needsSync) {
        print('No startup sync needed');
        _isStartupSyncComplete = true;
        return;
      }

      // Perform template sync
      print('Syncing templates...');
      final syncSuccess = await _syncService.syncTemplates();
      
      if (syncSuccess) {
        print('Template sync completed successfully');
        
        // Download essential templates
        await _downloadEssentialTemplates();
      } else {
        print('Template sync failed, but app can continue');
      }

      _isStartupSyncComplete = true;
      print('Startup sync completed');
      
    } catch (e) {
      print('Error during startup sync: $e');
      _isStartupSyncComplete = true; // Mark as complete to prevent blocking
    }
  }

  /// Check if startup sync is needed
  Future<bool> _checkStartupSyncNeed() async {
    try {
      // Check if we have recent sync data
      final lastSync = _syncService.lastSyncAttempt;
      if (lastSync == null) {
        print('No previous sync found, startup sync needed');
        return true;
      }

      // Check if sync is older than 6 hours
      final timeSinceLastSync = DateTime.now().difference(lastSync);
      if (timeSinceLastSync.inHours > 6) {
        print('Last sync was ${timeSinceLastSync.inHours} hours ago, startup sync needed');
        return true;
      }

      // Check if we have essential templates
      final hasEssentialTemplates = await _checkEssentialTemplates();
      if (!hasEssentialTemplates) {
        print('Missing essential templates, startup sync needed');
        return true;
      }

      print('No startup sync needed, content is fresh');
      return false;
      
    } catch (e) {
      print('Error checking startup sync need: $e, defaulting to sync needed');
      return true; // Default to sync if we can't determine
    }
  }

  /// Check if essential templates are available
  Future<bool> _checkEssentialTemplates() async {
    try {
      // Check if we have at least some templates
      final templates = await _templateService.fetchTemplates();
      if (templates == null || templates.isEmpty) {
        print('No templates found, sync needed');
        return false;
      }

      // Check if templates are recent
      final hasRecentTemplates = templates.any((template) {
        final templateAge = DateTime.now().difference(template.updatedAt);
        return templateAge.inHours < 24;
      });

      if (!hasRecentTemplates) {
        print('Templates are stale, sync needed');
        return false;
      }

      print('Essential templates are available and fresh');
      return true;
      
    } catch (e) {
      print('Error checking essential templates: $e');
      return false;
    }
  }

  /// Download essential templates
  Future<void> _downloadEssentialTemplates() async {
    try {
      print('Downloading essential templates...');
      
      // Get list of essential templates (e.g., demo memorials)
      final essentialTemplates = await _templateService.getEssentialTemplates();
      
      int downloadCount = 0;
      for (final template in essentialTemplates) {
        try {
          final success = await _templateService.downloadTemplate(template.id);
          if (success) {
            downloadCount++;
            print('Downloaded template: ${template.name}');
          }
        } catch (e) {
          print('Failed to download template ${template.name}: $e');
        }
      }
      
      print('Essential templates download completed: $downloadCount/${essentialTemplates.length}');
      
    } catch (e) {
      print('Error downloading essential templates: $e');
    }
  }

  /// Initialize background sync
  Future<void> _initializeBackgroundSync() async {
    try {
      print('Initializing background sync...');
      
      // Set up periodic sync (every 2 hours)
      Timer.periodic(Duration(hours: 2), (timer) async {
        if (await _checkConnectivity()) {
          print('Background sync triggered...');
          await _performBackgroundSync();
        } else {
          print('Background sync skipped (offline)');
        }
      });
      
      print('Background sync initialized (every 2 hours)');
      
    } catch (e) {
      print('Error initializing background sync: $e');
    }
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    try {
      print('Performing background sync...');
      
      // Check if user is authenticated
      if (!_authService.isAuthenticated) {
        print('User not authenticated, skipping background sync');
        return;
      }

      // Perform template sync
      final syncSuccess = await _syncService.syncTemplates();
      if (syncSuccess) {
        print('Background sync completed successfully');
      } else {
        print('Background sync failed');
      }
      
    } catch (e) {
      print('Error during background sync: $e');
    }
  }

  /// Get startup statistics
  Map<String, dynamic> getStartupStats() {
    return {
      'isInitialized': _isInitialized,
      'isStartupSyncComplete': _isStartupSyncComplete,
      'startupTime': _startupTime?.toIso8601String(),
      'initializationDuration': _startupTime != null 
          ? DateTime.now().difference(_startupTime!).inMilliseconds 
          : null,
    };
  }

  /// Reset startup state (for testing)
  void reset() {
    _isInitialized = false;
    _isStartupSyncComplete = false;
    _startupTime = null;
  }
} 