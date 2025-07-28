import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui';
import 'dart:io';

/// Location detection result
class LocationResult {
  final bool isAllowed;
  final String? country;
  final String? city;
  final List<String> detectionMethods;
  final LocationError? error;

  LocationResult({
    required this.isAllowed,
    this.country,
    this.city,
    required this.detectionMethods,
    this.error,
  });
}

/// Location error types
class LocationError {
  final String message;
  final LocationErrorType type;

  LocationError({
    required this.message,
    required this.type,
  });
}

enum LocationErrorType {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  networkError,
  unknown,
}

class LocationService {
  static const String _targetCountry = 'KE'; // Kenya
  static const Duration _gpsTimeout = Duration(seconds: 10);
  static const Duration _networkTimeout = Duration(seconds: 5);

  /// Check if user is in allowed location
  static Future<LocationResult> checkLocationAccess() async {
    List<String> detectionMethods = [];
    String? detectedCountry;
    String? detectedCity;
    LocationError? error;

    try {
      // Method 1: GPS Location (Most Accurate)
      try {
        final gpsResult = await _getGpsLocation();
        if (gpsResult != null) {
          detectedCountry = gpsResult['country'];
          detectedCity = gpsResult['city'];
          detectionMethods.add('GPS: ${gpsResult['display']}');
          print('🔍 GPS Result: ${gpsResult['display']}');
        }
      } catch (e) {
        detectionMethods.add('GPS: Failed - ${e.toString()}');
        print('❌ GPS Error: $e');
      }

      // Method 2: Device Locale
      final localeResult = _getDeviceLocale();
      if (localeResult.isNotEmpty) {
        detectionMethods.add('Locale: $localeResult');
        print('🌍 Locale Result: $localeResult');
        if (detectedCountry == null) {
          detectedCountry = localeResult.split(' ').first;
        }
      }

      // Method 3: Network-based location (Web and Mobile)
      try {
        final networkResult = await _getNetworkLocation();
        if (networkResult != null) {
          detectionMethods.add('Network: ${networkResult['display']}');
          print('🌐 Network Result: ${networkResult['display']}');
          if (detectedCountry == null) {
            detectedCountry = networkResult['country'];
          }
        }
      } catch (e) {
        detectionMethods.add('Network: Failed');
        print('❌ Network Error: $e');
      }

      // Debug: Print final detection
      print('🎯 Final Detection:');
      print('   Country: $detectedCountry');
      print('   City: $detectedCity');
      print('   Locale: $localeResult');
      print('   Methods: $detectionMethods');

      // Determine access
      bool isAllowed = _isLocationAllowed(detectedCountry, localeResult);
      print('✅ Access Allowed: $isAllowed');

      return LocationResult(
        isAllowed: isAllowed,
        country: detectedCountry,
        city: detectedCity,
        detectionMethods: detectionMethods,
        error: error,
      );

    } catch (e) {
      print('💥 General Error: $e');
      return LocationResult(
        isAllowed: false,
        detectionMethods: detectionMethods,
        error: LocationError(
          message: 'An error occurred while checking location: ${e.toString()}',
          type: LocationErrorType.unknown,
        ),
      );
    }
  }

  /// Get GPS location with timeout
  static Future<Map<String, String>?> _getGpsLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationError(
        message: 'Location services are disabled',
        type: LocationErrorType.servicesDisabled,
      );
    }

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationError(
        message: 'Location permission permanently denied',
        type: LocationErrorType.permissionDeniedForever,
      );
    }

    if (permission == LocationPermission.denied) {
      throw LocationError(
        message: 'Location permission denied',
        type: LocationErrorType.permissionDenied,
      );
    }

    // Get position with timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: _gpsTimeout,
    );

    // Reverse geocode
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      return {
        'country': placemark.isoCountryCode ?? '',
        'city': placemark.locality ?? '',
        'display': '${placemark.locality ?? 'Unknown City'}, ${placemark.isoCountryCode ?? 'Unknown Country'}',
      };
    }

    return null;
  }

  /// Get network-based location (lower accuracy, faster)
  static Future<Map<String, String>?> _getNetworkLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: _networkTimeout,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      return {
        'country': placemark.isoCountryCode ?? '',
        'city': placemark.locality ?? '',
        'display': placemark.isoCountryCode ?? 'Unknown Country',
      };
    }

    return null;
  }

  /// Get device locale information
  static String _getDeviceLocale() {
    final locale = window.locale;
    final countryCode = locale.countryCode?.toUpperCase() ?? '';
    final languageCode = locale.languageCode.toUpperCase();
    
    if (countryCode.isNotEmpty) {
      return '$countryCode ($languageCode)';
    }
    
    return '';
  }

  /// Check if location is allowed
  static bool _isLocationAllowed(String? country, String localeInfo) {
    // Debug: Print what we're checking
    print('🔍 Checking location access:');
    print('   Country: $country');
    print('   Target: $_targetCountry');
    print('   Locale: $localeInfo');
    
    if (country == _targetCountry) {
      print('✅ Country match found');
      return true;
    }
    
    // Check locale for Kenya
    if (localeInfo.contains(_targetCountry)) {
      print('✅ Locale match found');
      return true;
    }
    
    // For testing: Allow if locale contains 'KE' (Kenya)
    if (localeInfo.contains('KE')) {
      print('✅ Locale contains KE - allowing access');
      return true;
    }
    
    // TEMPORARY: Allow US for testing purposes
    if (country == 'US' || localeInfo.contains('US')) {
      print('✅ TEMPORARY: Allowing US for testing');
      return true;
    }
    
    print('❌ No match found - access denied');
    return false;
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location permission status
  static Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get location accuracy description
  static String getAccuracyDescription(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return 'Lowest (City level)';
      case LocationAccuracy.low:
        return 'Low (Neighborhood level)';
      case LocationAccuracy.medium:
        return 'Medium (Street level)';
      case LocationAccuracy.high:
        return 'High (Building level)';
      case LocationAccuracy.best:
        return 'Best (Room level)';
      case LocationAccuracy.bestForNavigation:
        return 'Best for Navigation';
      default:
        return 'Unknown';
    }
  }

  /// Get country name from country code
  static String getCountryName(String countryCode) {
    // Add more countries as needed
    final countries = {
      'KE': 'Kenya',
      'US': 'United States',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'DE': 'Germany',
      'FR': 'France',
      'JP': 'Japan',
      'CN': 'China',
      'IN': 'India',
      'BR': 'Brazil',
      'NG': 'Nigeria',
      'ZA': 'South Africa',
      'EG': 'Egypt',
      'GH': 'Ghana',
      'UG': 'Uganda',
      'TZ': 'Tanzania',
      'ET': 'Ethiopia',
    };

    return countries[countryCode.toUpperCase()] ?? countryCode;
  }
} 