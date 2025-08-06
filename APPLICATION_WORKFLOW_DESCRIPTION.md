# Gate of Memory - Application Workflow Description

## Application Overview
**Gate of Memory** is an offline Android application that provides access to memorial content through QR/barcode scanning, with access restricted to users located within Kenya.

## How the Application Works

### 1. **App Launch & Location Verification**
- User opens the app
- App automatically checks if user is located within Kenya using GPS
- If outside Kenya: Access denied with clear message
- If inside Kenya: App proceeds to main screen

### 2. **Main Screen (Start Screen)**
- Displays app title "Gate Of Memory"
- Shows a QR code with identifier "GATE-OF-MEMORY-QR"
- Provides "Scan QR/Barcode" button to access scanning functionality

### 3. **QR/Barcode Scanning Process**
- User taps "Scan QR/Barcode" button
- App requests camera permission (if not already granted)
- Camera opens with live feed and scanning overlay
- User aligns QR code or barcode within the scanning frame
- ML Kit processes the camera feed in real-time
- When a valid code is detected:
  - Success notification appears
  - App automatically navigates to the Gate Screen

### 4. **Content Access (Gate Screen)**
- After successful scan, user enters the memorial content area
- Displays memorial information and media content
- Provides access to various memorial features

### 5. **Museum Screen**
- Shows memorial images and content
- Displays memorial card and related media
- Provides immersive memorial experience

## Key Features

### **Offline Operation**
- App works completely without internet connection
- All content and functionality available offline
- No network requests or dependencies

### **Location-Based Access Control**
- GPS-based location detection
- Automatic verification of Kenya location
- Clear feedback for access denied scenarios
- Retry and settings access options

### **QR/Barcode Scanning**
- Real-time camera scanning using ML Kit
- Supports multiple barcode formats
- Flashlight control for low-light conditions
- Visual feedback and success notifications

### **User Experience**
- Clean, intuitive interface
- Clear error messages and guidance
- Smooth navigation between screens
- Professional memorial presentation

## Technical Flow

```
App Launch
    ↓
Location Check (GPS)
    ↓
Inside Kenya? → No → Access Denied
    ↓ Yes
Main Screen
    ↓
Scan QR/Barcode
    ↓
Camera Permission
    ↓
Live Scanning (ML Kit)
    ↓
Code Detected
    ↓
Success Notification
    ↓
Gate Screen (Content Access)
    ↓
Museum Screen (Memorial Content)
```

## User Journey Summary

1. **Download & Install**: User installs the APK on Android device
2. **Location Verification**: App checks if user is in Kenya
3. **Access Granted**: If in Kenya, user sees main screen
4. **Scan Process**: User scans memorial QR code or barcode
5. **Content Access**: User gains access to memorial content
6. **Memorial Experience**: User explores memorial information and media

## Security & Access Control

- **Geographic Restriction**: Only users in Kenya can access the app
- **Permission Management**: Proper handling of location and camera permissions
- **Offline Security**: No network vulnerabilities
- **Content Protection**: Memorial content only accessible through valid QR codes

## Target Use Case

The application is designed for memorial sites and museums in Kenya, allowing visitors to:
- Scan QR codes at memorial locations
- Access detailed memorial information
- View memorial media content
- Experience memorials in an interactive, offline manner

**The app provides a secure, offline, location-restricted platform for memorial content access through modern QR/barcode scanning technology.** 