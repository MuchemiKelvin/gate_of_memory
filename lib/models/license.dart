/// License model for license management and validation
/// 
/// This model represents a license in the Kardiverse system with its
/// activation status, template association, and metadata.
class License {
  final int id;
  final String code;
  final int templateId;
  final String status;
  final int? assignedTo;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  const License({
    required this.id,
    required this.code,
    required this.templateId,
    required this.status,
    this.assignedTo,
    this.activatedAt,
    this.expiresAt,
    this.metadata = const {},
  });

  /// Create License from JSON response
  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      id: json['id'] as int,
      code: json['code'] as String,
      templateId: json['template_id'] as int,
      status: json['status'] as String,
      assignedTo: json['assigned_to'] as int?,
      activatedAt: json['activated_at'] != null
          ? DateTime.parse(json['activated_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert License to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'template_id': templateId,
      'status': status,
      'assigned_to': assignedTo,
      'activated_at': activatedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Check if license is active
  bool get isActive => status.toLowerCase() == 'active';
  
  /// Check if license is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  /// Check if license will expire soon (within 30 days)
  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return thirtyDaysFromNow.isAfter(expiresAt!);
  }
  
  /// Check if license is assigned to a user
  bool get isAssigned => assignedTo != null;
  
  /// Check if license is activated
  bool get isActivated => activatedAt != null;
  
  /// Get time until license expires
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now());
  }
  
  /// Get formatted expiry time string
  String get formattedExpiryTime {
    if (expiresAt == null) return 'No expiry';
    
    final timeLeft = timeUntilExpiry!;
    if (timeLeft.isNegative) return 'Expired';
    
    final days = timeLeft.inDays;
    final hours = timeLeft.inHours % 24;
    
    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      final minutes = timeLeft.inMinutes % 60;
      return '${minutes}m';
    }
  }
  
  /// Get license status description
  String get statusDescription {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'expired':
        return 'Expired';
      case 'revoked':
        return 'Revoked';
      default:
        return 'Unknown';
    }
  }
  
  /// Check if license can be activated
  bool get canBeActivated => isActive && !isActivated && !isExpired;
  
  /// Check if license can be assigned
  bool get canBeAssigned => isActive && !isAssigned && !isExpired;

  /// Create a copy with updated fields
  License copyWith({
    int? id,
    String? code,
    int? templateId,
    String? status,
    int? assignedTo,
    DateTime? activatedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return License(
      id: id ?? this.id,
      code: code ?? this.code,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      activatedAt: activatedAt ?? this.activatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'License(id: $id, code: $code, templateId: $templateId, status: $status, assignedTo: $assignedTo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is License && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 