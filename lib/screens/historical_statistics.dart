import 'package:flutter/material.dart';

class HistoricalStatistics extends StatelessWidget {
  const HistoricalStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Historical Statistics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          // Page content will go here
        ],
      ),
    );
  }
}
