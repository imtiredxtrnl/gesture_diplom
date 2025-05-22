import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/alphabet_letter.dart';
import 'add_letter_screen.dart';

class AdminAlphabetScreen extends StatefulWidget {
  @override
  _AdminAlphabetScreenState createState() => _AdminAlphabetScreenState();
}

class _AdminAlphabetScreenState extends State<AdminAlphabetScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<AlphabetLetter> ukrainianLetters = [];
  List<AlphabetLetter> englishLetters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLetters();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    try {
      // Создаем тестовые данные для украинского алфавита
      List<String> ukLetters = ['А', 'Б', 'В', 'Г', 'Д'];
      ukrainianLetters = ukLetters.map((letter) => AlphabetLetter(
        id: 'uk_${letter}',
        letter: letter,
        language: 'uk',
        imagePath: 'assets/alphabet/uk/${letter.toLowerCase()}.png',
      )).toList();

      // Создаем тестовые данные для английского алфавита
      List<String> enLetters = ['A', 'B', 'C', 'D', 'E'];
      englishLetters = enLetters.map((letter) => AlphabetLetter(
        id: 'en_${letter}',
        letter: letter,
        language: 'en',
        imagePath: 'assets/alphabet/en/${letter.toLowerCase()}.png',
      )).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading alphabet: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление алфавитом'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Украинский'),
            Tab(text: 'Английский'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildLettersList(ukrainianLetters, 'uk'),
          _buildLettersList(englishLetters, 'en'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final String language = _tabController!.index == 0 ? 'uk' : 'en';
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddLetterScreen(language: language),
            ),
          );
          if (result == true) {
            _loadLetters();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Добавить букву',
      ),
    );
  }

  Widget _buildLettersList(List<AlphabetLetter> letters, String language) {
    return letters.isEmpty
        ? Center(child: Text('Буквы не найдены'))
        : GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        return _buildLetterCard(letter);
      },
    );
  }

  Widget _buildLetterCard(AlphabetLetter letter) {
    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(letter);
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            // В реальном приложении здесь был бы переход на экран редактирования
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Редактирование буквы пока не реализовано')),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                letter.letter,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(AlphabetLetter letter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удаление буквы'),
        content: Text('Вы уверены, что хотите удалить букву "${letter.letter}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ОТМЕНА'),
          ),
          TextButton(
            onPressed: () {
              // В реальном приложении здесь был бы API-запрос на удаление
              setState(() {
                if (letter.language == 'uk') {
                  ukrainianLetters.removeWhere((l) => l.id == letter.id);
                } else {
                  englishLetters.removeWhere((l) => l.id == letter.id);
                }
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Буква "${letter.letter}" удалена')),
              );
            },
            child: Text('УДАЛИТЬ'),
          ),
        ],
      ),
    );
  }
}