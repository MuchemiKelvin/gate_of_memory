import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui';

class GeoBlocker extends StatefulWidget {
  final Widget child;
  const GeoBlocker({required this.child});

  @override
  State<GeoBlocker> createState() => _GeoBlockerState();
}

class _GeoBlockerState extends State<GeoBlocker> {
  bool? _allowed;
  String? _fallbackMessage;
  String? _detectedCountry;

  @override
  void initState() {
    super.initState();
    _checkGeoBlocking();
  }

  Future<void> _checkGeoBlocking() async {
    bool allowed = false;
    String? fallback;
    String? countryForMessage;
    try {
      // 1. GPS Country
      String? gpsCountry;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        LocationPermission permission = await Geolocator.checkPermission();
        if (!serviceEnabled || permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          gpsCountry = placemarks.first.isoCountryCode;
        }
      } catch (_) {}

      // 2. Device Locale
      String localeCountry = window.locale.countryCode?.toUpperCase() ?? '';

      // Prefer GPS, then locale for message
      countryForMessage = gpsCountry ?? localeCountry;

      // Allow if any check passes
      if (gpsCountry == 'KE' || localeCountry == 'KE') {
        allowed = true;
      } else if (gpsCountry == null && localeCountry.isEmpty) {
        fallback = 'Location could not be verified. Please enable GPS or connect to a network in Kenya.';
      }
    } catch (e) {
      fallback = 'Location could not be verified. Please enable GPS or connect to a network in Kenya.';
    }
    setState(() {
      _allowed = allowed;
      _fallbackMessage = fallback;
      _detectedCountry = countryForMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed == null) {
      return _GeoBlockerScaffold(
        child: Center(child: CircularProgressIndicator(color: Color(0xFF7bb6e7))),
      );
    } else if (_allowed == true) {
      return widget.child;
    } else if (_fallbackMessage != null) {
      return _GeoBlockerScaffold(
        child: _GeoBlockerDialog(
          title: 'Location could not be verified',
          message: _fallbackMessage!,
          buttonText: 'OK',
          onButton: () => Navigator.of(context).pop(),
        ),
      );
    } else {
      String countryMsg = _detectedCountry != null && _detectedCountry!.isNotEmpty
        ? 'You are currently in ${_detectedCountry!}. This app is restricted to users within Kenya.'
        : 'This app is restricted to users within Kenya.';
      return _GeoBlockerScaffold(
        child: _GeoBlockerDialog(
          title: 'Access Denied',
          message: countryMsg,
          buttonText: 'Exit',
          onButton: () => Navigator.of(context).pop(),
        ),
      );
    }
  }
}

class _GeoBlockerScaffold extends StatelessWidget {
  final Widget child;
  const _GeoBlockerScaffold({required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFeaf3fa),
              Color(0xFFc7e0f5),
              Color(0xFF7bb6e7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _GeoBlockerDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButton;
  const _GeoBlockerDialog({required this.title, required this.message, required this.buttonText, required this.onButton});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white.withOpacity(0.97),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, color: Color(0xFF7bb6e7), size: 48),
              SizedBox(height: 24),
              Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2d3a4a)), textAlign: TextAlign.center),
              SizedBox(height: 16),
              Text(message, style: TextStyle(fontSize: 16, color: Color(0xFF4a5a6a)), textAlign: TextAlign.center),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: onButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7bb6e7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(buttonText, style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 