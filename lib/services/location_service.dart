import 'package:geolocator/geolocator.dart';

class LocationResult {
  final bool isAllowed;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  LocationResult({
    required this.isAllowed,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });
}

class LocationService {
  // Kenya bounding box
  static const double minLat = -4.7;
  static const double maxLat = 5.1;
  static const double minLon = 33.9;
  static const double maxLon = 41.9;
  static const Duration _gpsTimeout = Duration(seconds: 15);

  /// Main method: Check if user is in Kenya (offline, GPS only)
  static Future<LocationResult> checkLocationAccess() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          isAllowed: false,
          errorMessage: 'Location services are disabled. Please enable GPS.',
        );
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return LocationResult(
          isAllowed: false,
          errorMessage: 'Location permission denied. Please enable GPS permission.',
        );
      }

      // Get position with high accuracy and timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _gpsTimeout,
      );

      final lat = position.latitude;
      final lon = position.longitude;
      final isInKenya = _isWithinKenya(lat, lon);

      return LocationResult(
        isAllowed: isInKenya,
        latitude: lat,
        longitude: lon,
        errorMessage: isInKenya ? null : 'This app is restricted to users within Kenya.',
      );
    } catch (e) {
      return LocationResult(
        isAllowed: false,
        errorMessage: 'Location could not be verified. Please enable GPS or Turn on Location Services',
      );
    }
  }

  /// Kenya bounding box check
  static bool _isWithinKenya(double lat, double lon) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
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
} 