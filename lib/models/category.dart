class Category {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int sortOrder;
  final int memorialCount;
  final String status;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.memorialCount,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#7bb6e7',
      sortOrder: json['sort_order'] ?? 0,
      memorialCount: json['memorial_count'] ?? 0,
      status: json['status'] ?? 'active',
      syncStatus: json['sync_status'] ?? 'synced',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'memorial_count': memorialCount,
      'status': status,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isActive => status == 'active';
  bool get hasMemorials => memorialCount > 0;

  // Create a copy with updated fields
  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    int? memorialCount,
    String? status,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      memorialCount: memorialCount ?? this.memorialCount,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, memorialCount: $memorialCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Predefined categories for the app
class PredefinedCategories {
  static final List<Category> defaultCategories = [
    Category(
      id: 1,
      name: 'Memorial',
      description: 'Traditional memorial services',
      icon: 'memory',
      color: '#7bb6e7',
      sortOrder: 1,
      memorialCount: 0,
      status: 'active',
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Category(
      id: 2,
      name: 'Celebration',
      description: 'Celebration of life services',
      icon: 'celebration',
      color: '#4CAF50',
      sortOrder: 2,
      memorialCount: 0,
      status: 'active',
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Category(
      id: 3,
      name: 'Tribute',
      description: 'Special tribute memorials',
      icon: 'star',
      color: '#FF9800',
      sortOrder: 3,
      memorialCount: 0,
      status: 'active',
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Category(
      id: 4,
      name: 'Historical',
      description: 'Historical memorials',
      icon: 'history',
      color: '#9C27B0',
      sortOrder: 4,
      memorialCount: 0,
      status: 'active',
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static Category get defaultCategory => defaultCategories.first;
} 