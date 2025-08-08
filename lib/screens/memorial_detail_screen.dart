import 'package:flutter/material.dart';
import '../models/memorial.dart';
import 'images_page.dart';
import 'videos_page.dart';
import 'audio_page.dart';
import 'stories_page.dart';

class MemorialDetailScreen extends StatelessWidget {
  final Memorial memorial;

  const MemorialDetailScreen({
    super.key,
    required this.memorial,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(memorial.name),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(),
            _buildMemorialInfo(),
            _buildContentSections(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(memorial.imagePath.isNotEmpty 
              ? memorial.imagePath 
              : 'assets/images/memorial_card.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  memorial.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    memorial.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemorialInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            memorial.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Created ${_formatDate(memorial.createdAt)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (memorial.stories.isNotEmpty)
                Text(
                  '${memorial.stories.length} story${memorial.stories.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSections(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildContentGrid(context),
        ],
      ),
    );
  }

  Widget _buildContentGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        if (memorial.imagePath.isNotEmpty)
          _buildContentCard(
            context,
            'Images',
            Icons.photo_library,
            Colors.blue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagesPage(
                    imagePaths: [memorial.imagePath],
                  ),
                ),
              );
            },
          ),
        if (memorial.videoPath.isNotEmpty)
          _buildContentCard(
            context,
            'Videos',
            Icons.videocam,
            Colors.red,
            () {
              print('Opening video page with paths: [${memorial.videoPath}]');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideosPage(
                    videoPaths: [memorial.videoPath],
                  ),
                ),
              );
            },
          ),
        if (memorial.audioPaths.isNotEmpty)
          _buildContentCard(
            context,
            'Audio',
            Icons.audiotrack,
            Colors.orange,
            () {
              print('Opening audio page with paths: ${memorial.audioPaths}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AudioPage(
                    audioPaths: memorial.audioPaths,
                  ),
                ),
              );
            },
          ),
        if (memorial.stories.isNotEmpty)
          _buildContentCard(
            context,
            'Stories',
            Icons.book,
            Colors.green,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoriesPage(
                    stories: memorial.stories,
                  ),
                ),
              );
            },
          ),
        if (memorial.hologramPath.isNotEmpty)
          _buildContentCard(
            context,
            'Hologram',
            Icons.view_in_ar,
            Colors.purple,
            () {
              // TODO: Implement hologram viewer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hologram viewer coming soon!')),
              );
            },
          ),
      ],
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.2),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (memorial.category.toLowerCase()) {
      case 'memorial':
        return const Color(0xFF7BB6E7);
      case 'celebration':
        return const Color(0xFF4CAF50);
      case 'tribute':
        return const Color(0xFFFF9800);
      case 'historical':
        return const Color(0xFF9C27B0);
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months != 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years != 1 ? 's' : ''} ago';
    }
  }
} 