import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GeoBlocker extends StatefulWidget {
  final Widget child;
  const GeoBlocker({Key? key, required this.child}) : super(key: key);

  @override
  State<GeoBlocker> createState() => _GeoBlockerState();
}

class _GeoBlockerState extends State<GeoBlocker> {
  bool? _allowed;
  String? _fallbackMessage;
  String? _detectedCountry;
  bool _isLoading = true;
  bool _isRetrying = false;
  LocationStatus _locationStatus = LocationStatus.checking;
  List<String> _locationMethods = [];

  @override
  void initState() {
    super.initState();
    _checkGeoBlocking();
  }

  Future<void> _checkGeoBlocking() async {
    setState(() {
      _isLoading = true;
      _locationStatus = LocationStatus.checking;
      _locationMethods.clear();
    });

    try {
      final result = await LocationService.checkLocationAccess();
      
      setState(() {
        _allowed = result.isAllowed;
        _detectedCountry = result.latitude != null && result.longitude != null
          ? 'Lat: ${result.latitude!.toStringAsFixed(4)}, Lon: ${result.longitude!.toStringAsFixed(4)}'
          : null;
        _locationMethods = [];
        _isLoading = false;
        
        if (result.isAllowed) {
          _locationStatus = LocationStatus.allowed;
        } else if (result.errorMessage != null) {
          _locationStatus = LocationStatus.error;
          _fallbackMessage = result.errorMessage;
        } else {
          _locationStatus = LocationStatus.unavailable;
          _fallbackMessage = 'Location could not be verified. Please enable GPS or connect to a network in Kenya.';
        }
      });
    } catch (e) {
      setState(() {
        _locationStatus = LocationStatus.error;
        _fallbackMessage = 'An error occurred while checking your location. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _retryLocationCheck() async {
    setState(() {
      _isRetrying = true;
    });
    
    await _checkGeoBlocking();
    
    setState(() {
      _isRetrying = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _GeoBlockerScaffold(
        child: _LoadingView(),
      );
    } else if (_allowed == true) {
      return widget.child;
    } else if (_locationStatus == LocationStatus.unavailable || _fallbackMessage != null) {
      return _GeoBlockerScaffold(
        child: _GeoBlockerDialog(
          title: 'Location could not be verified',
          message: _fallbackMessage!,
          buttonText: 'Retry',
          secondaryButtonText: 'Location Settings',
          onButton: _retryLocationCheck,
          onSecondaryButton: () {
            // For location settings, we'll just retry the location check
            // since we can't navigate from this context
            _retryLocationCheck();
          },
          isRetrying: _isRetrying,
        ),
      );
    } else {
      String countryMsg = _detectedCountry != null && _detectedCountry!.isNotEmpty
        ? 'Your coordinates: ${_detectedCountry!}. This app is restricted to users within Kenya.'
        : 'This app is restricted to users within Kenya.';
      
      return _GeoBlockerScaffold(
        child: _GeoBlockerDialog(
          title: 'Access Denied',
          message: countryMsg,
          buttonText: 'Exit',
          secondaryButtonText: 'Retry',
          onButton: () async {
            if (kIsWeb) {
              // On web, just retry since we can't show dialogs from this context
              _retryLocationCheck();
            } else {
              // On mobile/desktop, close the app
              await SystemNavigator.pop();
            }
          },
          onSecondaryButton: _retryLocationCheck,
          isRetrying: _isRetrying,
          showLocationMethods: true,
          locationMethods: _locationMethods,
        ),
      );
    }
  }
}

enum LocationStatus {
  checking,
  allowed,
  blocked,
  unavailable,
  error,
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.location_searching,
              size: 40,
              color: Color(0xFF7bb6e7),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Verifying your location...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d3a4a),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Please ensure location services are enabled',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4a5a6a),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          CircularProgressIndicator(
            color: Color(0xFF7bb6e7),
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }
}

class _GeoBlockerScaffold extends StatelessWidget {
  final Widget child;
  const _GeoBlockerScaffold({required this.child});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
      ),
    );
  }
}

class _GeoBlockerDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final String? secondaryButtonText;
  final VoidCallback onButton;
  final VoidCallback? onSecondaryButton;
  final bool isRetrying;
  final bool showLocationMethods;
  final List<String> locationMethods;

  const _GeoBlockerDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.secondaryButtonText,
    required this.onButton,
    this.onSecondaryButton,
    this.isRetrying = false,
    this.showLocationMethods = false,
    this.locationMethods = const [],
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              title.contains('Denied') ? Icons.location_off : Icons.location_on,
              color: Color(0xFF7bb6e7),
              size: 48,
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3a4a),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4a5a6a),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            if (secondaryButtonText != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isRetrying ? null : onSecondaryButton,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF7bb6e7),
                    side: BorderSide(color: Color(0xFF7bb6e7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(secondaryButtonText!),
                ),
              ),
              SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isRetrying ? null : onButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7bb6e7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: isRetrying
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 