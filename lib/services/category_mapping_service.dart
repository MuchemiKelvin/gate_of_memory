/// Category Mapping Service for Kardiverse Mobile
/// 
/// This service maps backend template categories to mobile app memorial categories.
/// Backend has different categories (business-cards, greeting-cards, etc.) than
/// the mobile app (memorial, celebration, tribute, historical).
class CategoryMappingService {
  // Backend template categories
  static const String businessCards = 'business-cards';
  static const String greetingCards = 'greeting-cards';
  static const String invitations = 'invitations';
  static const String flyers = 'flyers';
  static const String posters = 'posters';
  
  // Mobile app memorial categories
  static const String memorial = 'memorial';
  static const String celebration = 'celebration';
  static const String tribute = 'tribute';
  static const String historical = 'historical';
  
  // Mapping from backend categories to mobile categories
  static const Map<String, String> _backendToMobileMapping = {
    businessCards: memorial,      // Business cards → Memorial
    greetingCards: celebration,   // Greeting cards → Celebration
    invitations: tribute,         // Invitations → Tribute
    flyers: historical,          // Flyers → Historical
    posters: memorial,           // Posters → Memorial
  };
  
  // Reverse mapping from mobile categories to backend categories
  static const Map<String, List<String>> _mobileToBackendMapping = {
    memorial: [businessCards, posters],
    celebration: [greetingCards],
    tribute: [invitations],
    historical: [flyers],
  };
  
  /// Map backend category to mobile category
  /// 
  /// [backendCategory] - The category from the backend (e.g., 'business-cards')
  /// Returns the corresponding mobile category (e.g., 'memorial')
  /// If no mapping found, returns 'memorial' as default
  static String mapBackendToMobile(String backendCategory) {
    return _backendToMobileMapping[backendCategory] ?? memorial;
  }
  
  /// Map mobile category to possible backend categories
  /// 
  /// [mobileCategory] - The category from the mobile app (e.g., 'memorial')
  /// Returns a list of possible backend categories
  /// If no mapping found, returns empty list
  static List<String> mapMobileToBackend(String mobileCategory) {
    return _mobileToBackendMapping[mobileCategory] ?? [];
  }
  
  /// Get all available backend categories
  /// 
  /// Returns a list of all backend template categories
  static List<String> getBackendCategories() {
    return _backendToMobileMapping.keys.toList();
  }
  
  /// Get all available mobile categories
  /// 
  /// Returns a list of all mobile memorial categories
  static List<String> getMobileCategories() {
    return _mobileToBackendMapping.keys.toList();
  }
  
  /// Check if a backend category is valid
  /// 
  /// [backendCategory] - The category to validate
  /// Returns true if the category exists in the mapping
  static bool isValidBackendCategory(String backendCategory) {
    return _backendToMobileMapping.containsKey(backendCategory);
  }
  
  /// Check if a mobile category is valid
  /// 
  /// [mobileCategory] - The category to validate
  /// Returns true if the category exists in the mapping
  static bool isValidMobileCategory(String mobileCategory) {
    return _mobileToBackendMapping.containsKey(mobileCategory);
  }
  
  /// Get mapping statistics
  /// 
  /// Returns a map with mapping information for debugging
  static Map<String, dynamic> getMappingStatistics() {
    return {
      'total_backend_categories': _backendToMobileMapping.length,
      'total_mobile_categories': _mobileToBackendMapping.length,
      'mappings': _backendToMobileMapping,
      'reverse_mappings': _mobileToBackendMapping,
    };
  }
  
  /// Validate mapping consistency
  /// 
  /// Returns true if all mappings are consistent
  /// Logs any inconsistencies found
  static bool validateMappingConsistency() {
    bool isConsistent = true;
    
    // Check if all backend categories have valid mobile mappings
    for (String backendCategory in _backendToMobileMapping.keys) {
      String mobileCategory = _backendToMobileMapping[backendCategory]!;
      if (!_mobileToBackendMapping.containsKey(mobileCategory)) {
        print('❌ Inconsistent mapping: $backendCategory → $mobileCategory (mobile category not found)');
        isConsistent = false;
      }
    }
    
    // Check if all mobile categories have at least one backend mapping
    for (String mobileCategory in _mobileToBackendMapping.keys) {
      List<String> backendCategories = _mobileToBackendMapping[mobileCategory]!;
      if (backendCategories.isEmpty) {
        print('❌ Inconsistent mapping: $mobileCategory has no backend categories');
        isConsistent = false;
      }
    }
    
    if (isConsistent) {
      print('✅ Category mapping is consistent');
    }
    
    return isConsistent;
  }
  
  /// Get category description for display
  /// 
  /// [category] - The category name
  /// [isBackend] - True if it's a backend category, false if mobile
  /// Returns a user-friendly description of the category
  static String getCategoryDescription(String category, {bool isBackend = false}) {
    if (isBackend) {
      switch (category) {
        case businessCards:
          return 'Business Card Templates';
        case greetingCards:
          return 'Greeting Card Templates';
        case invitations:
          return 'Invitation Templates';
        case flyers:
          return 'Flyer Templates';
        case posters:
          return 'Poster Templates';
        default:
          return 'Unknown Template Type';
      }
    } else {
      switch (category) {
        case memorial:
          return 'Memorial Templates';
        case celebration:
          return 'Celebration Templates';
        case tribute:
          return 'Tribute Templates';
        case historical:
          return 'Historical Templates';
        default:
          return 'Unknown Category';
      }
    }
  }
} 