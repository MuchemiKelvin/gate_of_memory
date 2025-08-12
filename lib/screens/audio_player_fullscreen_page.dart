import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:async';

class AudioPlayerFullscreenPage extends StatefulWidget {
  final String audioPath;
  final String title;
  const AudioPlayerFullscreenPage({required this.audioPath, required this.title});

  @override
  State<AudioPlayerFullscreenPage> createState() => _AudioPlayerFullscreenPageState();
}

class _AudioPlayerFullscreenPageState extends State<AudioPlayerFullscreenPage> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration(minutes: 2, seconds: 30);
  Duration _position = Duration.zero;
  bool _isLoaded = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // New features
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _isLooping = false;
  String _audioInfo = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAudioPlayer();
    });
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      print('Initializing audio player with path: ${widget.audioPath}');
      
      // Clean the audio path to ensure it's correct
      String cleanPath = widget.audioPath;
      if (cleanPath.startsWith('assets/assets/')) {
        cleanPath = cleanPath.replaceFirst('assets/assets/', 'assets/');
        print('Fixed path from ${widget.audioPath} to $cleanPath');
      }
      
      // Verify asset exists
      try {
        final assetBundle = DefaultAssetBundle.of(context);
        final manifestContent = await assetBundle.loadString('AssetManifest.json');
        final manifest = Map<String, dynamic>.from(json.decode(manifestContent));
        
        if (!manifest.containsKey(cleanPath)) {
          print('ERROR: Asset not found in manifest: $cleanPath');
          print('Available audio assets: ${manifest.keys.where((key) => key.startsWith('assets/audio/')).toList()}');
          setState(() {
            _hasError = true;
            _errorMessage = 'Audio file not found: $cleanPath';
          });
          return;
        }
        print('Asset found in manifest: $cleanPath');
      } catch (e) {
        print('Error checking asset manifest: $e');
      }
      
      _audioPlayer = AudioPlayer();
      
      // Try different methods to load the audio
      bool audioLoaded = false;
      
      try {
        // Method 1: Try with setSourceAsset (the standard way)
        await _audioPlayer!.setSourceAsset(cleanPath);
        print('Audio source set successfully with setSourceAsset');
        audioLoaded = true;
      } catch (e) {
        print('setSourceAsset failed: $e');
        
        try {
          // Method 2: Try with setSource using asset bundle
          final assetBundle = DefaultAssetBundle.of(context);
          final audioData = await assetBundle.load(cleanPath);
          await _audioPlayer!.setSourceBytes(audioData.buffer.asUint8List());
          print('Audio source set successfully with setSourceBytes');
          audioLoaded = true;
        } catch (e2) {
          print('setSourceBytes failed: $e2');
          
          try {
            // Method 3: Try with just the filename (without assets/ prefix)
            final fileName = cleanPath.split('/').last;
            await _audioPlayer!.setSourceAsset(fileName);
            print('Audio source set successfully with filename only');
            audioLoaded = true;
          } catch (e3) {
            print('All audio loading methods failed');
            throw e3;
          }
        }
      }
      
      if (!audioLoaded) {
        throw Exception('Failed to load audio source');
      }
      
      // Set up listeners
      _audioPlayer!.onDurationChanged.listen((d) {
        print('Duration changed: $d');
        setState(() {
          _duration = d;
          _updateAudioInfo();
        });
      });
      
      _audioPlayer!.onPositionChanged.listen((p) {
        setState(() {
          _position = p;
        });
      });
      
      _audioPlayer!.onPlayerComplete.listen((event) {
        print('Audio playback completed');
        if (_isLooping) {
          // Restart the audio if looping is enabled
          print('Looping enabled - restarting audio');
          _restartAudio();
        } else {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
          print('Audio completed - not looping');
        }
      });
      
      // Wait a moment for the audio to initialize properly
      await Future.delayed(Duration(milliseconds: 500));
      
      setState(() {
        _isLoaded = true;
        _updateAudioInfo();
      });
      print('Audio player initialized successfully');
      
      // Try to get initial duration
      try {
        final duration = await _audioPlayer!.getDuration();
        if (duration != null && duration.inMilliseconds > 0) {
          print('Initial duration: $duration');
          setState(() {
            _duration = duration;
            _updateAudioInfo();
          });
        }
      } catch (e) {
        print('Error getting initial duration: $e');
      }
      
      // Auto-start audio for testing
      await _autoStartAudio();
      
    } catch (e) {
      print('Error initializing audio player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load audio: $e';
      });
    }
  }

  Future<void> _autoStartAudio() async {
    if (_audioPlayer == null || !_isLoaded) return;
    
    try {
      print('Auto-starting audio...');
      await _audioPlayer!.resume();
      setState(() {
        _isPlaying = true;
      });
      print('Audio auto-started successfully');
    } catch (e) {
      print('Error auto-starting audio: $e');
    }
  }

  void _updateAudioInfo() {
    final fileName = widget.audioPath.split('/').last;
    final nameWithoutExtension = fileName.split('.').first;
    final readableTitle = nameWithoutExtension
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    
    setState(() {
      _audioInfo = '${readableTitle}\n${_formatDuration(_duration)} • ${_getFileSize()}';
    });
  }

  String _getAudioTitle() {
    final fileName = widget.audioPath.split('/').last;
    final nameWithoutExtension = fileName.split('.').first;
    return nameWithoutExtension
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  String _getAudioSubtitle() {
    return '${_formatDuration(_duration)} • ${_getFileSize()}';
  }

  String _getFileSize() {
    // Estimate file size based on duration (rough estimate)
    final sizeInMB = (_duration.inSeconds * 0.128).toStringAsFixed(1); // 128kbps estimate
    return '${sizeInMB} MB';
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_audioPlayer == null || !_isLoaded) return;
    
    try {
      if (_isPlaying) {
        print('Pausing audio...');
        await _audioPlayer!.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        print('Starting/Resuming audio...');
        
        // Check if we need to start from beginning
        if (_position.inMilliseconds == 0) {
          print('Starting audio from beginning');
          await _audioPlayer!.resume();
        } else {
          print('Resuming audio from position: $_position');
          await _audioPlayer!.resume();
        }
        
        setState(() {
          _isPlaying = true;
        });
        
        // Verify playback started
        await Future.delayed(Duration(milliseconds: 100));
        try {
          final isActuallyPlaying = await _audioPlayer!.getCurrentPosition();
          print('Current position after play: $isActuallyPlaying');
          
          if (isActuallyPlaying == null || isActuallyPlaying.inMilliseconds == 0) {
            print('Audio not actually playing, trying to restart...');
            await _audioPlayer!.resume();
          }
        } catch (e) {
          print('Error checking playback status: $e');
        }
      }
    } catch (e) {
      print('Error in toggle play/pause: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _skipForward() {
    if (_audioPlayer == null || !_isLoaded) return;
    final newPosition = _position + Duration(seconds: 15);
    final maxPosition = _duration;
    _audioPlayer!.seek(newPosition > maxPosition ? maxPosition : newPosition);
  }

  void _skipBackward() {
    if (_audioPlayer == null || !_isLoaded) return;
    final newPosition = _position - Duration(seconds: 15);
    _audioPlayer!.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  void _setPlaybackSpeed(double speed) async {
    if (_audioPlayer == null || !_isLoaded) return;
    
    try {
      await _audioPlayer!.setPlaybackRate(speed);
      setState(() {
        _playbackSpeed = speed;
      });
      print('Playback speed set to ${speed}x');
    } catch (e) {
      print('Error setting playback speed: $e');
    }
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
    print('Loop mode: ${_isLooping ? 'ON' : 'OFF'}');
  }

  void _restartAudio() async {
    if (_audioPlayer == null || !_isLoaded) return;
    
    try {
      print('Restarting audio...');
      
      // Method 1: Try to reload the audio source (more reliable than seek)
      try {
        String cleanPath = widget.audioPath;
        if (cleanPath.startsWith('assets/assets/')) {
          cleanPath = cleanPath.replaceFirst('assets/assets/', 'assets/');
        }
        
        // Stop current playback first
        await _audioPlayer!.stop();
        
        // Reload the audio source
        await _audioPlayer!.setSourceAsset(cleanPath);
        
        // Start playing
        await _audioPlayer!.resume();
        
        setState(() {
          _isPlaying = true;
          _position = Duration.zero;
        });
        print('Audio restarted by reloading source');
      } catch (e) {
        print('Reload source failed: $e');
        
        // Method 2: Try seek with timeout protection
        try {
          await _audioPlayer!.seek(Duration.zero).timeout(
            Duration(seconds: 5),
            onTimeout: () {
              print('Seek operation timed out');
              throw TimeoutException('Seek operation timed out', Duration(seconds: 5));
            },
          );
          
          await _audioPlayer!.resume();
          setState(() {
            _isPlaying = true;
            _position = Duration.zero;
          });
          print('Audio restarted successfully with seek');
        } catch (e2) {
          print('Seek and resume failed: $e2');
          
          // Method 3: Create new audio player instance
          try {
            _audioPlayer?.dispose();
            _audioPlayer = AudioPlayer();
            
            String cleanPath = widget.audioPath;
            if (cleanPath.startsWith('assets/assets/')) {
              cleanPath = cleanPath.replaceFirst('assets/assets/', 'assets/');
            }
            
            await _audioPlayer!.setSourceAsset(cleanPath);
            await _audioPlayer!.resume();
            
            // Re-setup listeners
            _audioPlayer!.onDurationChanged.listen((d) {
              print('Duration changed: $d');
              setState(() {
                _duration = d;
                _updateAudioInfo();
              });
            });
            
            _audioPlayer!.onPositionChanged.listen((p) {
              setState(() {
                _position = p;
              });
            });
            
            _audioPlayer!.onPlayerComplete.listen((event) {
              print('Audio playback completed');
              if (_isLooping) {
                print('Looping enabled - restarting audio');
                _restartAudio();
              } else {
                setState(() {
                  _isPlaying = false;
                  _position = Duration.zero;
                });
                print('Audio completed - not looping');
              }
            });
            
            setState(() {
              _isPlaying = true;
              _position = Duration.zero;
            });
            print('Audio restarted with new player instance');
          } catch (e3) {
            print('New player instance failed: $e3');
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          }
        }
      }
    } catch (e) {
      print('Error restarting audio: $e');
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    }
  }

  void _setVolume(double volume) async {
    if (_audioPlayer == null || !_isLoaded) return;
    
    try {
      await _audioPlayer!.setVolume(volume);
      setState(() {
        _volume = volume;
      });
      print('Volume set to ${(volume * 100).toInt()}%');
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  void _seek(double value) {
    if (_audioPlayer == null || !_isLoaded) return;
    final newPosition = Duration(milliseconds: value.toInt());
    _audioPlayer!.seek(newPosition);
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Audio Player',
          style: TextStyle(color: Colors.white),
        ),
      ),
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
        child: _hasError
            ? _buildErrorWidget()
            : _isLoaded
                ? _buildAudioPlayer()
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
            Icons.audiotrack,
            size: 80,
            color: Colors.white54,
          ),
          SizedBox(height: 20),
          Text(
            'Audio Not Available',
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
              _initializeAudioPlayer();
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

  Widget _buildAudioPlayer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Audio Info Display
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                _getAudioTitle(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3a4a),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _getAudioSubtitle(),
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4a5a6a),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        
        // Main Play Button
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Color(0xFF7bb6e7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 48,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
        ),
        SizedBox(height: 32),
        
        // Skip Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.replay_10, color: Color(0xFF4a5a6a), size: 28),
              onPressed: _skipBackward,
              tooltip: 'Skip Backward 15s',
            ),
            SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.forward_10, color: Color(0xFF4a5a6a), size: 28),
              onPressed: _skipForward,
              tooltip: 'Skip Forward 15s',
            ),
          ],
        ),
        SizedBox(height: 24),
        
        // Progress Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Slider(
                value: _position.inMilliseconds.toDouble(),
                min: 0,
                max: _duration.inMilliseconds.toDouble(),
                onChanged: _seek,
                activeColor: Color(0xFF7bb6e7),
                inactiveColor: Colors.white24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(color: Color(0xFF4a5a6a)),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(color: Color(0xFF4a5a6a)),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        
        // Volume Control
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(Icons.volume_down, color: Color(0xFF4a5a6a), size: 20),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: _setVolume,
                  activeColor: Color(0xFF7bb6e7),
                  inactiveColor: Colors.white24,
                ),
              ),
              Icon(Icons.volume_up, color: Color(0xFF4a5a6a), size: 20),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Playback Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loop Button
            IconButton(
              icon: Icon(
                _isLooping ? Icons.repeat_one : Icons.repeat,
                color: _isLooping ? Color(0xFF7bb6e7) : Color(0xFF4a5a6a),
                size: 24,
              ),
              onPressed: _toggleLoop,
              tooltip: 'Loop: ${_isLooping ? 'ON' : 'OFF'}',
            ),
            SizedBox(width: 20),
            
            // Speed Controls
            PopupMenuButton<double>(
              icon: Icon(Icons.speed, color: Color(0xFF4a5a6a), size: 24),
              tooltip: 'Playback Speed: ${_playbackSpeed}x',
              onSelected: _setPlaybackSpeed,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0.5,
                  child: Text('0.5x'),
                ),
                PopupMenuItem(
                  value: 1.0,
                  child: Text('1.0x'),
                ),
                PopupMenuItem(
                  value: 1.5,
                  child: Text('1.5x'),
                ),
                PopupMenuItem(
                  value: 2.0,
                  child: Text('2.0x'),
                ),
              ],
            ),
          ],
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
          'Loading audio...',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          widget.audioPath,
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