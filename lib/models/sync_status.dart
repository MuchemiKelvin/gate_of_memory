/// Sync status model for tracking synchronization progress
/// 
/// This model represents the overall synchronization status of the
/// Kardiverse mobile application with the backend.
class SyncStatus {
  final int totalTemplates;
  final int syncedTemplates;
  final int pendingSync;
  final int failedSync;
  final DateTime? lastSyncAt;
  final List<SyncLog> recentSyncLogs;
  final String overallStatus;
  final bool isSyncing;

  const SyncStatus({
    required this.totalTemplates,
    required this.syncedTemplates,
    required this.pendingSync,
    required this.failedSync,
    this.lastSyncAt,
    this.recentSyncLogs = const [],
    required this.overallStatus,
    required this.isSyncing,
  });

  /// Create SyncStatus from JSON response
  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      totalTemplates: json['total_templates'] as int? ?? 0,
      syncedTemplates: json['synced_templates'] as int? ?? 0,
      pendingSync: json['pending_sync'] as int? ?? 0,
      failedSync: json['failed_sync'] as int? ?? 0,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      recentSyncLogs: (json['recent_sync_logs'] as List<dynamic>?)
              ?.map((log) => SyncLog.fromJson(log as Map<String, dynamic>))
              .toList() ??
          [],
      overallStatus: json['overall_status'] as String? ?? 'unknown',
      isSyncing: json['is_syncing'] as bool? ?? false,
    );
  }

  /// Convert SyncStatus to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_templates': totalTemplates,
      'synced_templates': syncedTemplates,
      'pending_sync': pendingSync,
      'failed_sync': failedSync,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'recent_sync_logs': recentSyncLogs.map((log) => log.toJson()).toList(),
      'overall_status': overallStatus,
      'is_syncing': isSyncing,
    };
  }

  /// Get sync progress percentage
  double get syncProgress {
    if (totalTemplates == 0) return 0.0;
    return (syncedTemplates / totalTemplates) * 100;
  }
  
  /// Check if sync is complete
  bool get isSyncComplete => syncedTemplates == totalTemplates && totalTemplates > 0;
  
  /// Check if there are sync errors
  bool get hasSyncErrors => failedSync > 0;
  
  /// Check if sync is needed
  bool get needsSync => pendingSync > 0 || failedSync > 0;
  
  /// Get sync status description
  String get syncStatusDescription {
    if (isSyncing) return 'Syncing...';
    if (isSyncComplete) return 'Fully Synced';
    if (hasSyncErrors) return 'Sync Errors';
    if (needsSync) return 'Sync Needed';
    return 'Unknown';
  }
  
  /// Get time since last sync
  String get timeSinceLastSync {
    if (lastSyncAt == null) return 'Never';
    
    final timeDiff = DateTime.now().difference(lastSyncAt!);
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
  
  /// Get sync summary
  String get syncSummary {
    if (totalTemplates == 0) return 'No templates';
    
    final parts = <String>[];
    if (syncedTemplates > 0) {
      parts.add('$syncedTemplates synced');
    }
    if (pendingSync > 0) {
      parts.add('$pendingSync pending');
    }
    if (failedSync > 0) {
      parts.add('$failedSync failed');
    }
    
    return parts.join(', ');
  }
  
  /// Check if sync is healthy (less than 10% failed)
  bool get isSyncHealthy {
    if (totalTemplates == 0) return true;
    final failureRate = (failedSync / totalTemplates) * 100;
    return failureRate < 10;
  }
  
  /// Get sync health status
  String get syncHealthStatus {
    if (isSyncHealthy) return 'Healthy';
    if (hasSyncErrors) return 'Unhealthy';
    return 'Unknown';
  }

  /// Create a copy with updated fields
  SyncStatus copyWith({
    int? totalTemplates,
    int? syncedTemplates,
    int? pendingSync,
    int? failedSync,
    DateTime? lastSyncAt,
    List<SyncLog>? recentSyncLogs,
    String? overallStatus,
    bool? isSyncing,
  }) {
    return SyncStatus(
      totalTemplates: totalTemplates ?? this.totalTemplates,
      syncedTemplates: syncedTemplates ?? this.syncedTemplates,
      pendingSync: pendingSync ?? this.pendingSync,
      failedSync: failedSync ?? this.failedSync,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      recentSyncLogs: recentSyncLogs ?? this.recentSyncLogs,
      overallStatus: overallStatus ?? this.overallStatus,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  String toString() {
    return 'SyncStatus(total: $totalTemplates, synced: $syncedTemplates, pending: $pendingSync, failed: $failedSync)';
  }
}

/// Sync log entry for tracking individual sync operations
class SyncLog {
  final String operation;
  final String status;
  final String? message;
  final DateTime timestamp;
  final int? templateId;
  final String? templateName;

  const SyncLog({
    required this.operation,
    required this.status,
    this.message,
    required this.timestamp,
    this.templateId,
    this.templateName,
  });

  /// Create SyncLog from JSON
  factory SyncLog.fromJson(Map<String, dynamic> json) {
    return SyncLog(
      operation: json['operation'] as String,
      status: json['status'] as String,
      message: json['message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      templateId: json['template_id'] as int?,
      templateName: json['template_name'] as String?,
    );
  }

  /// Convert SyncLog to JSON
  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'status': status,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'template_id': templateId,
      'template_name': templateName,
    };
  }

  /// Check if sync operation was successful
  bool get isSuccessful => status.toLowerCase() == 'success';
  
  /// Check if sync operation failed
  bool get isFailed => status.toLowerCase() == 'failed';
  
  /// Check if sync operation is in progress
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  
  /// Get status description
  String get statusDescription {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Success';
      case 'failed':
        return 'Failed';
      case 'in_progress':
        return 'In Progress';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }
  
  /// Get time since operation
  String get timeSinceOperation {
    final timeDiff = DateTime.now().difference(timestamp);
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

  @override
  String toString() {
    return 'SyncLog(operation: $operation, status: $status, template: ${templateName ?? templateId})';
  }
} 