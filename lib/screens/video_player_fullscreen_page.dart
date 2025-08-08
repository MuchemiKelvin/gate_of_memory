import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPlayerFullscreenPage extends StatefulWidget {
  final String videoPath;
  const VideoPlayerFullscreenPage({required this.videoPath});

  @override
  State<VideoPlayerFullscreenPage> createState() => _VideoPlayerFullscreenPageState();
}

class _VideoPlayerFullscreenPageState extends State<VideoPlayerFullscreenPage> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      print('Initializing video player with path: ${widget.videoPath}');
      
      // Check if we're on Windows and provide a fallback
      if (Platform.isWindows) {
        print('Running on Windows - using fallback video player');
        setState(() {
          _hasError = true;
          _errorMessage = 'Video playback is not supported on Windows yet. Video path: ${widget.videoPath}';
        });
        return;
      }
      
      _controller = VideoPlayerController.asset(widget.videoPath);
      
      await _controller!.initialize();
      print('Video controller initialized successfully');
      
      setState(() {
        _isInitialized = true;
      });
      
      _controller!.play();
      _isPlaying = true;
      print('Video playback started');
      
      _controller!.addListener(() {
        setState(() {});
      });
    } catch (e) {
      print('Error initializing video controller: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
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
      body: Center(
        child: _hasError
            ? _buildErrorWidget()
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
} 