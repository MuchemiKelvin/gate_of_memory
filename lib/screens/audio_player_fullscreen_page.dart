import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerFullscreenPage extends StatefulWidget {
  final String audioPath;
  final String title;
  const AudioPlayerFullscreenPage({required this.audioPath, required this.title});

  @override
  State<AudioPlayerFullscreenPage> createState() => _AudioPlayerFullscreenPageState();
}

class _AudioPlayerFullscreenPageState extends State<AudioPlayerFullscreenPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setSourceAsset(widget.audioPath).then((_) {
      setState(() {
        _isLoaded = true;
      });
    });
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() {
        _duration = d;
      });
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seek(double value) {
    final newPosition = Duration(milliseconds: value.toInt());
    _audioPlayer.seek(newPosition);
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
        child: _isLoaded
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFeab676),
                    child: Icon(Icons.person, size: 48, color: Color(0xFFa05a00)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 24, color: Color(0xFF2d3a4a), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lorem ipsum dolors amet, consectetur',
                    style: TextStyle(fontSize: 16, color: Color(0xFF4a5a6a)),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 120,
                    height: 2,
                    color: Color(0xFFd3bfa7),
                  ),
                  SizedBox(height: 32),
                  // Large play/pause and music icon in a colored rounded rectangle
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFeab676),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
                          onPressed: _togglePlayPause,
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.music_note, color: Colors.white, size: 36),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        Slider(
                          value: _position.inMilliseconds.toDouble(),
                          min: 0,
                          max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1,
                          onChanged: (value) => _seek(value),
                          activeColor: Color(0xFF7bb6e7),
                          inactiveColor: Colors.white24,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_position), style: TextStyle(color: Color(0xFF4a5a6a))),
                            Text(_formatDuration(_duration), style: TextStyle(color: Color(0xFF4a5a6a))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(child: CircularProgressIndicator(color: Color(0xFF7bb6e7))),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 