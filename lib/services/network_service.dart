/// Network Service for monitoring connectivity and network state
/// 
/// This service monitors online/offline status, manages network state,
/// and provides connectivity information throughout the app.
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';

class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();
  
  NetworkService._();
  
  // Stream controllers
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final StreamController<NetworkStatus> _networkStatusController = StreamController<NetworkStatus>.broadcast();
  
  // Current state
  bool _isOnline = true;
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Network quality metrics
  final List<NetworkQualityMetric> _qualityMetrics = [];
  static const int _maxMetrics = 100;
  
  /// Initialize network monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final initialResult = await Connectivity().checkConnectivity();
      _updateConnectivityStatus(initialResult);
      
      // Listen to connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        _updateConnectivityStatus,
        onError: (error) {
          ApiConfig.logApiError('Network connectivity listener', error);
        },
      );
      
      ApiConfig.logApiCall('Network service initialized', data: {
        'initial_status': _currentStatus.toString(),
        'is_online': _isOnline,
      });
    } catch (e) {
      ApiConfig.logApiError('Initialize network service', e);
    }
  }
  
  /// Get current online status
  bool get isOnline => _isOnline;
  
  /// Get current network status
  NetworkStatus get currentStatus => _currentStatus;
  
  /// Get connectivity stream
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Get network status stream
  Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;
  
  /// Check if currently online
  Future<bool> checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final isConnected = result != ConnectivityResult.none;
      
      // Update internal state
      _isOnline = isConnected;
      _updateConnectivityStatus(result);
      
      return isConnected;
    } catch (e) {
      ApiConfig.logApiError('Check connectivity', e);
      return false;
    }
  }
  
  /// Test network quality
  Future<NetworkQualityMetric> testNetworkQuality() async {
    final startTime = DateTime.now();
    
    try {
      // Test API endpoint response time
      final response = await Future.any([
        _testApiEndpoint(),
        Future.delayed(const Duration(seconds: 10)).then((_) => throw TimeoutException('API timeout')),
      ]);
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      final metric = NetworkQualityMetric(
        timestamp: startTime,
        responseTime: responseTime,
        isSuccessful: response != null,
        networkType: _currentStatus,
      );
      
      _addQualityMetric(metric);
      
      ApiConfig.logApiCall('Network quality test', data: {
        'response_time_ms': responseTime,
        'is_successful': response != null,
        'network_type': _currentStatus.toString(),
      });
      
      return metric;
    } catch (e) {
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      final metric = NetworkQualityMetric(
        timestamp: startTime,
        responseTime: responseTime,
        isSuccessful: false,
        networkType: _currentStatus,
        error: e.toString(),
      );
      
      _addQualityMetric(metric);
      
      ApiConfig.logApiError('Network quality test failed', e);
      return metric;
    }
  }
  
  /// Get network quality statistics
  NetworkQualityStats getNetworkQualityStats() {
    if (_qualityMetrics.isEmpty) {
      return NetworkQualityStats.empty();
    }
    
    final successfulMetrics = _qualityMetrics.where((m) => m.isSuccessful).toList();
    final failedMetrics = _qualityMetrics.where((m) => !m.isSuccessful).toList();
    
    double averageResponseTime = 0;
    if (successfulMetrics.isNotEmpty) {
      final totalTime = successfulMetrics.fold<int>(0, (sum, m) => sum + m.responseTime);
      averageResponseTime = totalTime / successfulMetrics.length;
    }
    
    final successRate = _qualityMetrics.length > 0 
        ? (successfulMetrics.length / _qualityMetrics.length) * 100 
        : 0.0;
    
    return NetworkQualityStats(
      totalTests: _qualityMetrics.length,
      successfulTests: successfulMetrics.length,
      failedTests: failedMetrics.length,
      successRate: successRate,
      averageResponseTime: averageResponseTime,
      lastTestTime: _qualityMetrics.last.timestamp,
      networkType: _currentStatus,
    );
  }
  
  /// Get network type description
  String getNetworkTypeDescription() {
    switch (_currentStatus) {
      case NetworkStatus.wifi:
        return 'WiFi';
      case NetworkStatus.mobile:
        return 'Mobile Data';
      case NetworkStatus.ethernet:
        return 'Ethernet';
      case NetworkStatus.vpn:
        return 'VPN';
      case NetworkStatus.bluetooth:
        return 'Bluetooth';
      case NetworkStatus.other:
        return 'Other';
      case NetworkStatus.none:
        return 'No Connection';
      case NetworkStatus.unknown:
      default:
        return 'Unknown';
    }
  }
  
  /// Check if network is stable (good quality)
  bool get isNetworkStable {
    if (_qualityMetrics.length < 5) return true; // Not enough data
    
    final recentMetrics = _qualityMetrics.takeLast(5);
    final successRate = recentMetrics.where((m) => m.isSuccessful).length / recentMetrics.length;
    
    return successRate >= 0.8; // 80% success rate
  }
  
  /// Get network health status
  NetworkHealthStatus getNetworkHealthStatus() {
    if (!_isOnline) {
      return NetworkHealthStatus.offline;
    }
    
    if (!isNetworkStable) {
      return NetworkHealthStatus.unstable;
    }
    
    final stats = getNetworkQualityStats();
    if (stats.averageResponseTime > 5000) { // 5 seconds
      return NetworkHealthStatus.slow;
    }
    
    return NetworkHealthStatus.healthy;
  }
  
  /// Get network health description
  String getNetworkHealthDescription() {
    switch (getNetworkHealthStatus()) {
      case NetworkHealthStatus.healthy:
        return 'Network is healthy and stable';
      case NetworkHealthStatus.slow:
        return 'Network is slow but functional';
      case NetworkHealthStatus.unstable:
        return 'Network is unstable with frequent failures';
      case NetworkHealthStatus.offline:
        return 'No network connection available';
    }
  }
  
  /// Update connectivity status
  void _updateConnectivityStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    final oldStatus = _currentStatus;
    
    // Update status
    switch (result) {
      case ConnectivityResult.wifi:
        _currentStatus = NetworkStatus.wifi;
        _isOnline = true;
        break;
      case ConnectivityResult.mobile:
        _currentStatus = NetworkStatus.mobile;
        _isOnline = true;
        break;
      case ConnectivityResult.ethernet:
        _currentStatus = NetworkStatus.ethernet;
        _isOnline = true;
        break;
      case ConnectivityResult.vpn:
        _currentStatus = NetworkStatus.vpn;
        _isOnline = true;
        break;
      case ConnectivityResult.bluetooth:
        _currentStatus = NetworkStatus.bluetooth;
        _isOnline = true;
        break;
      case ConnectivityResult.other:
        _currentStatus = NetworkStatus.other;
        _isOnline = true;
        break;
      case ConnectivityResult.none:
        _currentStatus = NetworkStatus.none;
        _isOnline = false;
        break;
    }
    
    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
      
      ApiConfig.logApiCall('Network status changed', data: {
        'was_online': wasOnline,
        'is_online': _isOnline,
        'new_status': _currentStatus.toString(),
      });
    }
    
    if (oldStatus != _currentStatus) {
      _networkStatusController.add(_currentStatus);
    }
  }
  
  /// Test API endpoint
  Future<bool?> _testApiEndpoint() async {
    try {
      // Simple connectivity test to API health endpoint
      final response = await Future.any([
        _testEndpoint('${ApiConfig.baseUrl}/health'),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Health check timeout')),
      ]);
      
      return response;
    } catch (e) {
      return null;
    }
  }
  
  /// Test specific endpoint
  Future<bool> _testEndpoint(String url) async {
    try {
      // This would be a simple HTTP request in a real implementation
      // For now, we'll simulate it
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Add quality metric
  void _addQualityMetric(NetworkQualityMetric metric) {
    _qualityMetrics.add(metric);
    
    // Keep only recent metrics
    if (_qualityMetrics.length > _maxMetrics) {
      _qualityMetrics.removeAt(0);
    }
  }
  
  /// Clear quality metrics
  void clearQualityMetrics() {
    _qualityMetrics.clear();
    ApiConfig.logApiCall('Network quality metrics cleared');
  }
  
  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _networkStatusController.close();
  }
}

