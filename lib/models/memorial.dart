class Memorial {
  final int id;
  final String name;
  final String description;
  final String category;
  final String version;
  final String imagePath;
  final String videoPath;
  final String hologramPath;
  final List<String> audioPaths;
  final List<Story> stories;
  final String qrCode;
  final String status;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Memorial({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.version,
    required this.imagePath,
    required this.videoPath,
    required this.hologramPath,
    required this.audioPaths,
    required this.stories,
    required this.qrCode,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Memorial.fromJson(Map<String, dynamic> json) {
    return Memorial(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'memorial',
      version: json['version'] ?? '1.0',
      imagePath: json['image_path'] ?? '',
      videoPath: json['video_path'] ?? '',
      hologramPath: json['hologram_path'] ?? '',
      audioPaths: List<String>.from(json['audio_paths'] ?? []),
      stories: (json['stories'] as List<dynamic>?)
          ?.map((story) => Story.fromJson(story))
          .toList() ?? [],
      qrCode: json['qr_code'] ?? '',
      status: json['status'] ?? 'active',
      syncStatus: json['sync_status'] ?? 'synced',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'version': version,
      'image_path': imagePath,
      'video_path': videoPath,
      'hologram_path': hologramPath,
      'audio_paths': audioPaths,
      'stories': stories.map((story) => story.toJson()).toList(),
      'qr_code': qrCode,
      'status': status,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isActive => status == 'active';
  bool get isDeleted => deletedAt != null;
  bool get hasImage => imagePath.isNotEmpty;
  bool get hasVideo => videoPath.isNotEmpty;
  bool get hasHologram => hologramPath.isNotEmpty;
  bool get hasAudio => audioPaths.isNotEmpty;
  bool get hasStories => stories.isNotEmpty;

  // Create a copy with updated fields
  Memorial copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? version,
    String? imagePath,
    String? videoPath,
    String? hologramPath,
    List<String>? audioPaths,
    List<Story>? stories,
    String? qrCode,
    String? status,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Memorial(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      version: version ?? this.version,
      imagePath: imagePath ?? this.imagePath,
      videoPath: videoPath ?? this.videoPath,
      hologramPath: hologramPath ?? this.hologramPath,
      audioPaths: audioPaths ?? this.audioPaths,
      stories: stories ?? this.stories,
      qrCode: qrCode ?? this.qrCode,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Memorial(id: $id, name: $name, category: $category, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Memorial && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Story {
  final String title;
  final String snippet;
  final String fullText;

  Story({
    required this.title,
    required this.snippet,
    required this.fullText,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      title: json['title'] ?? '',
      snippet: json['snippet'] ?? '',
      fullText: json['full_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'snippet': snippet,
      'full_text': fullText,
    };
  }

  @override
  String toString() {
    return 'Story(title: $title)';
  }
} 