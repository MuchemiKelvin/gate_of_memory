/// System Health Screen
/// 
/// This screen provides comprehensive monitoring of network status, error tracking,
/// sync status, and overall system health with real-time updates.
import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/error_handling_service.dart';
import '../services/sync_service.dart';
import '../services/template_storage_service.dart';
import '../config/api_config.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NetworkService _networkService = NetworkService.instance;
  final ErrorHandlingService _errorService = ErrorHandlingService.instance;
  final SyncService _syncService = SyncService.instance;
  final TemplateStorageService _storageService = TemplateStorageService.instance;
  
  // Real-time data
  bool _isOnline = true;
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  NetworkHealthStatus _networkHealth = NetworkHealthStatus.healthy;
  NetworkQualityStats _networkStats = NetworkQualityStats.empty();
  ErrorStatistics _errorStats = ErrorStatistics(
    totalErrors: 0,
    criticalErrors: 0,
    networkErrors: 0,
    apiErrors: 0,
    errorRate: 0.0,
  );
  Map<String, dynamic> _syncStats = {};
  Map<String, dynamic> _storageStats = {};
  
  // Stream subscriptions
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;
  StreamSubscription<AppError>? _errorSubscription;
  StreamSubscription<AppError>? _criticalErrorSubscription;
  
  // Refresh timer
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
    _startPeriodicRefresh();
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _networkStatusSubscription?.cancel();
    _errorSubscription?.cancel();
    _criticalErrorSubscription?.cancel();
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
  
  /// Initialize services and start listening
  Future<void> _initializeServices() async {
    try {
      // Initialize network service
      await _networkService.initialize();
      
      // Get initial data
      _updateNetworkData();
      _updateErrorData();
      _updateSyncData();
      _updateStorageData();
      
      // Listen to changes
      _connectivitySubscription = _networkService.connectivityStream.listen((isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
      });
      
      _networkStatusSubscription = _networkService.networkStatusStream.listen((status) {
        setState(() {
          _networkStatus = status;
          _updateNetworkData();
        });
      });
      
      _errorSubscription = _errorService.errorStream.listen((error) {
        _updateErrorData();
      });
      
      _criticalErrorSubscription = _errorService.criticalErrorStream.listen((error) {
        _updateErrorData();
      });
      
    } catch (e) {
      ApiConfig.logApiError('Initialize system health', e);
    }
  }
  
  /// Start periodic refresh
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshAllData();
      }
    });
  }
  
  /// Refresh all data
  Future<void> _refreshAllData() async {
    _updateNetworkData();
    _updateErrorData();
    _updateSyncData();
    _updateStorageData();
  }
  
  /// Update network data
  void _updateNetworkData() {
    setState(() {
      _isOnline = _networkService.isOnline;
      _networkStatus = _networkService.currentStatus;
      _networkHealth = _networkService.getNetworkHealthStatus();
      _networkStats = _networkService.getNetworkQualityStats();
    });
  }
  
  /// Update error data
  void _updateErrorData() {
    setState(() {
      _errorStats = _errorService.getErrorStatistics();
    });
  }
  
  /// Update sync data
  void _updateSyncData() {
    setState(() {
      _syncStats = _syncService.getSyncStatistics();
    });
  }
  
  /// Update storage data
  Future<void> _updateStorageData() async {
    try {
      final stats = await _storageService.getCacheStatistics();
      setState(() {
        _storageStats = stats;
      });
    } catch (e) {
      ApiConfig.logApiError('Update storage data', e);
    }
  }
  
  /// Test network quality
  Future<void> _testNetworkQuality() async {
    try {
      final metric = await _networkService.testNetworkQuality();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Network test completed: ${metric.responseTimeDescription}',
            backgroundColor: metric.isSuccessful ? Colors.green : Colors.red,
          ),
        ),
      );
      
      _updateNetworkData();
    } catch (e) {
      ApiConfig.logApiError('Test network quality', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network test failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Clear error history
  void _clearErrorHistory() {
    _errorService.clearErrorHistory();
    _updateErrorData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error history cleared')),
    );
  }
  
  /// Clear critical errors
  void _clearCriticalErrors() {
    _errorService.clearCriticalErrors();
    _updateErrorData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Critical errors cleared')),
    );
  }
  
  /// Clear network quality metrics
  void _clearNetworkMetrics() {
    _networkService.clearQualityMetrics();
    _updateNetworkData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network quality metrics cleared')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Network', icon: Icon(Icons.wifi)),
            Tab(text: 'Errors', icon: Icon(Icons.error)),
            Tab(text: 'Storage', icon: Icon(Icons.storage)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildNetworkTab(),
          _buildErrorsTab(),
          _buildStorageTab(),
        ],
      ),
    );
  }
  
  /// Build Overview tab
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // System status overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Status Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusGrid(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testNetworkQuality,
                          icon: const Icon(Icons.wifi_find),
                          label: const Text('Test Network'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _refreshAllData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build status grid
  Widget _buildStatusGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatusCard(
          'Network Status',
          _networkService.getNetworkTypeDescription(),
          _getNetworkStatusIcon(),
          _getNetworkStatusColor(),
        ),
        _buildStatusCard(
          'Network Health',
          _networkService.getNetworkHealthDescription(),
          _getNetworkHealthIcon(),
          _getNetworkHealthColor(),
        ),
        _buildStatusCard(
          'Error Rate',
          _errorStats.errorRateDescription,
          _getErrorRateIcon(),
          _getErrorRateColor(),
        ),
        _buildStatusCard(
          'Sync Status',
          _syncStats['is_currently_syncing'] == true ? 'Syncing...' : 'Idle',
          _getSyncStatusIcon(),
          _getSyncStatusColor(),
        ),
      ],
    );
  }
  
  /// Build Network tab
  Widget _buildNetworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Network status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getNetworkStatusIcon(), color: _getNetworkStatusColor()),
                      const SizedBox(width: 8),
                      Text(
                        'Network Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNetworkStatusDetails(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Network quality statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Quality Statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNetworkQualityStats(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Network actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testNetworkQuality,
                          icon: const Icon(Icons.wifi_find),
                          label: const Text('Test Quality'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearNetworkMetrics,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Metrics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build network status details
  Widget _buildNetworkStatusDetails() {
    return Column(
      children: [
        _buildDetailRow('Connection Status', _isOnline ? 'Online' : 'Offline'),
        _buildDetailRow('Network Type', _networkService.getNetworkTypeDescription()),
        _buildDetailRow('Health Status', _networkService.getNetworkHealthDescription()),
        _buildDetailRow('Stability', _networkService.isNetworkStable ? 'Stable' : 'Unstable'),
        if (_networkStats.lastTestTime != null)
          _buildDetailRow('Last Test', _networkStats.timeSinceLastTest),
      ],
    );
  }
  
  /// Build network quality stats
  Widget _buildNetworkQualityStats() {
    return Column(
      children: [
        _buildDetailRow('Total Tests', '${_networkStats.totalTests}'),
        _buildDetailRow('Successful Tests', '${_networkStats.successfulTests}'),
        _buildDetailRow('Failed Tests', '${_networkStats.failedTests}'),
        _buildDetailRow('Success Rate', '${_networkStats.successRate.toStringAsFixed(1)}%'),
        _buildDetailRow('Average Response', _networkStats.formattedAverageResponseTime),
      ],
    );
  }
  
  /// Build Errors tab
  Widget _buildErrorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Error Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildErrorStats(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent errors
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Errors',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentErrors(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Error actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearErrorHistory,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear History'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearCriticalErrors,
                          icon: const Icon(Icons.warning),
                          label: const Text('Clear Critical'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build error statistics
  Widget _buildErrorStats() {
    return Column(
      children: [
        _buildDetailRow('Total Errors', '${_errorStats.totalErrors}'),
        _buildDetailRow('Critical Errors', '${_errorStats.criticalErrors}'),
        _buildDetailRow('Network Errors', '${_errorStats.networkErrors}'),
        _buildDetailRow('API Errors', '${_errorStats.apiErrors}'),
        _buildDetailRow('Error Rate', _errorStats.errorRateDescription),
        if (_errorStats.lastErrorTime != null)
          _buildDetailRow('Last Error', _errorStats.timeSinceLastError),
      ],
    );
  }
  
  /// Build recent errors
  Widget _buildRecentErrors() {
    final recentErrors = _errorService.errorHistory.take(5).toList();
    
    if (recentErrors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No recent errors',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return Column(
      children: recentErrors.map((error) => _buildErrorTile(error)).toList(),
    );
  }
  
  /// Build error tile
  Widget _buildErrorTile(AppError error) {
    final severity = _errorService.getErrorSeverity(error);
    
    return ListTile(
      leading: Icon(
        _getErrorSeverityIcon(severity),
        color: _getErrorSeverityColor(severity),
      ),
      title: Text(
        error.context,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        error.errorMessage,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        error.timeSinceError,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: () {
        _showErrorDetails(error);
      },
    );
  }
  
  /// Build Storage tab
  Widget _buildStorageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Storage overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: Colors.purple[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Storage Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStorageStats(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sync status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSyncStats(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build storage stats
  Widget _buildStorageStats() {
    return Column(
      children: [
        _buildDetailRow('Total Cache Size', '${_storageStats['total_size_formatted'] ?? '0B'}'),
        _buildDetailRow('Templates Cached', '${_storageStats['templates_count'] ?? 0}'),
        _buildDetailRow('Thumbnails Cached', '${_storageStats['thumbnails_count'] ?? 0}'),
        _buildDetailRow('Cache Usage', '${_storageStats['cache_usage_percent']?.toStringAsFixed(1) ?? '0'}%'),
        _buildDetailRow('Max Cache Size', '${_storageStats['max_cache_size_formatted'] ?? '0B'}'),
      ],
    );
  }
  
  /// Build sync stats
  Widget _buildSyncStats() {
    return Column(
      children: [
        _buildDetailRow('Total Operations', '${_syncStats['total_operations'] ?? 0}'),
        _buildDetailRow('Successful Operations', '${_syncStats['successful_operations'] ?? 0}'),
        _buildDetailRow('Failed Operations', '${_syncStats['failed_operations'] ?? 0}'),
        _buildDetailRow('Success Rate', '${_syncStats['success_rate']?.toStringAsFixed(1) ?? '0'}%'),
        if (_syncStats['last_sync_attempt'] != null)
          _buildDetailRow('Last Sync Attempt', _syncStats['last_sync_attempt']),
      ],
    );
  }
  
  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build status card
  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Show error details
  void _showErrorDetails(AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error Details: ${error.context}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Error Type', error.errorType),
              _buildDetailRow('Error Message', error.errorMessage),
              _buildDetailRow('Timestamp', error.formattedTimestamp),
              _buildDetailRow('Time Since', error.timeSinceError),
              _buildDetailRow('Critical', error.isCritical ? 'Yes' : 'No'),
              if (error.userMessage != null)
                _buildDetailRow('User Message', error.userMessage!),
              if (error.additionalData != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Additional Data:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(error.additionalData.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Helper methods for icons and colors
  IconData _getNetworkStatusIcon() {
    if (!_isOnline) return Icons.wifi_off;
    switch (_networkStatus) {
      case NetworkStatus.wifi:
        return Icons.wifi;
      case NetworkStatus.mobile:
        return Icons.mobile_friendly;
      case NetworkStatus.ethernet:
        return Icons.ethernet;
      case NetworkStatus.vpn:
        return Icons.vpn_key;
      case NetworkStatus.bluetooth:
        return Icons.bluetooth;
      case NetworkStatus.other:
        return Icons.device_unknown;
      case NetworkStatus.none:
        return Icons.wifi_off;
      case NetworkStatus.unknown:
      default:
        return Icons.help;
    }
  }
  
  Color _getNetworkStatusColor() {
    if (!_isOnline) return Colors.red;
    switch (_networkStatus) {
      case NetworkStatus.wifi:
        return Colors.green;
      case NetworkStatus.mobile:
        return Colors.blue;
      case NetworkStatus.ethernet:
        return Colors.purple;
      case NetworkStatus.vpn:
        return Colors.orange;
      case NetworkStatus.bluetooth:
        return Colors.indigo;
      case NetworkStatus.other:
        return Colors.grey;
      case NetworkStatus.none:
        return Colors.red;
      case NetworkStatus.unknown:
      default:
        return Colors.grey;
    }
  }
  
  IconData _getNetworkHealthIcon() {
    switch (_networkHealth) {
      case NetworkHealthStatus.healthy:
        return Icons.check_circle;
      case NetworkHealthStatus.slow:
        return Icons.slow_motion_video;
      case NetworkHealthStatus.unstable:
        return Icons.warning;
      case NetworkHealthStatus.offline:
        return Icons.wifi_off;
    }
  }
  
  Color _getNetworkHealthColor() {
    switch (_networkHealth) {
      case NetworkHealthStatus.healthy:
        return Colors.green;
      case NetworkHealthStatus.slow:
        return Colors.orange;
      case NetworkHealthStatus.unstable:
        return Colors.red;
      case NetworkHealthStatus.offline:
        return Colors.grey;
    }
  }
  
  IconData _getErrorRateIcon() {
    if (_errorStats.isErrorRateConcerning) return Icons.error;
    if (_errorStats.totalErrors > 0) return Icons.warning;
    return Icons.check_circle;
  }
  
  Color _getErrorRateColor() {
    if (_errorStats.isErrorRateConcerning) return Colors.red;
    if (_errorStats.totalErrors > 0) return Colors.orange;
    return Colors.green;
  }
  
  IconData _getSyncStatusIcon() {
    if (_syncStats['is_currently_syncing'] == true) return Icons.sync;
    return Icons.check_circle;
  }
  
  Color _getSyncStatusColor() {
    if (_syncStats['is_currently_syncing'] == true) return Colors.blue;
    return Colors.green;
  }
  
  IconData _getErrorSeverityIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info;
      case ErrorSeverity.warning:
        return Icons.warning;
      case ErrorSeverity.error:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.crisis_alert;
    }
  }
  
  Color _getErrorSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.purple;
    }
  }
} 