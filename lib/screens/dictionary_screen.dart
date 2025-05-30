// lib/screens/dictionary_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/gesture.dart';
import 'gesture_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  List<Gesture> gestures = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'all';

  List<String> categories = [
    'all',
    'basic',
    'greetings',
    'questions',
    'emotions',
    'actions',
    'family',
    'food',
    'numbers',
  ];

  @override
  void initState() {
    super.initState();
    _loadGestures();
  }

  Future<void> _loadGestures() async {
    try {
      // Создаем тестовые данные жестов (в реальном приложении данные загружаются из JSON)
      List<Gesture> testGestures = [
        Gesture(
          id: '1',
          name: 'Привіт',
          description: 'Жест привітання, який використовується для початку розмови або під час зустрічі з кимось.',
          imagePath: 'assets/gestures/hello.png',
          category: 'greetings',
        ),
        Gesture(
          id: '2',
          name: 'Дякую',
          description: 'Жест подяки, який виражає вдячність за що-небудь',
          imagePath: 'assets/gestures/thank_you.png',
          category: 'basic',
        ),
        Gesture(
          id: '3',
          name: 'Будь-ласка',
          description: 'Жест ввічливого прохання або відповіді на подяку.',
          imagePath: 'assets/gestures/please.png',
          category: 'basic',
        ),
        Gesture(
          id: '4',
          name: 'Так',
          description: 'Жест згоди, який означає позитивну відповідь.',
          imagePath: 'assets/gestures/yes.png',
          category: 'basic',
        ),
        Gesture(
          id: '5',
          name: 'Ні',
          description: 'Жест заперечення, який означає негативну відповідь.',
          imagePath: 'assets/gestures/no.png',
          category: 'basic',
        ),
        Gesture(
          id: '6',
          name: 'Добре',
          description: 'Жест схвалення і позитивної оцінки.',
          imagePath: 'assets/gestures/good.png',
          category: 'emotions',
        ),
        Gesture(
          id: '7',
          name: 'Погано',
          description: 'Жест несхвалення і негативної оцінки.',
          imagePath: 'assets/gestures/bad.png',
          category: 'emotions',
        ),
        Gesture(
          id: '8',
          name: 'Як справи?',
          description: 'Запитальний жест для з\'ясування стану справ.',
          imagePath: 'assets/gestures/how_are_you.png',
          category: 'questions',
        ),
        Gesture(
          id: '9',
          name: 'Вибачте',
          description: 'Жест вибачення за скоєну помилку або незручність.',
          imagePath: 'assets/gestures/sorry.png',
          category: 'basic',
        ),
        Gesture(
          id: '10',
          name: 'Допоможіть',
          description: 'Жест прохання про допомогу в складній ситуації.',
          imagePath: 'assets/gestures/help.png',
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

  List<Gesture> get filteredGestures {
    List<Gesture> result = gestures;

    if (selectedCategory != 'all') {
      result = result.where((gesture) => gesture.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((gesture) =>
      gesture.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          gesture.description.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    return result;
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'all':
        return 'Все';
      case 'basic':
        return 'Базові';
      case 'greetings':
        return 'Привітання';
      case 'questions':
        return 'Питання';
      case 'emotions':
        return 'Емоції';
      case 'actions':
        return 'Дії';
      case 'family':
        return 'Сім\'я';
      case 'food':
        return 'Їжа';
      case 'numbers':
        return 'Числа';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Словник жестів'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Пошук жестів...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Фильтры по категориям
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      _getCategoryDisplayName(category),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.deepPurple,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 8),
          // Список жестов
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.deepPurple,
                  ),
                  SizedBox(height: 16),
                  Text('Завантаження жестів...'),
                ],
              ),
            )
                : filteredGestures.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Жести не знайдено',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Спробуйте змінити параметри пошуку',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredGestures.length,
              itemBuilder: (context, index) {
                final gesture = filteredGestures[index];
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
                          builder: (context) => GestureDetailScreen(gesture: gesture),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Изображение жеста
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: gesture.imagePath.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                gesture.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.gesture,
                                    size: 30,
                                    color: Colors.grey[600],
                                  );
                                },
                              ),
                            )
                                : Icon(
                              Icons.gesture,
                              size: 30,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 16),
                          // Информация о жесте
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        gesture.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getCategoryDisplayName(gesture.category),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.deepPurple[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  gesture.description.length > 80
                                      ? '${gesture.description.substring(0, 80)}...'
                                      : gesture.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
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