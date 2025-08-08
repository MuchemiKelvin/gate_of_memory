import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';

class HologramPlayerFullscreenPage extends StatefulWidget {
  final String hologramPath;
  final String title;
  const HologramPlayerFullscreenPage({required this.hologramPath, required this.title});

  @override
  State<HologramPlayerFullscreenPage> createState() => _HologramPlayerFullscreenPageState();
}

class _HologramPlayerFullscreenPageState extends State<HologramPlayerFullscreenPage> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Hologram-specific features
  double _rotationAngle = 0.0;
  double _zoomLevel = 1.0;
  bool _autoRotate = false;
  double _rotationSpeed = 1.0;
  bool _isLooping = false;
  String _hologramInfo = '';
  
  // Advanced positioning features
  Offset _position = Offset.zero;
  bool _isDragging = false;
  List<Offset> _savedPositions = [];
  int _currentPreset = 0;
  
  // Interaction features
  bool _isInteracting = false;
  String _interactionMessage = '';
  int _tapCount = 0;
  
  // Metadata features
  Map<String, dynamic> _hologramMetadata = {};
  bool _showMetadata = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeHologramPlayer();
    });
  }

  Future<void> _initializeHologramPlayer() async {
    try {
      print('Initializing hologram player with path: ${widget.hologramPath}');
      
      // Clean the hologram path
      String cleanPath = widget.hologramPath;
      if (cleanPath.startsWith('assets/assets/')) {
        cleanPath = cleanPath.replaceFirst('assets/assets/', 'assets/');
        print('Fixed path from ${widget.hologramPath} to $cleanPath');
      }
      
      // Check if we're on Windows and provide a fallback
      if (Platform.isWindows) {
        print('Running on Windows - using fallback hologram player');
        setState(() {
          _hasError = true;
          _errorMessage = 'Hologram playback is not supported on Windows yet. Hologram path: ${widget.hologramPath}';
        });
        return;
      }
      
      _controller = VideoPlayerController.asset(cleanPath);
      
      await _controller!.initialize();
      print('Hologram controller initialized successfully');
      
      // Set up listeners
      _controller!.addListener(() {
        setState(() {
          _updateHologramInfo();
        });
      });
      
      setState(() {
        _isInitialized = true;
        _updateHologramInfo();
      });
      print('Hologram player initialized successfully');
      
      // Auto-start hologram for testing
      await _autoStartHologram();
      
    } catch (e) {
      print('Error initializing hologram player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load hologram: $e';
      });
    }
  }

  void _updateHologramInfo() {
    final fileName = widget.hologramPath.split('/').last;
    final nameWithoutExtension = fileName.split('.').first;
    final readableTitle = nameWithoutExtension
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    
    setState(() {
      _hologramInfo = '${readableTitle}\nHologram • 360° View • ${_getFileSize()}';
    });
  }

  String _getFileSize() {
    // Estimate file size based on duration (rough estimate)
    final sizeInMB = (_controller?.value.duration.inSeconds ?? 0 * 0.256).toStringAsFixed(1); // 256kbps estimate
    return '${sizeInMB} MB';
  }

  Future<void> _autoStartHologram() async {
    if (_controller == null || !_isInitialized) return;
    
    try {
      print('Auto-starting hologram...');
      _controller!.play();
      setState(() {
        _isPlaying = true;
      });
      print('Hologram auto-started successfully');
    } catch (e) {
      print('Error auto-starting hologram: $e');
    }
  }

  void _restartHologram() async {
    if (_controller == null || !_isInitialized) return;
    
    try {
      print('Restarting hologram...');
      
      // Method 1: Try to reload the hologram source
      try {
        String cleanPath = widget.hologramPath;
        if (cleanPath.startsWith('assets/assets/')) {
          cleanPath = cleanPath.replaceFirst('assets/assets/', 'assets/');
        }
        
        await _controller!.dispose();
        _controller = VideoPlayerController.asset(cleanPath);
        await _controller!.initialize();
        _controller!.play();
        
        setState(() {
          _isPlaying = true;
        });
        print('Hologram restarted by reloading source');
      } catch (e) {
        print('Reload source failed: $e');
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      print('Error restarting hologram: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_controller == null || !_isInitialized) return;
    
    try {
      if (_isPlaying) {
        print('Pausing hologram...');
        _controller!.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        print('Starting/Resuming hologram...');
        _controller!.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('Error in toggle play/pause: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _rotateLeft() {
    setState(() {
      _rotationAngle -= 15.0;
      if (_rotationAngle < 0) _rotationAngle += 360.0;
    });
    print('Rotated left: $_rotationAngle°');
  }

  void _rotateRight() {
    setState(() {
      _rotationAngle += 15.0;
      if (_rotationAngle >= 360.0) _rotationAngle -= 360.0;
    });
    print('Rotated right: $_rotationAngle°');
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 3.0);
    });
    print('Zoomed in: ${_zoomLevel.toStringAsFixed(1)}x');
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 3.0);
    });
    print('Zoomed out: ${_zoomLevel.toStringAsFixed(1)}x');
  }

  void _resetView() {
    setState(() {
      _rotationAngle = 0.0;
      _zoomLevel = 1.0;
    });
    print('View reset');
  }

  void _toggleAutoRotate() {
    setState(() {
      _autoRotate = !_autoRotate;
    });
    print('Auto-rotate: ${_autoRotate ? 'ON' : 'OFF'}');
    
    if (_autoRotate) {
      _startAutoRotation();
    }
  }

  void _startAutoRotation() {
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!_autoRotate || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _rotationAngle += _rotationSpeed;
        if (_rotationAngle >= 360.0) _rotationAngle -= 360.0;
      });
    });
  }

  void _setRotationSpeed(double speed) {
    setState(() {
      _rotationSpeed = speed;
    });
    print('Rotation speed set to: ${speed.toStringAsFixed(1)}x');
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
    print('Loop mode: ${_isLooping ? 'ON' : 'OFF'}');
  }

  // Advanced positioning methods
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    print('Started dragging hologram');
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      // Limit movement to reasonable bounds
      _position = Offset(
        _position.dx.clamp(-100.0, 100.0),
        _position.dy.clamp(-100.0, 100.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    print('Stopped dragging hologram at position: $_position');
  }

  void _saveCurrentPosition() {
    setState(() {
      _savedPositions.add(_position);
    });
    print('Saved position: $_position (Total saved: ${_savedPositions.length})');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Position saved!')),
    );
  }

  void _loadSavedPosition(int index) {
    if (index < _savedPositions.length) {
      setState(() {
        _position = _savedPositions[index];
        _currentPreset = index;
      });
      print('Loaded position $index: $_position');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Position $index loaded!')),
      );
    }
  }

  void _clearSavedPositions() {
    setState(() {
      _savedPositions.clear();
      _currentPreset = 0;
    });
    print('Cleared all saved positions');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All positions cleared!')),
    );
  }

  void _resetPosition() {
    setState(() {
      _position = Offset.zero;
      _currentPreset = 0;
    });
    print('Position reset to center');
  }

  // Interaction methods
  void _onTap() {
    setState(() {
      _tapCount++;
      _isInteracting = true;
      _interactionMessage = 'Tap detected!';
    });
    print('Hologram tapped! Count: $_tapCount');
    
    // Auto-hide interaction message
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isInteracting = false;
          _interactionMessage = '';
        });
      }
    });
  }

  void _onDoubleTap() {
    setState(() {
      _isInteracting = true;
      _interactionMessage = 'Double tap - Reset view!';
      _resetView();
      _resetPosition();
    });
    print('Hologram double-tapped - Reset view');
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isInteracting = false;
          _interactionMessage = '';
        });
      }
    });
  }

  void _onLongPress() {
    setState(() {
      _isInteracting = true;
      _interactionMessage = 'Long press - Save position!';
      _saveCurrentPosition();
    });
    print('Hologram long-pressed - Save position');
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isInteracting = false;
          _interactionMessage = '';
        });
      }
    });
  }

  // Metadata methods
  void _generateMetadata() {
    final fileName = widget.hologramPath.split('/').last;
    final fileSize = _getFileSize();
    final duration = _controller?.value.duration ?? Duration.zero;
    final currentPosition = _controller?.value.position ?? Duration.zero;
    
    setState(() {
      _hologramMetadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'duration': _formatDuration(duration),
        'currentPosition': _formatDuration(currentPosition),
        'rotationAngle': '${_rotationAngle.toStringAsFixed(1)}°',
        'zoomLevel': '${_zoomLevel.toStringAsFixed(1)}x',
        'position': 'X: ${_position.dx.toStringAsFixed(1)}, Y: ${_position.dy.toStringAsFixed(1)}',
        'autoRotate': _autoRotate ? 'ON' : 'OFF',
        'rotationSpeed': '${_rotationSpeed.toStringAsFixed(1)}x',
        'isLooping': _isLooping ? 'ON' : 'OFF',
        'isPlaying': _isPlaying ? 'YES' : 'NO',
        'savedPositions': _savedPositions.length,
        'tapCount': _tapCount,
        'playbackProgress': '${((currentPosition.inMilliseconds / duration.inMilliseconds) * 100).toStringAsFixed(1)}%',
        'fileType': 'Hologram Video (MP4)',
        'resolution': '360° View',
        'createdAt': DateTime.now().toString(),
      };
    });
  }

  void _toggleMetadata() {
    setState(() {
      _showMetadata = !_showMetadata;
      if (_showMetadata) {
        _generateMetadata();
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a2a3a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hologram Viewer',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showMetadata ? Icons.info : Icons.info_outline,
              color: Colors.white,
            ),
            onPressed: _toggleMetadata,
            tooltip: 'Show/Hide Metadata',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1a2a3a),
              Color(0xFF2d3a4a),
              Color(0xFF1a2a3a),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _hasError
            ? _buildErrorWidget()
            : _isInitialized
                ? _buildHologramPlayer()
                : _buildLoadingWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_in_ar,
            size: 80,
            color: Colors.white54,
          ),
          SizedBox(height: 20),
          Text(
            'Hologram Not Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = '';
              });
              _initializeHologramPlayer();
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7bb6e7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHologramPlayer() {
    return Column(
      children: [
        // Hologram Info Display
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _hologramInfo.split('\n')[0], // Title
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                _hologramInfo.split('\n')[1], // Info
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Hologram Display Area
        Expanded(
          child: Center(
            child: Stack(
              children: [
                GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onTap: _onTap,
                  onDoubleTap: _onDoubleTap,
                  onLongPress: _onLongPress,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Transform.translate(
                        offset: _position,
                        child: Transform.rotate(
                          angle: _rotationAngle * 3.14159 / 180,
                          child: Transform.scale(
                            scale: _zoomLevel,
                            child: _controller != null
                                ? VideoPlayer(_controller!)
                                : Container(
                                    color: Colors.black,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF7bb6e7),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Interaction Feedback Overlay
                if (_isInteracting)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color(0xFF7bb6e7).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _interactionMessage,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                // Tap Counter
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Taps: $_tapCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Metadata Overlay
                if (_showMetadata)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF7bb6e7), width: 2),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hologram Metadata',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white),
                                  onPressed: _toggleMetadata,
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ..._hologramMetadata.entries.map((entry) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '${entry.key}:',
                                      style: TextStyle(
                                        color: Color(0xFF7bb6e7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Hologram Controls
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Rotation Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.rotate_left, color: Colors.white, size: 28),
                    onPressed: _rotateLeft,
                    tooltip: 'Rotate Left',
                  ),
                  IconButton(
                    icon: Icon(
                      _autoRotate ? Icons.pause_circle : Icons.play_circle,
                      color: _autoRotate ? Color(0xFF7bb6e7) : Colors.white,
                      size: 32,
                    ),
                    onPressed: _toggleAutoRotate,
                    tooltip: 'Auto Rotate',
                  ),
                  IconButton(
                    icon: Icon(Icons.rotate_right, color: Colors.white, size: 28),
                    onPressed: _rotateRight,
                    tooltip: 'Rotate Right',
                  ),
                ],
              ),
              
              // Zoom Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.zoom_out, color: Colors.white, size: 28),
                    onPressed: _zoomOut,
                    tooltip: 'Zoom Out',
                  ),
                  IconButton(
                    icon: Icon(Icons.center_focus_strong, color: Colors.white, size: 28),
                    onPressed: _resetView,
                    tooltip: 'Reset View',
                  ),
                  IconButton(
                    icon: Icon(Icons.zoom_in, color: Colors.white, size: 28),
                    onPressed: _zoomIn,
                    tooltip: 'Zoom In',
                  ),
                ],
              ),
              
              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: _togglePlayPause,
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                  ),
                  IconButton(
                    icon: Icon(
                      _isLooping ? Icons.repeat_one : Icons.repeat,
                      color: _isLooping ? Color(0xFF7bb6e7) : Colors.white,
                      size: 24,
                    ),
                    onPressed: _toggleLoop,
                    tooltip: 'Loop: ${_isLooping ? 'ON' : 'OFF'}',
                  ),
                ],
              ),
              
              // Positioning Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.save, color: Colors.white, size: 24),
                    onPressed: _saveCurrentPosition,
                    tooltip: 'Save Position',
                  ),
                  IconButton(
                    icon: Icon(Icons.center_focus_strong, color: Colors.white, size: 24),
                    onPressed: _resetPosition,
                    tooltip: 'Reset Position',
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.white, size: 24),
                    onPressed: _clearSavedPositions,
                    tooltip: 'Clear Saved Positions',
                  ),
                ],
              ),
              
              // Position Presets
              if (_savedPositions.isNotEmpty)
                Container(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedPositions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () => _loadSavedPosition(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPreset == index 
                                ? Color(0xFF7bb6e7) 
                                : Colors.white24,
                            foregroundColor: Colors.white,
                            minimumSize: Size(60, 30),
                          ),
                          child: Text('P${index + 1}'),
                        ),
                      );
                    },
                  ),
                ),
              
              // Rotation Speed Control
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Speed:', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Slider(
                        value: _rotationSpeed,
                        min: 0.5,
                        max: 3.0,
                        divisions: 5,
                        onChanged: _setRotationSpeed,
                        activeColor: Color(0xFF7bb6e7),
                        inactiveColor: Colors.white24,
                      ),
                    ),
                    Text(
                      '${_rotationSpeed.toStringAsFixed(1)}x',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              // Progress Bar
              if (_controller != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Slider(
                        value: _controller!.value.position.inMilliseconds.toDouble(),
                        min: 0,
                        max: _controller!.value.duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          // Note: Seek functionality may not work on all platforms
                          print('Seek to: ${value.toInt()}ms');
                        },
                        activeColor: Color(0xFF7bb6e7),
                        inactiveColor: Colors.white24,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_controller!.value.position),
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Color(0xFF7bb6e7)),
        SizedBox(height: 20),
        Text(
          'Loading hologram...',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          widget.hologramPath,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 