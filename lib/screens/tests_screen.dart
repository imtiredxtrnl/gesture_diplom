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
      // Создаем тестовые данные без изображений
      List<Test> testData = [
        Test(
          id: '1',
          question: 'Який жест означає "Привіт"?',
          imagePath: '', // Убираем путь к изображению
          options: [
            'Піднята рука з розкритою долонею',
            'Стиснутий кулак',
            'Вказівний палець направлений вгору',
            'Дві руки схрещені на грудях'
          ],
          correctOptionIndex: 0,
          category: 'greetings',
        ),
        Test(
          id: '2',
          question: 'Який жест означає "Дякую"?',
          imagePath: '', // Убираем путь к изображению
          options: [
            'Стиснутий кулак',
            'Рука прикладається до губ і потім опускається вперед',
            'Руки схрещені над головою',
            'Великий палець вгору'
          ],
          correctOptionIndex: 1,
          category: 'basic',
        ),
        Test(
          id: '3',
          question: 'Який жест означає "Так"?',
          imagePath: '', // Убираем путь к изображению
          options: [
            'Хитання головою ліворуч-праворуч',
            'Кивання головою вгору-вниз',
            'Підняття плечей',
            'Вказування пальцем'
          ],
          correctOptionIndex: 1,
          category: 'basic',
        ),
        Test(
          id: '4',
          question: 'Як показати жест "Ні"?',
          imagePath: '',
          options: [
            'Вказівний палець з боку в бік',
            'Похитати головою',
            'Схрестити руки',
            'Заплющити очі'
          ],
          correctOptionIndex: 0,
          category: 'basic',
        ),
        Test(
          id: '5',
          question: 'Який жест використовується для "Будь ласка"?',
          imagePath: '',
          options: [
            'Поклін головою',
            'Відкрита долоня на грудях з круговим рухом',
            'Схрещені пальці',
            'Підняті брови'
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
        title: Text('Тести'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Тести не знайдено',
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
          // Информационная панель
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
                      'Інформація про тести',
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
                  'Всього тестів: ${tests.length}\nПройдено: ${completedTests.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),

          // Список тестов
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                final bool isCompleted = completedTests.contains(test.id);

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCompleted ? Colors.green[300]! : Colors.transparent,
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
                          // Иконка теста
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green[100]
                                  : Colors.deepPurple[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCompleted ? Icons.quiz_outlined : Icons.quiz,
                              size: 30,
                              color: isCompleted
                                  ? Colors.green[700]
                                  : Colors.deepPurple[700],
                            ),
                          ),
                          SizedBox(width: 16),

                          // Информация о тесте
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test.question,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 6),

                                // Категория
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
                                    'Категорія: ${test.category}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),

                                // Количество вариантов
                                Text(
                                  'Варіантів відповіді: ${test.options.length}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Статус прохождения
                          if (isCompleted)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            )
                          else
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                              size: 16,
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