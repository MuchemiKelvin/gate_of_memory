import 'package:flutter/material.dart';
import 'story_reader_page.dart';
import '../models/memorial.dart';

class StoriesPage extends StatelessWidget {
  final List<Story> stories;
  
  const StoriesPage({
    super.key,
    required this.stories,
  });

  void _openStory(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryReaderPage(
          title: stories[index].title,
          fullText: stories[index].fullText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stories (${stories.length})'),
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
        child: stories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No stories available',
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
                        leading: Icon(
                          Icons.menu_book, 
                          color: Color(0xFF7bb6e7), 
                          size: 32
                        ),
                        title: Text(
                          stories[index].title,
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF2d3a4a),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          stories[index].snippet,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4a5a6a),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios, 
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