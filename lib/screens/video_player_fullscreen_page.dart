import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

class VideoPlayerFullscreenPage extends StatefulWidget {
  final String videoPath;
  final String title;
  const VideoPlayerFullscreenPage({required this.videoPath, required this.title});

  @override
  State<VideoPlayerFullscreenPage> createState() => _VideoPlayerFullscreenPageState();
}

class _VideoPlayerFullscreenPageState extends State<VideoPlayerFullscreenPage> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      print('Initializing video player with path: ${widget.videoPath}');

      // Check if we're on web platform
      if (kIsWeb) {
        print('Web platform detected - using web-compatible video player');
        setState(() {
          _isWeb = true;
          _isInitialized = true;
          _hasError = false;
        });
        return;
      }
      
      // For mobile and desktop platforms, try to initialize video player
      print('Mobile/Desktop platform detected - initializing video player');
      
      // Clean the video path
      String cleanPath = widget.videoPath;
      if (cleanPath.startsWith('assets/assets/')) {
        cleanPath = cleanPath.replaceFirst('assets/assets/', 'assets/');
        print('Fixed path from ${widget.videoPath} to $cleanPath');
      }
      
      try {
        _controller = VideoPlayerController.asset(cleanPath);
        await _controller!.initialize();
        
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _isWeb = false;
        });
        
        print('Video player initialized successfully');
      } catch (e) {
        print('Video player initialization failed: $e');
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize video player: $e';
        });
      }
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize video player: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _seekTo(Duration position) {
    if (_controller == null || !_isInitialized) return;
    _controller!.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.fullscreen),
            onPressed: () {
              // Toggle fullscreen mode
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_isWeb) {
      return _buildWebVideoWidget();
    }

    if (!_isInitialized || _controller == null) {
      return _buildLoadingWidget();
    }

    return _buildVideoPlayerWidget();
  }

  Widget _buildWebVideoWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 80,
            color: Colors.white54,
          ),
          SizedBox(height: 20),
          Text(
            'Video: ${widget.title}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Web Video Player',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Text(
                  'Video Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Title: ${widget.title}',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  'Path: ${widget.videoPath}',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  'Platform: Web Browser',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Show video info
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Video: ${widget.title} - ${widget.videoPath}'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: Icon(Icons.info),
            label: Text('Show Video Info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7bb6e7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerWidget() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
        _buildVideoControls(),
      ],
    );
  }

  Widget _buildVideoControls() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.black87,
      child: Column(
        children: [
          // Progress bar
          ValueListenableBuilder(
            valueListenable: _controller!,
            builder: (context, VideoPlayerValue value, child) {
              return Column(
                children: [
                  Slider(
                    value: value.position.inMilliseconds.toDouble(),
                    min: 0,
                    max: value.duration.inMilliseconds.toDouble(),
                    onChanged: (newValue) {
                      _seekTo(Duration(milliseconds: newValue.round()));
                    },
                    activeColor: Color(0xFF7bb6e7),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(value.position),
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          _formatDuration(value.duration),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 16),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: _togglePlayPause,
              ),
              IconButton(
                icon: Icon(
                  Icons.replay_10,
                  size: 24,
                  color: Colors.white,
                ),
                onPressed: () {
                  final currentPosition = _controller!.value.position;
                  final newPosition = currentPosition - Duration(seconds: 10);
                  _seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.forward_10,
                  size: 24,
                  color: Colors.white,
                ),
                onPressed: () {
                  final currentPosition = _controller!.value.position;
                  final newPosition = currentPosition + Duration(seconds: 10);
                  final maxPosition = _controller!.value.duration;
                  _seekTo(newPosition > maxPosition ? maxPosition : newPosition);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF7bb6e7),
          ),
          SizedBox(height: 20),
          Text(
            'Loading video...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            widget.videoPath,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          SizedBox(height: 20),
          Text(
            'Video Playback Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
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
              _initializeVideoPlayer();
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
} 