/// Network status enum
enum NetworkStatus {
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  other,
  none,
  unknown,
}

/// Network health status enum
enum NetworkHealthStatus {
  healthy,
  slow,
  unstable,
  offline,
}

/// Network quality metric
class NetworkQualityMetric {
  final DateTime timestamp;
  final int responseTime; // milliseconds
  final bool isSuccessful;
  final NetworkStatus networkType;
  final String? error;
  
  NetworkQualityMetric({
    required this.timestamp,
    required this.responseTime,
    required this.isSuccessful,
    required this.networkType,
    this.error,
  });
  
  /// Get response time description
  String get responseTimeDescription {
    if (responseTime < 100) return 'Excellent (< 100ms)';
    if (responseTime < 500) return 'Good (100-500ms)';
    if (responseTime < 2000) return 'Fair (500ms-2s)';
    if (responseTime < 5000) return 'Slow (2-5s)';
    return 'Very Slow (> 5s)';
  }
  
  /// Get quality score (0-100)
  int get qualityScore {
    if (!isSuccessful) return 0;
    if (responseTime < 100) return 100;
    if (responseTime < 500) return 90;
    if (responseTime < 2000) return 70;
    if (responseTime < 5000) return 50;
    return 30;
  }
}

/// Network quality statistics
class NetworkQualityStats {
  final int totalTests;
  final int successfulTests;
  final int failedTests;
  final double successRate;
  final double averageResponseTime;
  final DateTime? lastTestTime;
  final NetworkStatus networkType;
  
  NetworkQualityStats({
    required this.totalTests,
    required this.successfulTests,
    required this.failedTests,
    required this.successRate,
    required this.averageResponseTime,
    this.lastTestTime,
    required this.networkType,
  });
  
  /// Create empty stats
  factory NetworkQualityStats.empty() {
    return NetworkQualityStats(
      totalTests: 0,
      successfulTests: 0,
      failedTests: 0,
      successRate: 0.0,
      averageResponseTime: 0.0,
      networkType: NetworkStatus.unknown,
    );
  }
  
  /// Get formatted average response time
  String get formattedAverageResponseTime {
    if (averageResponseTime < 1000) {
      return '${averageResponseTime.toStringAsFixed(0)}ms';
    } else {
      return '${(averageResponseTime / 1000).toStringAsFixed(1)}s';
    }
  }
  
  /// Get time since last test
  String get timeSinceLastTest {
    if (lastTestTime == null) return 'Never';
    
    final timeDiff = DateTime.now().difference(lastTestTime!);
    if (timeDiff.inDays > 0) {
      return '${timeDiff.inDays}d ago';
    } else if (timeDiff.inHours > 0) {
      return '${timeDiff.inHours}h ago';
    } else if (timeDiff.inMinutes > 0) {
      return '${timeDiff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 