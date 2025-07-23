import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'memorial_details_page.dart';

class GateScreen extends StatefulWidget {
  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  late VideoPlayerController _videoController;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/video/memorial_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
      });
    // Hide overlay after 2 seconds for a modern effect
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showOverlay = false;
      });
    });
    // Navigate to MemorialDetailsPage after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MemorialDetailsPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video background
          Positioned.fill(
            child: _videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: Color(0xFFeaf3fa)),
          ),
          // Blue/white gradient overlay for beauty
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xAAeaf3fa),
                      Color(0xAAfafdff),
                      Color(0xAAdbeaf7),
                      Color(0xAAc7e0f5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 80, color: Color(0xFF7bb6e7)),
                      SizedBox(height: 32),
                      Text(
                        'Opening the Gate...',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3a4a),
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 