import 'package:flutter/material.dart';
import 'story_reader_page.dart';

class StoriesPage extends StatelessWidget {
  // 5 sample short stories
  final List<Map<String, String>> stories = [
    {
      'title': 'A Beautiful Memory',
      'snippet': 'It was a sunny day when we all gathered... ',
      'full': 'It was a sunny day when we all gathered at the park. Naomi smiled as she watched the children play, her laughter echoing in the air. We shared stories, food, and love, making memories that would last forever.'
    },
    {
      'title': 'The Last Song',
      'snippet': 'She sang with a voice that touched every heart... ',
      'full': 'She sang with a voice that touched every heart in the room. As the final note faded, there was a moment of silence, then applause. Naomi bowed, her eyes shining with joy.'
    },
    {
      'title': 'A Walk in the Garden',
      'snippet': 'We strolled among the flowers, talking softly... ',
      'full': 'We strolled among the flowers, talking softly about dreams and hopes. The scent of roses filled the air, and the world felt peaceful and kind.'
    },
    {
      'title': 'The Old Photograph',
      'snippet': 'I found an old photograph of us... ',
      'full': 'I found an old photograph of us, smiling at the camera, arms around each other. It brought back a flood of happy memories and a few tears.'
    },
    {
      'title': 'A Cup of Tea',
      'snippet': 'We sat by the window, sipping tea... ',
      'full': 'We sat by the window, sipping tea and watching the rain. Naomi told stories of her childhood, and I listened, grateful for every moment.'
    },
  ];

  void _openStory(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryReaderPage(
          title: stories[index]['title']!,
          fullText: stories[index]['full']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stories'),
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
          itemCount: stories.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openStory(context, index),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(Icons.menu_book, color: Color(0xFF7bb6e7), size: 32),
                  title: Text(
                    stories[index]['title']!,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF2d3a4a),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    stories[index]['snippet']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4a5a6a),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF7bb6e7)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 