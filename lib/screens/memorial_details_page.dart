import 'package:flutter/material.dart';
import 'images_page.dart';
import 'videos_page.dart';
import 'audio_page.dart';
import 'stories_page.dart';
import '../models/memorial.dart';

class MemorialDetailsPage extends StatelessWidget {
  static const double cardWidth = 350;
  static const double mediaCardHeight = 80;

  void _showSnackBar(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label tapped!'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > cardWidth + 48;
    final double width = isWide ? cardWidth : MediaQuery.of(context).size.width - 32;
    return Scaffold(
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
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top card
                Container(
                  width: width,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    color: Colors.white.withOpacity(0.97),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 120,
                            child: CustomPaint(
                              painter: GateFramePainter(),
                              child: Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF7bb6e7).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.person, size: 40, color: Color(0xFF7bb6e7)),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Naomi N.',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3a4a),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'In Loving Memory',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF4a5a6a),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'A beloved friend and family member. Her light will always shine in our hearts.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4a5a6a),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                // Two rows of two media cards
                Container(
                  width: width,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: mediaCardHeight,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ImagesPage(
                                        imagePaths: ['assets/images/memorial_card.jpeg'],
                                      ),
                                    ),
                                  );
                                  _showSnackBar(context, 'Images');
                                },
                                child: MediaCard(icon: Icons.photo, label: 'Images'),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: mediaCardHeight,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VideosPage(
                                        videoPaths: ['assets/video/memorial_video.mp4'],
                                      ),
                                    ),
                                  );
                                  _showSnackBar(context, 'Videos');
                                },
                                child: MediaCard(icon: Icons.videocam, label: 'Videos'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: mediaCardHeight,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AudioPage(
                                        audioPaths: ['assets/audio/victory_chime.mp3'],
                                      ),
                                    ),
                                  );
                                  _showSnackBar(context, 'Audio');
                                },
                                child: MediaCard(icon: Icons.audiotrack, label: 'Audio'),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: mediaCardHeight,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoriesPage(
                                        stories: [
                                          Story(
                                            title: 'A Beautiful Memory',
                                            snippet: 'It was a sunny day when we all gathered...',
                                            fullText: 'It was a sunny day when we all gathered at the park. Naomi smiled as she watched the children play, her laughter echoing in the air. We shared stories, food, and love, making memories that would last forever.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: MediaCard(icon: Icons.menu_book, label: 'Stories'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for gate/arched frame
class GateFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF7bb6e7).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path();
    // Draw arch (gate)
    path.moveTo(0, size.height * 0.6);
    path.arcToPoint(
      Offset(size.width, size.height * 0.6),
      radius: Radius.circular(size.width / 2),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(GateFramePainter oldDelegate) => false;
}

// Media card widget
class MediaCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const MediaCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Color(0xFF7bb6e7), size: 32),
          SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF2d3a4a),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 