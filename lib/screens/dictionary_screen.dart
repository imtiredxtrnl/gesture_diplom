// lib/screens/dictionary_screen.dart
import 'package:flutter/material.dart';
import '../models/gesture.dart';
import '../services/gesture_data_service.dart';
import 'gesture_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final GestureDataService _gestureService = GestureDataService();
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

    // Добавляем слушатель для обновлений
    _gestureService.addListener(_onGesturesUpdated);
  }

  @override
  void dispose() {
    // Удаляем слушатель при уничтожении виджета
    _gestureService.removeListener(_onGesturesUpdated);
    super.dispose();
  }

  void _onGesturesUpdated() {
    if (mounted) {
      _loadGestures();
    }
  }

  Future<void> _loadGestures() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Инициализируем жесты если они еще не загружены
      await _gestureService.initializeGestures();

      setState(() {
        gestures = _gestureService.getAllGestures();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading gestures: $e');

      // Показываем сообщение об ошибке
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки жестов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Gesture> get filteredGestures {
    List<Gesture> result = gestures;

    // Фильтрация по категории
    if (selectedCategory != 'all') {
      result = result.where((gesture) => gesture.category == selectedCategory).toList();
    }

    // Фильтрация по поисковому запросу
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
        return 'Основные';
      case 'greetings':
        return 'Приветствия';
      case 'questions':
        return 'Вопросы';
      case 'emotions':
        return 'Эмоции';
      case 'actions':
        return 'Действия';
      case 'family':
        return 'Семья';
      case 'food':
        return 'Еда';
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
        title: Text('Словарь жестов'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadGestures,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск жестов...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
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
                  Text('Загрузка жестов...'),
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
                    searchQuery.isNotEmpty
                        ? 'Жесты не найдены'
                        : 'Нет жестов в данной категории',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (searchQuery.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Попробуйте изменить поисковый запрос',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadGestures,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filteredGestures.length,
                itemBuilder: (context, index) {
                  final gesture = filteredGestures[index];
                  return _buildGestureCard(gesture);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureCard(Gesture gesture) {
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
              // Изображение жеста или заглушка
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: gesture.imagePath.isNotEmpty
                      ? Image.asset(
                    gesture.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.gesture,
                        size: 30,
                        color: Colors.grey[400],
                      );
                    },
                  )
                      : Icon(
                    Icons.gesture,
                    size: 30,
                    color: Colors.grey[400],
                  ),
                ),
              ),

              SizedBox(width: 12),

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
                              fontSize: 12,
                              color: Colors.deepPurple[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
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

              // Стрелка
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
  }
}