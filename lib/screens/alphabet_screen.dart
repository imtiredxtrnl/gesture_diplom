import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/alphabet_letter.dart';
import 'letter_detail_screen.dart';

class AlphabetScreen extends StatefulWidget {
  final String language;

  AlphabetScreen({required this.language});

  @override
  _AlphabetScreenState createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  List<AlphabetLetter> letters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlphabet();
  }

  Future<void> _loadAlphabet() async {
    try {
      // В реальном приложении, здесь должен быть запрос к API или локальной БД
      // Для примера создаем тестовые данные
      List<AlphabetLetter> testLetters = [];

      if (widget.language == 'uk') {
        List<String> ukrainianLetters = ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Є', 'Ж', 'З', 'И', 'І', 'Ї', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ь', 'Ю', 'Я'];
        for (int i = 0; i < ukrainianLetters.length; i++) {
          testLetters.add(AlphabetLetter(
            id: 'uk_${i}',
            letter: ukrainianLetters[i],
            language: 'uk',
            imagePath: 'assets/alphabet/uk/${ukrainianLetters[i].toLowerCase()}.png',
          ));
        }
      } else {
        List<String> englishLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
        for (int i = 0; i < englishLetters.length; i++) {
          testLetters.add(AlphabetLetter(
            id: 'en_${i}',
            letter: englishLetters[i],
            language: 'en',
            imagePath: 'assets/alphabet/en/${englishLetters[i].toLowerCase()}.png',
          ));
        }
      }

      setState(() {
        letters = testLetters;
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
    String title = widget.language == 'uk' ? 'Украинский алфавит' : 'Английский алфавит';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : letters.isEmpty
          ? Center(child: Text('Алфавит не найден'))
          : GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          return _buildLetterCard(context, letters[index]);
        },
      ),
    );
  }

  Widget _buildLetterCard(BuildContext context, AlphabetLetter letter) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LetterDetailScreen(letter: letter),
            ),
          );
        },
        child: Center(
          child: Text(
            letter.letter,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}