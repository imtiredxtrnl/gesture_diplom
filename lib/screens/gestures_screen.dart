// lib/screens/gestures_screen.dart
import 'package:flutter/material.dart';
import '../screens/dictionary_screen.dart';
import '../screens/alphabet_selection_screen.dart';
import '../screens/tests_screen.dart';
import '../screens/gesture_selection_screen.dart';

class GesturesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCategoryCard(
            context,
            'Словарь жестов',
            'Изучите основные жесты и их значения',
            Icons.sign_language,
            Colors.purple[700]!,
                () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DictionaryScreen())
            ),
          ),
          SizedBox(height: 16),
          _buildCategoryCard(
            context,
            'Практика жестов',
            'Практикуйте жесты с использованием камеры и таймера',
            Icons.camera_alt,
            Colors.teal[700]!,
                () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GestureSelectionScreen())
            ),
          ),
          SizedBox(height: 16),
          _buildCategoryCard(
            context,
            'Алфавит',
            'Изучите алфавит на языке жестов (украинский и английский)',
            Icons.text_fields,
            Colors.blue[700]!,
                () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlphabetSelectionScreen())
            ),
          ),
          SizedBox(height: 16),
          _buildCategoryCard(
            context,
            'Тесты',
            'Проверьте свои знания языка жестов',
            Icons.quiz,
            Colors.green[700]!,
                () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TestsScreen())
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onPressed
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
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