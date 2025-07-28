import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationSettingsScreen extends StatefulWidget {
  @override
  _LocationSettingsScreenState createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _isLoading = true;
  bool _locationServicesEnabled = false;
  LocationPermission _permissionStatus = LocationPermission.denied;
  String? _currentLocation;
  String? _currentCountry;

  @override
  void initState() {
    super.initState();
    _loadLocationStatus();
  }

  Future<void> _loadLocationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location services
      _locationServicesEnabled = await LocationService.isLocationServiceEnabled();
      
      // Check permission status
      _permissionStatus = await LocationService.getLocationPermission();
      
      // Try to get current location if permitted
      if (_permissionStatus == LocationPermission.whileInUse || 
          _permissionStatus == LocationPermission.always) {
        try {
          final result = await LocationService.checkLocationAccess();
          _currentLocation = result.city;
          _currentCountry = result.country;
        } catch (e) {
          // Location fetch failed, but that's okay
        }
      }
    } catch (e) {
      // Handle errors
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    try {
      final permission = await LocationService.requestLocationPermission();
      setState(() {
        _permissionStatus = permission;
      });
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        await _loadLocationStatus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request location permission'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      await LocationService.openLocationSettings();
      // Reload status after returning from settings
      await _loadLocationStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open location settings'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _getPermissionStatusText() {
    switch (_permissionStatus) {
      case LocationPermission.denied:
        return 'Location permission is denied';
      case LocationPermission.deniedForever:
        return 'Location permission is permanently denied';
      case LocationPermission.whileInUse:
        return 'Location permission granted (while in use)';
      case LocationPermission.always:
        return 'Location permission granted (always)';
      default:
        return 'Unknown permission status';
    }
  }

  Color _getPermissionStatusColor() {
    switch (_permissionStatus) {
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
        return Colors.red;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPermissionStatusIcon() {
    switch (_permissionStatus) {
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
        return Icons.location_off;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return Icons.location_on;
      default:
        return Icons.location_disabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Settings'),
        backgroundColor: Color(0xFF7bb6e7),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLocationStatus,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7bb6e7)))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Services Status
                    _buildStatusCard(
                      title: 'Location Services',
                      subtitle: _locationServicesEnabled ? 'Enabled' : 'Disabled',
                      icon: _locationServicesEnabled ? Icons.location_on : Icons.location_off,
                      color: _locationServicesEnabled ? Colors.green : Colors.red,
                      action: _locationServicesEnabled ? null : _openLocationSettings,
                      actionText: 'Enable',
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Permission Status
                    _buildStatusCard(
                      title: 'Location Permission',
                      subtitle: _getPermissionStatusText(),
                      icon: _getPermissionStatusIcon(),
                      color: _getPermissionStatusColor(),
                      action: _permissionStatus == LocationPermission.denied 
                          ? _requestPermission 
                          : _permissionStatus == LocationPermission.deniedForever 
                              ? _openLocationSettings 
                              : null,
                      actionText: _permissionStatus == LocationPermission.denied 
                          ? 'Grant Permission' 
                          : _permissionStatus == LocationPermission.deniedForever 
                              ? 'Open Settings' 
                              : null,
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Current Location (if available)
                    if (_currentLocation != null && _currentCountry != null)
                      _buildStatusCard(
                        title: 'Current Location',
                        subtitle: '$_currentLocation, ${LocationService.getCountryName(_currentCountry!)}',
                        icon: Icons.my_location,
                        color: Colors.blue,
                        action: null,
                        actionText: null,
                      ),
                    
                    SizedBox(height: 32),
                    
                    // Information Section
                    _buildInfoSection(),
                    
                    SizedBox(height: 32),
                    
                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? action,
    String? actionText,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2d3a4a),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4a5a6a),
                    ),
                  ),
                ],
              ),
            ),
            if (action != null && actionText != null)
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7bb6e7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(actionText),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF7bb6e7)),
                SizedBox(width: 8),
                Text(
                  'Why does this app need location?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3a4a),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'This app is designed for memorial services in Kenya and requires location access to ensure it\'s used appropriately within the intended region.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4a5a6a),
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFf8f9fa),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFe9ecef)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Detection Methods:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2d3a4a),
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildMethodItem('GPS Location', 'Most accurate method'),
                  _buildMethodItem('Network Location', 'Uses mobile network'),
                  _buildMethodItem('Device Locale', 'Uses device settings'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2d3a4a),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6c757d),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openLocationSettings,
            icon: Icon(Icons.settings),
            label: Text('Open Device Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7bb6e7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadLocationStatus,
            icon: Icon(Icons.refresh),
            label: Text('Refresh Status'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF7bb6e7),
              side: BorderSide(color: Color(0xFF7bb6e7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}