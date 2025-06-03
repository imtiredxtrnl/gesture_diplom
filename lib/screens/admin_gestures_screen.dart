// lib/screens/admin_gestures_screen.dart
import 'package:flutter/material.dart';
import '../models/gesture.dart';
import '../services/gesture_data_service.dart';
import 'add_gesture_screen.dart';
import 'edit_gesture_screen.dart';


class AdminGesturesScreen extends StatefulWidget {
  @override
  _AdminGesturesScreenState createState() => _AdminGesturesScreenState();
}

class _AdminGesturesScreenState extends State<AdminGesturesScreen> {
  final GestureDataService _gestureService = GestureDataService();
  List<Gesture> gestures = [];
  bool isLoading = true;
  String searchQuery = '';

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
    if (searchQuery.isEmpty) {
      return gestures;
    }
    return gestures.where((gesture) =>
    gesture.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        gesture.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
        gesture.description.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
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

  Future<void> _deleteGesture(Gesture gesture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удаление жеста'),
        content: Text('Вы уверены, что хотите удалить жест "${gesture.name}"?\n\nЭто действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ОТМЕНА'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('УДАЛИТЬ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _gestureService.deleteGesture(gesture.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Жест "${gesture.name}" удален'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'ОТМЕНИТЬ',
                onPressed: () async {
                  // Восстанавливаем удаленный жест
                  await _gestureService.addGesture(gesture);
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при удалении жеста: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление жестами'),
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

          // Статистика
          if (!isLoading)
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    'Всего жестов: ${gestures.length}',
                    style: TextStyle(
                      color: Colors.deepPurple[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (searchQuery.isNotEmpty) ...[
                    Text(
                      ' • Найдено: ${filteredGestures.length}',
                      style: TextStyle(
                        color: Colors.deepPurple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          SizedBox(height: 16),

          // Список жестов
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
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
                    Icons.gesture_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'Жесты не найдены'
                        : 'Нет жестов для отображения',
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
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddGestureScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadGestures();
                      }
                    },
                    icon: Icon(Icons.add),
                    label: Text('Добавить первый жест'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadGestures,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredGestures.length,
                itemBuilder: (context, index) {
                  final gesture = filteredGestures[index];
                  return _buildGestureItem(gesture);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGestureScreen()),
          );
          if (result == true) {
            _loadGestures();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Добавить жест',
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGestureItem(Gesture gesture) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditGestureScreen(gesture: gesture),
            ),
          );
          if (result == true) {
            _loadGestures();
          }
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getCategoryDisplayName(gesture.category),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.deepPurple[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      gesture.description.length > 60
                          ? '${gesture.description.substring(0, 60)}...'
                          : gesture.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: ${gesture.id}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Кнопки действий
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditGestureScreen(gesture: gesture),
                        ),
                      );
                      if (result == true) {
                        _loadGestures();
                      }
                    },
                    tooltip: 'Редактировать',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteGesture(gesture),
                    tooltip: 'Удалить',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}