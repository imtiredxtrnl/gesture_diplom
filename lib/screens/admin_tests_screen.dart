import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/test_model.dart';
import 'add_test_screen.dart';

class AdminTestsScreen extends StatefulWidget {
  @override
  _AdminTestsScreenState createState() => _AdminTestsScreenState();
}

class _AdminTestsScreenState extends State<AdminTestsScreen> {
  List<Test> tests = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      // Створюємо тестові дані
      List<Test> testData = [
        Test(
          id: '1',
          question: 'Який жест означає "Привіт"?',
          options: [
            'Піднята рука з розкритою долонею',
            'Стиснутий кулак',
            'Вказівний палець спрямований вгору',
            'Дві руки схрещені на грудях'
          ],
          correctOptionIndex: 0,
          category: 'greetings',
        ),
        Test(
          id: '2',
          question: 'Який жест означає "Дякую"?',
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
          options: [
            'Похитування головою вліво-вправо',
            'Кивання головою вгору-вниз',
            'Підняття плечей',
            'Вказування пальцем'
          ],
          correctOptionIndex: 1,
          category: 'basic',
        ),
      ];

      setState(() {
        tests = testData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Помилка завантаження тестів: $e');
    }
  }

  List<Test> get filteredTests {
    if (searchQuery.isEmpty) {
      return tests;
    }
    return tests.where((test) =>
    test.question.toLowerCase().contains(searchQuery.toLowerCase()) ||
        test.category.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _showDeleteConfirmation(Test test) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Видалення тесту'),
        content: Text('Ви впевнені, що хочете видалити тест "${test.question}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ВІДМІНА'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ВИДАЛИТИ'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteTest(test);
    }
  }

  Future<void> _deleteTest(Test test) async {
    // Показуємо SnackBar з можливістю скасування
    setState(() {
      tests.removeWhere((t) => t.id == test.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Тест "${test.question}" видалено'),
        action: SnackBarAction(
          label: 'ВІДМІНИТИ',
          onPressed: () {
            // Повертаємо тест назад у список
            setState(() {
              tests.add(test);
              // Сортуємо список за ID для збереження порядку
              tests.sort((a, b) => a.id.compareTo(b.id));
            });
          },
        ),
        duration: Duration(seconds: 5),
      ),
    );

    // В реальному застосунку тут був би API-запит на видалення
    // await ApiService.deleteTest(test.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управління тестами'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTests,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Пошук тестів...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredTests.isEmpty
                ? Center(child: Text('Тести не знайдено'))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredTests.length,
              itemBuilder: (context, index) {
                final test = filteredTests[index];
                return _buildTestItem(test);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTestScreen()),
          );
          if (result == true) {
            _loadTests();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Додати тест',
      ),
    );
  }

  Widget _buildTestItem(Test test) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.quiz,
            color: Colors.grey[600],
          ),
        ),
        title: Text(
          test.question,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Категорія: ${test.category}'),
            SizedBox(height: 4),
            Text('Варіанти відповідей: ${test.options.length}'),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                // В реальному застосунку тут був би перехід на екран редагування
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Редагування тесту поки що не реалізовано')),
                );
              },
              tooltip: 'Редагувати',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(test),
              tooltip: 'Видалити',
            ),
          ],
        ),
      ),
    );
  }
}