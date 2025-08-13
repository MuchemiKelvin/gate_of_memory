import 'package:flutter/material.dart';
import 'story_reader_page.dart';
import '../services/memorial_service.dart';
import '../models/memorial.dart';

class StoriesPage extends StatefulWidget {
  final String? memorialId;
  
  const StoriesPage({
    super.key,
    this.memorialId,
  });

  @override
  _StoriesPageState createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  Memorial? memorial;
  List<Story> stories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemorialData();
  }

  Future<void> _loadMemorialData() async {
    print('=== STORIES PAGE DEBUG ===');
    print('Memorial ID (QR Code): ${widget.memorialId}');
    
    if (widget.memorialId == null) {
      print('✗ No memorial ID provided');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final memorialService = MemorialService();
      final memorials = await memorialService.getAllMemorials();
      print('✓ Loaded ${memorials.length} memorials from database');
      
      // Find memorial by QR code (not ID)
      final foundMemorial = memorials.firstWhere(
        (m) => m.qrCode == widget.memorialId,
        orElse: () => throw Exception('Memorial not found with QR code: ${widget.memorialId}'),
      );
      
      print('✓ Found memorial: ${foundMemorial.name}');
      print('  - Stories: ${foundMemorial.stories.length} stories');
      print('  - Stories isEmpty: ${foundMemorial.stories.isEmpty}');

      setState(() {
        memorial = foundMemorial;
        stories = foundMemorial.stories;
        isLoading = false;
      });
      
      print('✓ State updated successfully');
    } catch (e) {
      print('❌ Error loading memorial data: $e');
      setState(() {
        isLoading = false;
      });
    }
    
    print('=== END STORIES PAGE DEBUG ===');
  }

  void _openStoryReader(int index) {
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
        title: Text('Stories${memorial != null ? ' - ${memorial!.name}' : ''}'),
        backgroundColor: Color(0xFF7bb6e7),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                      'Loading stories...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : stories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book,
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
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: InkWell(
                          onTap: () => _openStoryReader(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF7bb6e7).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        color: Color(0xFF7bb6e7),
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                 children: [
                                           Text(
                                             story.title,
                                             style: TextStyle(
                                               fontSize: 18,
                                               fontWeight: FontWeight.bold,
                                               color: Color(0xFF2d3a4a),
                                             ),
                                           ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Story ${index + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Color(0xFF7bb6e7),
                                      size: 20,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                                                 Text(
                                   story.snippet,
                                   style: TextStyle(
                                     fontSize: 14,
                                     color: Colors.grey[700],
                                     height: 1.4,
                                   ),
                                   maxLines: 3,
                                   overflow: TextOverflow.ellipsis,
                                 ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Read Story',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF7bb6e7).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Tap to read',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF7bb6e7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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