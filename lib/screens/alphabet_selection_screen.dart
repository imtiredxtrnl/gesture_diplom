import 'package:flutter/material.dart';
import 'alphabet_screen.dart';

class AlphabetSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Вибір алфавіту'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildLanguageCard(
              context,
              'Український алфавіт',
              'Вивчить український дактильний алфавіт',
              'assets/images/ukraine_flag.png',
              Colors.blue[700]!,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlphabetScreen(language: 'uk')),
              ),
            ),
            SizedBox(height: 16),
            _buildLanguageCard(
              context,
              'Англійський алфавіт',
              'Вивчить англійський дактильний алфавіт',
              'assets/images/uk_flag.png',
              Colors.red[700]!,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlphabetScreen(language: 'en')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
      BuildContext context,
      String title,
      String subtitle,
      String imagePath,
      Color color,
      VoidCallback onPressed,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flag,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}