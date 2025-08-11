/// Template model for template management and synchronization
/// 
/// This model represents a template in the Kardiverse system with its
/// metadata, file information, and synchronization status.
class Template {
  final int id;
  final String name;
  final String description;
  final String category;
  final String version;
  final int fileSize;
  final String fileType;
  final String fileUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic> metadata;
  final String status;
  final String syncStatus;
  final int downloadCount;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final int? remoteId;

  const Template({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.version,
    required this.fileSize,
    required this.fileType,
    required this.fileUrl,
    this.thumbnailUrl,
    this.metadata = const {},
    required this.status,
    required this.syncStatus,
    required this.downloadCount,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    this.remoteId,
  });

  /// Create Template from JSON response
  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      version: json['version'] as String,
      fileSize: json['file_size'] as int,
      fileType: json['file_type'] as String,
      fileUrl: json['file_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      status: json['status'] as String,
      syncStatus: json['sync_status'] as String? ?? 'pending',
      downloadCount: json['download_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      remoteId: json['remote_id'] as int?,
    );
  }

  /// Convert Template to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'version': version,
      'file_size': fileSize,
      'file_type': fileType,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'metadata': metadata,
      'status': status,
      'sync_status': syncStatus,
      'download_count': downloadCount,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'remote_id': remoteId,
    };
  }

  /// Check if template is active
  bool get isActive => status.toLowerCase() == 'active';
  
  /// Check if template is synced
  bool get isSynced => syncStatus.toLowerCase() == 'synced';
  
  /// Check if template needs sync
  bool get needsSync => syncStatus.toLowerCase() == 'pending' || 
                       syncStatus.toLowerCase() == 'failed';
  
  /// Check if template has been downloaded
  bool get hasBeenDownloaded => downloadCount > 0;
  
  /// Check if template has thumbnail
  bool get hasThumbnail => thumbnailUrl != null;
  
  /// Get file size in human readable format
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
  
  /// Get sync status description
  String get syncStatusDescription {
    switch (syncStatus.toLowerCase()) {
      case 'synced':
        return 'Synced';
      case 'pending':
        return 'Pending Sync';
      case 'failed':
        return 'Sync Failed';
      case 'in_progress':
        return 'Syncing...';
      default:
        return 'Unknown';
    }
  }
  
  /// Get template status description
  String get statusDescription {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'archived':
        return 'Archived';
      case 'draft':
        return 'Draft';
      default:
        return 'Unknown';
    }
  }
  
  /// Check if template can be downloaded
  bool get canBeDownloaded => isActive && isSynced;
  
  /// Check if template is large file (>10MB)
  bool get isLargeFile => fileSize > 10 * 1024 * 1024;
  
  /// Get time since last sync
  String get timeSinceLastSync {
    if (lastSyncedAt == null) return 'Never synced';
    
    final timeDiff = DateTime.now().difference(lastSyncedAt!);
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
  
  /// Check if template needs update (older than 30 days)
  bool get needsUpdate {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return updatedAt.isBefore(thirtyDaysAgo);
  }
  
  /// Get category display name
  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'business-cards':
        return 'Business Cards';
      case 'greeting-cards':
        return 'Greeting Cards';
      case 'invitations':
        return 'Invitations';
      case 'flyers':
        return 'Flyers';
      case 'posters':
        return 'Posters';
      default:
        return category;
    }
  }
  
  /// Get file extension
  String get fileExtension {
    final parts = fileType.split('/');
    if (parts.length > 1) {
      return parts[1].toUpperCase();
    }
    return fileType.toUpperCase();
  }

  /// Create a copy with updated fields
  Template copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? version,
    int? fileSize,
    String? fileType,
    String? fileUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    String? status,
    String? syncStatus,
    int? downloadCount,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    int? remoteId,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      version: version ?? this.version,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      downloadCount: downloadCount ?? this.downloadCount,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  @override
  String toString() {
    return 'Template(id: $id, name: $name, category: $category, version: $version, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Template && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 