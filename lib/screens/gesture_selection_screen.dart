// lib/screens/gesture_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/gesture.dart';
import 'gesture_practice_screen.dart';

class GestureSelectionScreen extends StatefulWidget {
  @override
  _GestureSelectionScreenState createState() => _GestureSelectionScreenState();
}

class _GestureSelectionScreenState extends State<GestureSelectionScreen> {
  List<Gesture> gestures = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGestures();
  }

  Future<void> _loadGestures() async {
    try {
      // Создаем тестовые данные жестов для практики
      List<Gesture> testGestures = [
        Gesture(
          id: '1',
          name: 'Привет',
          description: 'Жест приветствия. Поднимите руку с раскрытой ладонью и помашите ей.',
          imagePath: 'assets/gestures/hello.png',
          category: 'greetings',
        ),
        Gesture(
          id: '2',
          name: 'Спасибо',
          description: 'Жест благодарности. Прикоснитесь пальцами к губам, затем опустите руку вперед.',
          imagePath: 'assets/gestures/thank_you.png',
          category: 'basic',
        ),
        Gesture(
          id: '3',
          name: 'Пожалуйста',
          description: 'Жест вежливой просьбы. Положите открытую ладонь на грудь и сделайте круговое движение.',
          imagePath: 'assets/gestures/please.png',
          category: 'basic',
        ),
        Gesture(
          id: '4',
          name: 'Да',
          description: 'Жест согласия. Покажите большой палец вверх или кивните головой.',
          imagePath: 'assets/gestures/yes.png',
          category: 'basic',
        ),
        Gesture(
          id: '5',
          name: 'Нет',
          description: 'Жест отрицания. Покачайте головой или покажите указательным пальцем из стороны в сторону.',
          imagePath: 'assets/gestures/no.png',
          category: 'basic',
        ),
        Gesture(
          id: '6',
          name: 'Хорошо',
          description: 'Жест одобрения. Сформируйте кольцо из большого и указательного пальца.',
          imagePath: 'assets/gestures/ok.png',
          category: 'emotions',
        ),
        Gesture(
          id: '7',
          name: 'Плохо',
          description: 'Жест неодобрения. Покажите большой палец вниз.',
          imagePath: 'assets/gestures/bad.png',
          category: 'emotions',
        ),
        Gesture(
          id: '8',
          name: 'Стоп',
          description: 'Жест остановки. Поднимите руку с открытой ладонью перед собой.',
          imagePath: 'assets/gestures/stop.png',
          category: 'actions',
        ),
      ];

      setState(() {
        gestures = testGestures;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading gestures: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выберите жест для практики'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : gestures.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gesture,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Жесты не найдены',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Инструкция
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
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
                    Icon(Icons.info, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Text(
                      'Инструкция',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Выберите жест для практики\n• У вас будет 60 секунд для тренировки\n• Следуйте описанию жеста\n• Камера будет распознавать ваши движения',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          // Список жестов
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: gestures.length,
              itemBuilder: (context, index) {
                final gesture = gestures[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GesturePracticeScreen(
                            gestureName: gesture.name,
                            gestureDescription: gesture.description,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Иконка жеста
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.gesture,
                              size: 30,
                              color: Colors.deepPurple[700],
                            ),
                          ),
                          SizedBox(width: 16),
                          // Информация о жесте
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gesture.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    gesture.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  gesture.description.length > 60
                                      ? '${gesture.description.substring(0, 60)}...'
                                      : gesture.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Кнопка практики
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}