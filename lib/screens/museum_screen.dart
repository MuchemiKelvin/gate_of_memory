import 'package:flutter/material.dart';

class MuseumScreen extends StatelessWidget {
  final List<String> imageAssets;

  const MuseumScreen({
    Key? key,
    required this.imageAssets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kardiverse Gallery'),
        backgroundColor: Color(0xFF7B4F1D),
      ),
      backgroundColor: const Color(0xFFFFF8E1),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: imageAssets.length,
        itemBuilder: (context, index) {
          return Image.asset(imageAssets[index], fit: BoxFit.cover);
        },
      ),
    );
  }
} 