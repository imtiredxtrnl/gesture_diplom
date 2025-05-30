// lib/screens/admin_gestures_screen.dart
import 'package:flutter/material.dart';
import '../models/gesture.dart';
import '../services/admin_service.dart';
import 'add_gesture_screen.dart';

class AdminGesturesScreen extends StatefulWidget {
  @override
  _AdminGesturesScreenState createState() => _AdminGesturesScreenState();
}

class _AdminGesturesScreenState extends State<AdminGesturesScreen> {
  List<Gesture> gestures = [];
  bool isLoading = true;
  String searchQuery = '';
  final AdminService _adminService = AdminService();

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
      final loadedGestures = await _adminService.getAllGestures();
      setState(() {
        gestures = loadedGestures;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading gestures: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки жестов: $e')),
      );
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

  Future<void> _deleteGesture(Gesture gesture) async {
    try {
      final result = await _adminService.deleteGesture(gesture.id);
      if (result['status'] == 'success') {
        setState(() {
          gestures.removeWhere((g) => g.id == gesture.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Жест "${gesture.name}" удален')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления жеста: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление жестами'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                ? Center(child: CircularProgressIndicator(
              color: Colors.deepPurple,
            ))
                : filteredGestures.isEmpty
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
                    searchQuery.isEmpty ? 'Жесты не найдены' : 'Нет результатов поиска',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (searchQuery.isEmpty) ...[
                    SizedBox(height: 16),
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Добавить первый жест'),
                    ),
                  ],
                ],
              ),
            )
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
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add, color: Colors.white),
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
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text('УДАЛИТЬ'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _deleteGesture(gesture);
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddGestureScreen(gesture: gesture),
              ),
            );
            if (result == true) {
              _loadGestures();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[100],
                    borderRadius: BorderRadius.circular(8),
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
                          color: Colors.deepPurple[700],
                          size: 30,
                        );
                      },
                    ),
                  )
                      : Icon(
                    Icons.gesture,
                    color: Colors.deepPurple[700],
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gesture.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        gesture.description.length > 100
                            ? '${gesture.description.substring(0, 100)}...'
                            : gesture.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit,
                  color: Colors.deepPurple,
                ),
              ],
            ),
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