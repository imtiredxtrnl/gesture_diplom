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
      // Создаем тестовые данные
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

  List<Test> get filteredTests {
    if (searchQuery.isEmpty) {
      return tests;
    }
    return tests.where((test) =>
    test.question.toLowerCase().contains(searchQuery.toLowerCase()) ||
        test.category.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление тестами'),
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
                hintText: 'Поиск тестов...',
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
                ? Center(child: Text('Тесты не найдены'))
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
        tooltip: 'Добавить тест',
      ),
    );
  }

  Widget _buildTestItem(Test test) {
    return Dismissible(
      key: Key(test.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Удаление теста'),
            content: Text('Вы уверены, что хотите удалить тест "${test.question}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('ОТМЕНА'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('УДАЛИТЬ'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // В реальном приложении здесь был бы API-запрос на удаление
        setState(() {
          tests.removeWhere((t) => t.id == test.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Тест "${test.question}" удален')),
        );
      },
      child: Card(
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
              Text('Категория: ${test.category}'),
              SizedBox(height: 4),
              Text('Варианты ответов: ${test.options.length}'),
            ],
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              // В реальном приложении здесь был бы переход на экран редактирования
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Редактирование теста пока не реализовано')),
              );
            },
          ),
        ),
      ),
    );
  }
}