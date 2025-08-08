import 'package:flutter/material.dart';
import 'audio_player_fullscreen_page.dart';
import '../services/memorial_service.dart';
import '../models/memorial.dart';

class AudioPage extends StatefulWidget {
  final String? memorialId;
  
  const AudioPage({
    super.key,
    this.memorialId,
  });

  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  bool isGrid = true;
  Memorial? memorial;
  List<String> audioPaths = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemorialData();
  }

  Future<void> _loadMemorialData() async {
    if (widget.memorialId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final memorialService = MemorialService();
      final memorials = await memorialService.getAllMemorials();
      
      // Find memorial by QR code
      final foundMemorial = memorials.firstWhere(
        (m) => m.qrCode == widget.memorialId,
        orElse: () => throw Exception('Memorial not found'),
      );

      setState(() {
        memorial = foundMemorial;
        audioPaths = foundMemorial.audioPaths.where((path) => path.isNotEmpty).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading memorial data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openAudioPlayer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioPlayerFullscreenPage(
          audioPath: audioPaths[index],
          title: memorial?.name ?? 'Audio',
        ),
      ),
    );
  }

  String _getAudioTitle(String audioPath) {
    // Extract title from path
    final fileName = audioPath.split('/').last.replaceAll('.mp3', '');
    return fileName.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio${memorial != null ? ' - ${memorial!.name}' : ''}'),
        backgroundColor: Color(0xFF7bb6e7),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: isGrid ? 'List View' : 'Grid View',
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
              });
            },
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
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF7bb6e7),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading audio...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : audioPaths.isEmpty
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
                          'No audio available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (memorial != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'for ${memorial!.name}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : isGrid
                    ? GridView.builder(
                        padding: EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: audioPaths.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _openAudioPlayer(index),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF7bb6e7).withOpacity(0.8),
                                      Color(0xFF7bb6e7).withOpacity(0.6),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 12),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        _getAudioTitle(audioPaths[index]),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: audioPaths.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Color(0xFF7bb6e7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              title: Text(
                                _getAudioTitle(audioPaths[index]),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Memorial Audio',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Icon(
                                Icons.play_circle_outline,
                                color: Color(0xFF7bb6e7),
                                size: 32,
                              ),
                              onTap: () => _openAudioPlayer(index),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}