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
  bool _isWindows = false;

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
        print('Web platform detected - using fallback video player');
        setState(() {
          _hasError = true;
          _errorMessage = 'Video playback is not supported on web platform yet. Video path: ${widget.videoPath}';
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
          _isWindows = false; // Not Windows if we got here
        });
        
        print('✓ Video player initialized successfully');
      } catch (e) {
        print('❌ Video player initialization failed: $e');
        // If video player fails, show Windows fallback
        setState(() {
          _isWindows = true;
          _hasError = false;
          _errorMessage = '';
        });
        print('Falling back to Windows interface due to video player failure');
      }
    } catch (e) {
      print('❌ Error initializing video player: $e');
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
          'Video Player',
          style: TextStyle(color: Colors.white),
        ),
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
            : _isWindows
                ? _buildWindowsFallbackWidget()
                : _isInitialized
                    ? _buildVideoPlayer()
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
            Icons.video_library,
            size: 80,
            color: Colors.white54,
          ),
          SizedBox(height: 20),
          Text(
            'Video Not Available',
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

  Widget _buildVideoPlayer() {
    if (_controller == null) return _buildErrorWidget();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
              onPressed: _togglePlayPause,
            ),
            SizedBox(width: 16),
            Expanded(
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Color(0xFF7bb6e7),
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white38,
                ),
              ),
            ),
            SizedBox(width: 16),
            Text(
              '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
              style: TextStyle(color: Colors.white),
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
    );
  }

  Widget _buildWindowsFallbackWidget() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_file,
            size: 80,
            color: Colors.white54,
          ),
          SizedBox(height: 20),
          Text(
            'Video Preview (Windows)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Video playback is not yet supported on Windows desktop.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
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
                  'Platform: Windows Desktop',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Show file info or open file location
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Video file: ${widget.videoPath}'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: Icon(Icons.info),
            label: Text('Show File Info'),
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