import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/gesture.dart';
import 'add_gesture_screen.dart';

class AdminGesturesScreen extends StatefulWidget {
  @override
  _AdminGesturesScreenState createState() => _AdminGesturesScreenState();
}

class _AdminGesturesScreenState extends State<AdminGesturesScreen> {
  List<Gesture> gestures = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGestures();
  }

  Future<void> _loadGestures() async {
    try {
      // Создаем тестовые данные жестов
      List<Gesture> testGestures = [
        Gesture(
          id: '1',
          name: 'Привет',
          description: 'Жест приветствия, который используется для начала разговора или при встрече с кем-то.',
          imagePath: 'assets/gestures/hello.png',
          category: 'greetings',
        ),
        Gesture(
          id: '2',
          name: 'Спасибо',
          description: 'Жест благодарности, который выражает признательность за что-либо.',
          imagePath: 'assets/gestures/thank_you.png',
          category: 'basic',
        ),
        Gesture(
          id: '3',
          name: 'Пожалуйста',
          description: 'Жест вежливой просьбы или ответа на благодарность.',
          imagePath: 'assets/gestures/please.png',
          category: 'basic',
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
    if (searchQuery.isEmpty) {
      return gestures;
    }
    return gestures.where((gesture) =>
    gesture.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        gesture.category.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
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
                hintText: 'Поиск жестов...',
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
                : filteredGestures.isEmpty
                ? Center(child: Text('Жесты не найдены'))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredGestures.length,
              itemBuilder: (context, index) {
                final gesture = filteredGestures[index];
                return _buildGestureItem(gesture);
              },
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
      ),
    );
  }

  Widget _buildGestureItem(Gesture gesture) {
    return Dismissible(
      key: Key(gesture.id),
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
            title: Text('Удаление жеста'),
            content: Text('Вы уверены, что хотите удалить жест "${gesture.name}"?'),
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
          gestures.removeWhere((g) => g.id == gesture.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Жест "${gesture.name}" удален')),
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
              Icons.gesture,
              color: Colors.grey[600],
            ),
          ),
          title: Text(
            gesture.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Категория: ${gesture.category}\n${gesture.description.substring(0, gesture.description.length > 50 ? 50 : gesture.description.length)}${gesture.description.length > 50 ? "..." : ""}',
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              // В реальном приложении здесь был бы переход на экран редактирования
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Редактирование жеста пока не реализовано')),
              );
            },
          ),
        ),
      ),
    );
  }
}