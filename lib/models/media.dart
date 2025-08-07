enum MediaType {
  image,
  video,
  audio,
  hologram,
}

class Media {
  final int id;
  final int memorialId;
  final MediaType type;
  final String title;
  final String description;
  final String localPath;
  final String remoteUrl;
  final int fileSize;
  final String fileType;
  final String mimeType;
  final Map<String, dynamic> metadata;
  final String status;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Media({
    required this.id,
    required this.memorialId,
    required this.type,
    required this.title,
    required this.description,
    required this.localPath,
    required this.remoteUrl,
    required this.fileSize,
    required this.fileType,
    required this.mimeType,
    required this.metadata,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      memorialId: json['memorial_id'],
      type: MediaType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MediaType.image,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      localPath: json['local_path'] ?? '',
      remoteUrl: json['remote_url'] ?? '',
      fileSize: json['file_size'] ?? 0,
      fileType: json['file_type'] ?? '',
      mimeType: json['mime_type'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      status: json['status'] ?? 'active',
      syncStatus: json['sync_status'] ?? 'synced',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memorial_id': memorialId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'local_path': localPath,
      'remote_url': remoteUrl,
      'file_size': fileSize,
      'file_type': fileType,
      'mime_type': mimeType,
      'metadata': metadata,
      'status': status,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isActive => status == 'active';
  bool get isLocal => localPath.isNotEmpty;
  bool get isRemote => remoteUrl.isNotEmpty;
  bool get isDownloaded => localPath.isNotEmpty;
  bool get needsDownload => remoteUrl.isNotEmpty && localPath.isEmpty;
  bool get isImage => type == MediaType.image;
  bool get isVideo => type == MediaType.video;
  bool get isAudio => type == MediaType.audio;
  bool get isHologram => type == MediaType.hologram;

  // File size formatting
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Get display path (local if available, otherwise remote)
  String get displayPath => isLocal ? localPath : remoteUrl;

  // Create a copy with updated fields
  Media copyWith({
    int? id,
    int? memorialId,
    MediaType? type,
    String? title,
    String? description,
    String? localPath,
    String? remoteUrl,
    int? fileSize,
    String? fileType,
    String? mimeType,
    Map<String, dynamic>? metadata,
    String? status,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Media(
      id: id ?? this.id,
      memorialId: memorialId ?? this.memorialId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Media(id: $id, type: $type, title: $title, memorialId: $memorialId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Media && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extension for MediaType
extension MediaTypeExtension on MediaType {
  String get displayName {
    switch (this) {
      case MediaType.image:
        return 'Image';
      case MediaType.video:
        return 'Video';
      case MediaType.audio:
        return 'Audio';
      case MediaType.hologram:
        return 'Hologram';
    }
  }

  String get icon {
    switch (this) {
      case MediaType.image:
        return 'photo';
      case MediaType.video:
        return 'videocam';
      case MediaType.audio:
        return 'audiotrack';
      case MediaType.hologram:
        return 'view_in_ar';
    }
  }

  List<String> get supportedExtensions {
    switch (this) {
      case MediaType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      case MediaType.video:
        return ['mp4', 'avi', 'mov', 'mkv', 'webm'];
      case MediaType.audio:
        return ['mp3', 'wav', 'aac', 'ogg', 'm4a'];
      case MediaType.hologram:
        return ['mp4', 'webm', 'gif'];
    }
  }
} 