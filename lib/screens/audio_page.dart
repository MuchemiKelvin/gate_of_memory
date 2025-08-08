import 'package:flutter/material.dart';
import 'audio_player_fullscreen_page.dart';

class AudioPage extends StatefulWidget {
  final List<String> audioPaths;
  
  const AudioPage({
    super.key,
    required this.audioPaths,
  });

  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  void _openAudioPlayer(int index) {
    final audioPath = widget.audioPaths[index];
    final title = _getAudioTitle(audioPath);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioPlayerFullscreenPage(
          audioPath: audioPath,
          title: title,
        ),
      ),
    );
  }

  String _getAudioTitle(String audioPath) {
    // Extract title from path
    final fileName = audioPath.split('/').last;
    final nameWithoutExtension = fileName.split('.').first;
    
    // Convert to readable title
    return nameWithoutExtension
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio (${widget.audioPaths.length})'),
        backgroundColor: Color(0xFF7bb6e7),
        actions: [
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              print('=== AUDIO DEBUG INFO ===');
              print('Audio paths: ${widget.audioPaths}');
              for (int i = 0; i < widget.audioPaths.length; i++) {
                print('  $i: ${widget.audioPaths[i]}');
              }
              print('=======================');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Debug info printed to console')),
              );
            },
            tooltip: 'Debug Info',
          ),
        ],
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
        child: widget.audioPaths.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.audiotrack,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No audio files available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: widget.audioPaths.length,
                itemBuilder: (context, index) {
                  final audioPath = widget.audioPaths[index];
                  final title = _getAudioTitle(audioPath);
                  
                  return GestureDetector(
                    onTap: () => _openAudioPlayer(index),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: Icon(
                          Icons.audiotrack, 
                          color: Color(0xFF7bb6e7), 
                          size: 32
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF2d3a4a),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Tap to play',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.play_arrow, 
                          color: Color(0xFF7bb6e7)
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}