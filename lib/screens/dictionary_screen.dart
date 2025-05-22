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
      // В реальном приложении здесь был бы API-запрос
      // Для примера загружаем из JSON-файла
      final jsonString = await rootBundle.loadString('assets/data/gestures.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      setState(() {
        gestures = jsonList.map((json) => Gesture.fromJson(json)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Словарь жестов'),
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
                      category == 'all' ? 'Все' : category,
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
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(gesture.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      gesture.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      gesture.description.length > 80
                          ? '${gesture.description.substring(0, 80)}...'
                          : gesture.description,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GestureDetailScreen(gesture: gesture),
                        ),
                      );
                    },
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