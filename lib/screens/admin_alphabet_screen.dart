// lib/screens/admin_alphabet_screen.dart
import 'package:flutter/material.dart';
import '../models/alphabet_letter.dart';
import '../services/admin_service.dart';
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
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLetters();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _adminService.dispose();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Загружаем украинские буквы
      final ukrainianLoadedLetters = await _adminService.getAllLetters(language: 'uk');

      // Загружаем английские буквы
      final englishLoadedLetters = await _adminService.getAllLetters(language: 'en');

      setState(() {
        ukrainianLetters = ukrainianLoadedLetters;
        englishLetters = englishLoadedLetters;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading alphabet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки алфавита: $e')),
      );
    }
  }

  Future<void> _deleteLetter(AlphabetLetter letter) async {
    try {
      final result = await _adminService.deleteLetter(letter.id);
      if (result['status'] == 'success') {
        setState(() {
          if (letter.language == 'uk') {
            ukrainianLetters.removeWhere((l) => l.id == letter.id);
          } else {
            englishLetters.removeWhere((l) => l.id == letter.id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Буква "${letter.letter}" удалена')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления буквы: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Управление алфавитом'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLetters,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Icon(Icons.flag),
              text: 'Украинский',
            ),
            Tab(
              icon: Icon(Icons.flag_outlined),
              text: 'Английский',
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
        color: Colors.deepPurple,
      ))
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
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Добавить букву',
      ),
    );
  }

  Widget _buildLettersList(List<AlphabetLetter> letters, String language) {
    if (letters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.text_fields,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Буквы не найдены',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text('Добавить первую букву'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
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
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddLetterScreen(
                  language: letter.language,
                  letter: letter,
                ),
              ),
            );
            if (result == true) {
              _loadLetters();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple[100]!,
                  Colors.deepPurple[50]!,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      letter.letter,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[700],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: letter.imagePath.isNotEmpty
                        ? Colors.green[100]
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    letter.imagePath.isNotEmpty ? Icons.image : Icons.image_not_supported,
                    size: 14,
                    color: letter.imagePath.isNotEmpty
                        ? Colors.green[600]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
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
              Navigator.of(context).pop();
              _deleteLetter(letter);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('УДАЛИТЬ'),
          ),
        ],
      ),
    );
  }
}