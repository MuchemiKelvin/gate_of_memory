import 'package:flutter/material.dart';
import 'hologram_player_fullscreen_page.dart';

class HologramsPage extends StatefulWidget {
  final List<String> hologramPaths;
  
  const HologramsPage({
    super.key,
    required this.hologramPaths,
  });

  @override
  _HologramsPageState createState() => _HologramsPageState();
}

class _HologramsPageState extends State<HologramsPage> {
  String _selectedCategory = 'All';
  List<String> _categories = ['All', 'Memorial', 'Educational', 'Entertainment', 'Scientific'];
  
  List<String> get _filteredHolograms {
    if (_selectedCategory == 'All') {
      return widget.hologramPaths;
    }
    // Filter based on filename patterns
    return widget.hologramPaths.where((path) {
      final fileName = path.toLowerCase();
      switch (_selectedCategory) {
        case 'Memorial':
          return fileName.contains('memorial') || fileName.contains('naomi') || fileName.contains('john') || fileName.contains('sarah');
        case 'Educational':
          return fileName.contains('teaching') || fileName.contains('educational') || fileName.contains('learn');
        case 'Entertainment':
          return fileName.contains('entertainment') || fileName.contains('fun') || fileName.contains('show');
        case 'Scientific':
          return fileName.contains('scientific') || fileName.contains('research') || fileName.contains('study');
        default:
          return true;
      }
    }).toList();
  }

  void _openHologramPlayer(int index) {
    final hologramPath = widget.hologramPaths[index];
    final title = _getHologramTitle(hologramPath);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HologramPlayerFullscreenPage(
          hologramPath: hologramPath,
          title: title,
        ),
      ),
    );
  }

  String _getHologramTitle(String hologramPath) {
    // Extract title from path
    final fileName = hologramPath.split('/').last;
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
        title: Text('Holograms (${_filteredHolograms.length}/${widget.hologramPaths.length})'),
        backgroundColor: Color(0xFF7bb6e7),
        actions: [
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              print('=== HOLOGRAM DEBUG INFO ===');
              print('Total hologram paths: ${widget.hologramPaths.length}');
              print('Filtered holograms: ${_filteredHolograms.length}');
              print('Selected category: $_selectedCategory');
              print('Hologram paths: ${widget.hologramPaths}');
              for (int i = 0; i < widget.hologramPaths.length; i++) {
                print('  $i: ${widget.hologramPaths[i]}');
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
        child: Column(
          children: [
            // Category Filter
            Container(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Color(0xFF7bb6e7),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Color(0xFF2d3a4a),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Hologram Grid
            Expanded(
              child: _filteredHolograms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_in_ar,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No holograms in "$_selectedCategory" category',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try selecting a different category',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _filteredHolograms.length,
                      itemBuilder: (context, index) {
                        final hologramPath = _filteredHolograms[index];
                        final title = _getHologramTitle(hologramPath);
                        
                        return _buildHologramCard(index, title, hologramPath);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHologramCard(int index, String title, String hologramPath) {
    return GestureDetector(
      onTap: () => _openHologramPlayer(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hologram Preview with Thumbnail
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1a2a3a),
                      Color(0xFF2d3a4a),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Hologram Thumbnail
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFF7bb6e7), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF7bb6e7).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.view_in_ar,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Rotation Animation
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    // Play Button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(0xFF7bb6e7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Hologram Type Badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF7bb6e7).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '360°',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Hologram Info
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d3a4a),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.view_in_ar,
                        size: 14,
                        color: Color(0xFF7bb6e7),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Hologram • 360°',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7bb6e7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to view in 3D',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 