import 'package:flutter/material.dart';

class MemorialPages extends StatelessWidget {
  // final Memorial memorial;
  // MemorialPages({required this.memorial});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Memorial Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Text('Memorial content goes here.'),
      ],
    );
  }
} 