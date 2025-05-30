// lib/screens/gesture_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/gesture.dart';
import '../services/admin_service.dart';
import 'gesture_practice_screen.dart';

class GestureSelectionScreen extends StatefulWidget {
  @override
  _GestureSelectionScreenState createState() => _GestureSelectionScreenState();
}

class _GestureSelectionScreenState extends State<GestureSelectionScreen> {
  List<Gesture> gestures = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'all';
  final AdminService _adminService = AdminService();

  final List<String> categories = [
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

  final Map<String, String> categoryLabels = {
    'all': 'Все',
    'basic': 'Базовые',
    'greetings': 'Приветствие',
    'questions': 'Вопросы',
    'emotions': 'Эмоции',
    'actions': 'Действия',
    'family': 'Семья',
    'food': 'Еда',
    'numbers': 'Числа',
  };

  @override
  void initState() {
    super.initState();
    _loadGestures();
  }

  Future<void> _loadGestures() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Пытаемся загрузить жесты с сервера
      final loadedGestures = await _adminService.getAllGestures();

      // Если с сервера ничего не пришло, используем тестовые данные
      if (loadedGestures.isEmpty) {
        final testGestures = _createTestGestures();
        setState(() {
          gestures = testGestures;
          isLoading = false;
        });
      } else {
        setState(() {
          gestures = loadedGestures;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading gestures: $e');
      // В случае ошибки используем тестовые данные
      final testGestures = _createTestGestures();
      setState(() {
        gestures = testGestures;
        isLoading = false;
      });
    }
  }

  List<Gesture> _createTestGestures() {
    return [
      Gesture(
        id: '1',
        name: 'Привет',
        description: 'Жест приветствия. Поднимите руку с раскрытой ладонью и помашите ей из стороны в сторону.',
        imagePath: 'assets/gestures/hello.png',
        category: 'greetings',
      ),
      Gesture(
        id: '2',
        name: 'Спасибо',
        description: 'Жест благодарности. Прикоснитесь кончиками пальцев к губам, затем опустите руку вперед.',
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
        description: 'Жест согласия. Покажите большой палец вверх или кивните головой вверх-вниз.',
        imagePath: 'assets/gestures/yes.png',
        category: 'basic',
      ),
      Gesture(
        id: '5',
        name: 'Нет',
        description: 'Жест отрицания. Покачайте головой из стороны в сторону или покажите указательным пальцем.',
        imagePath: 'assets/gestures/no.png',
        category: 'basic',
      ),
      Gesture(
        id: '6',
        name: 'Хорошо',
        description: 'Жест одобрения. Сформируйте кольцо из большого и указательного пальца (знак ОК).',
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
      Gesture(
        id: '9',
        name: 'Помощь',
        description: 'Жест просьбы о помощи. Поднимите обе руки вверх.',
        imagePath: 'assets/gestures/help.png',
        category: 'actions',
      ),
      Gesture(
        id: '10',
        name: 'Любовь',
        description: 'Жест любви. Сложите руки в форме сердца.',
        imagePath: 'assets/gestures/love.png',
        category: 'emotions',
      ),
    ];
  }

  List<Gesture> get filteredGestures {
    List<Gesture> result = gestures;

    // Фильтр по категории
    if (selectedCategory != 'all') {
      result = result.where((gesture) => gesture.category == selectedCategory).toList();
    }

    // Фильтр по поисковому запросу
    if (searchQuery.isNotEmpty) {
      result = result.where((gesture) =>
      gesture.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          gesture.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          gesture.category.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выберите жест для практики'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadGestures,
            tooltip: 'Обновить список жестов',
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'Загрузка жестов...',
              style: TextStyle(color: Colors.grey[600]),
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
                  '• Выберите жест для практики\n• Камера будет распознавать ваши движения\n• Следуйте описанию и инструкциям\n• Практикуйтесь до правильного выполнения',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),

          // Поиск
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск жестов...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 8),

          // Фильтр по категориям
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
                      categoryLabels[category] ?? category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 12,
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
            child: filteredGestures.isEmpty
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
                    searchQuery.isNotEmpty || selectedCategory != 'all'
                        ? 'Нет жестов по вашему запросу'
                        : 'Жесты не найдены',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (searchQuery.isNotEmpty || selectedCategory != 'all') ...[
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                          selectedCategory = 'all';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Сбросить фильтры'),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredGestures.length,
              itemBuilder: (context, index) {
                final gesture = filteredGestures[index];
                return _buildGestureCard(gesture);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureCard(Gesture gesture) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GesturePracticeScreen(
                gesture: gesture,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Иконка/изображение жеста
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.deepPurple[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.deepPurple[200]!,
                    width: 1,
                  ),
                ),
                child: gesture.imagePath.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    gesture.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.gesture,
                        size: 35,
                        color: Colors.deepPurple[700],
                      );
                    },
                  ),
                )
                    : Icon(
                  Icons.gesture,
                  size: 35,
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
                        categoryLabels[gesture.category] ?? gesture.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
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

              // Кнопка практики
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adminService.dispose();
    super.dispose();
  }
}