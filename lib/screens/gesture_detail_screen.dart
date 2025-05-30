// lib/screens/gesture_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/gesture.dart';
import 'gesture_practice_screen.dart';

class GestureDetailScreen extends StatelessWidget {
  final Gesture gesture;

  GestureDetailScreen({required this.gesture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(gesture.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение жеста
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: gesture.imagePath.isNotEmpty
                  ? Image.asset(
                gesture.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              )
                  : _buildImagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название и категория
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gesture.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getCategoryName(gesture.category),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Описание
                  _buildSectionTitle('Описание'),
                  SizedBox(height: 8),
                  Text(
                    gesture.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Инструкции по выполнению
                  _buildSectionTitle('Как выполнить'),
                  SizedBox(height: 12),
                  _buildInstructionCard(
                    '1',
                    'Подготовка',
                    'Расположите руки перед собой на уровне груди, убедитесь что освещение достаточное.',
                    Colors.blue,
                  ),
                  SizedBox(height: 8),
                  _buildInstructionCard(
                    '2',
                    'Выполнение',
                    'Сформируйте жест как показано на изображении, обратите внимание на положение пальцев и кисти.',
                    Colors.green,
                  ),
                  SizedBox(height: 8),
                  _buildInstructionCard(
                    '3',
                    'Движение',
                    'Если жест требует движения, выполните его плавно и четко, как описано в инструкции.',
                    Colors.orange,
                  ),
                  SizedBox(height: 32),

                  // Кнопка практики
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GesturePracticeScreen(
                              gesture: gesture,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.camera_alt, size: 24),
                      label: Text(
                        'Практиковать с камерой',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Дополнительная информация
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Совет',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Для лучшего распознавания держите руку в хорошо освещенном месте и выполняйте жест четко и медленно.',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gesture,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Изображение жеста',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'В демо-версии изображения не загружены',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildInstructionCard(String number, String title, String description, MaterialColor color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color[800],
                    fontSize: 16,
                  ),
                ),
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
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      height: 1.4,
                      color: Colors.grey[600],
                      fontSize: 14,
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

  String _getCategoryName(String category) {
    const categoryNames = {
      'basic': 'Базовые',
      'greetings': 'Приветствие',
      'questions': 'Вопросы',
      'emotions': 'Эмоции',
      'actions': 'Действия',
      'family': 'Семья',
      'food': 'Еда',
      'numbers': 'Числа',
    };
    return categoryNames[category] ?? category;
  }
}