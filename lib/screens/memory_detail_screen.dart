import 'package:flutter/material.dart';
import '../models/memory_page.dart';

class MemoryDetailScreen extends StatelessWidget {
  final MemoryPage memory;

  const MemoryDetailScreen({Key? key, required this.memory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(memory.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(memory.imageAsset, fit: BoxFit.cover, height: 250),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              memory.description,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
} 