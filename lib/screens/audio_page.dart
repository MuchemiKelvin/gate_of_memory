import 'package:flutter/material.dart';
import 'audio_player_fullscreen_page.dart';

class AudioPage extends StatefulWidget {
  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final List<Map<String, String>> audios = [
    {
      'audio': 'assets/audio/the-wreck-12291.mp3',
      'title': 'The Wreck',
    },
    {
      'audio': 'assets/audio/the-wreck-12291.mp3',
      'title': 'The Wreck (2)',
    },
  ];

  void _openAudioPlayer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioPlayerFullscreenPage(
          audioPath: audios[index]['audio']!,
          title: audios[index]['title']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio'),
        backgroundColor: Color(0xFF7bb6e7),
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
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: audios.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openAudioPlayer(index),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(Icons.audiotrack, color: Color(0xFF7bb6e7), size: 32),
                  title: Text(
                    audios[index]['title']!,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF2d3a4a),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.play_arrow, color: Color(0xFF7bb6e7)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}