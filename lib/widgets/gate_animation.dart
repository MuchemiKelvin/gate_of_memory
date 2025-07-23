import 'package:flutter/material.dart';

class GateAnimation extends StatelessWidget {
  final VoidCallback onComplete;
  const GateAnimation({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), onComplete);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_open, size: 64, color: Colors.yellow[700]),
        SizedBox(height: 16),
        Text('Opening the gate...', style: TextStyle(fontSize: 18)),
      ],
    );
  }
} 