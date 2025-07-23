import 'package:flutter/material.dart';

class HomeMemorialCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.yellow[100],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome to Gate of Memory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Preserve and celebrate the memories of your loved ones.'),
          ],
        ),
      ),
    );
  }
} 