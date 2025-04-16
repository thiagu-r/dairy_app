// lib/widgets/loading_indicator.dart

import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  
  const LoadingIndicator({
    this.message = 'Loading...',
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}