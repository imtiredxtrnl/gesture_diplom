import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/test_model.dart';
import '../services/auth_service.dart';
import 'test_detail_screen.dart';

class TestsScreen extends StatefulWidget {
  @override
  _TestsScreenState createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  List<Test> tests = [];
  bool isLoading = true;
  List<String> completedTests = [];

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      // Создаем тестовые данные, так как у нас нет JSON файла
      List<Test> testData = [
        Test(
          id: '1',
          question: 'Какой жест обозначает "Привет"?',
          imagePath: 'assets/tests/test1.png',
          options: [
            'Поднятая рука с раскрытой ладонью',
            'Сжатый кулак',
            'Указательный палец направлен вверх',
            'Две руки скрещены на груди'
          ],
          correctOptionIndex: 0,
          category: 'greetings',
        ),
        Test(
          id: '2',
          question: 'Какой жест обозначает "Спасибо"?',
          imagePath: 'assets/tests/test2.png',
          options: [
            'Сжатый кулак',
            'Рука прикладывается к губам и затем опускается вперед',
            'Руки скрещены над головой',
            'Большой палец вверх'
          ],
          correctOptionIndex: 1,
          category: 'basic',
        ),
        Test(
          id: '3',
          question: 'Какой жест означает "Да"?',
          imagePath: 'assets/tests/test3.png',
          options: [
            'Качание головой влево-вправо',
            'Кивание головой вверх-вниз',
            'Поднятие плеч',
            'Указание пальцем'
          ],
          correctOptionIndex: 1,
          category: 'basic',
        ),
      ];

      // Получение списка пройденных тестов
      completedTests = AuthService.currentUser?.completedTests ?? [];

      setState(() {
        tests = testData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading tests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Тесты'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tests.isEmpty
          ? Center(child: Text('Тесты не найдены'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: tests.length,
        itemBuilder: (context, index) {
          final test = tests[index];
          final bool isCompleted = completedTests.contains(test.id);

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCompleted ? Colors.green : Colors.transparent,
                width: isCompleted ? 2 : 0,
              ),
            ),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestDetailScreen(test: test),
                  ),
                );

                if (result == true) {
                  // Тест был пройден, обновляем UI
                  setState(() {
                    if (!completedTests.contains(test.id)) {
                      completedTests.add(test.id);
                    }
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.quiz,
                        size: 30,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.question,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Категория: ${test.category}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}