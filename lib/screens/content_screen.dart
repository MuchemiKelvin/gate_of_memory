import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ContentScreen extends StatefulWidget {
  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late VideoPlayerController _memorialController;
  late VideoPlayerController _hologramController;

  @override
  void initState() {
    super.initState();
    _memorialController = VideoPlayerController.asset('assets/video/memorial_video.mp4')
      ..initialize().then((_) {
        setState(() {});
      });
    _hologramController = VideoPlayerController.asset('assets/animation/hologram.mp4')
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _memorialController.dispose();
    _hologramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('Memorial Content'),
        backgroundColor: Color(0xFF7B4F1D),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Memorial Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Image.asset('assets/images/memorial_card.jpeg', height: 200),
            SizedBox(height: 32),
            Text('Memorial Video', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _memorialController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _memorialController.value.aspectRatio,
                    child: VideoPlayer(_memorialController),
                  )
                : CircularProgressIndicator(),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _memorialController.value.isPlaying
                      ? _memorialController.pause()
                      : _memorialController.play();
                });
              },
              child: Icon(_memorialController.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            SizedBox(height: 32),
            Text('Hologram Animation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _hologramController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _hologramController.value.aspectRatio,
                    child: VideoPlayer(_hologramController),
                  )
                : CircularProgressIndicator(),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hologramController.value.isPlaying
                      ? _hologramController.pause()
                      : _hologramController.play();
                });
              },
              child: Icon(_hologramController.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
} 