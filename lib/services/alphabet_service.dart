import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/alphabet_letter.dart';

class AlphabetService extends ChangeNotifier {
  static final AlphabetService _instance = AlphabetService._internal();
  factory AlphabetService() => _instance;

  Map<String, List<AlphabetLetter>> _alphabet = {
    'uk': [],
    'en': []
  };
  bool _initialized = false;
  final String _baseUrl = 'http://localhost:8080/api';

  AlphabetService._internal();

  List<AlphabetLetter> getLetters(String language) {
    return List.from(_alphabet[language] ?? []);
  }

  Future<void> initializeAlphabet() async {
    if (_initialized) return;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/alphabet'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        _alphabet = {
          'uk': (data['alphabet']['uk'] as List)
              .map((letter) => AlphabetLetter.fromJson(letter))
              .toList(),
          'en': (data['alphabet']['en'] as List)
              .map((letter) => AlphabetLetter.fromJson(letter))
              .toList(),
        };
        
        _initialized = true;
        notifyListeners();
      } else {
        throw Exception('Помилка завантаження алфавіту: ${response.statusCode}');
      }
    } catch (e) {
      print('Помилка ініціалізації алфавіту: $e');
      rethrow;
    }
  }

  Future<AlphabetLetter> addLetter(String letter, String description, String language, File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/alphabet'));
      
      // Добавляем данные буквы
      request.fields['data'] = json.encode({
        'letter': letter,
        'description': description,
        'language': language,
      });
      
      // Добавляем изображение
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        final newLetter = AlphabetLetter.fromJson(data['letter']);
        
        _alphabet[language]?.add(newLetter);
        notifyListeners();
        
        return newLetter;
      } else {
        throw Exception('Помилка додавання літери: ${response.statusCode}');
      }
    } catch (e) {
      print('Помилка додавання літери: $e');
      rethrow;
    }
  }

  Future<void> deleteLetter(String id, String language) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/alphabet/$language/$id'));
      
      if (response.statusCode == 200) {
        _alphabet[language]?.removeWhere((letter) => letter.id == id);
        notifyListeners();
      } else {
        throw Exception('Помилка видалення літери: ${response.statusCode}');
      }
    } catch (e) {
      print('Помилка видалення літери: $e');
      rethrow;
    }
  }

  List<AlphabetLetter> searchLetters(String query, String language) {
    if (query.isEmpty) {
      return getLetters(language);
    }

    final lowerQuery = query.toLowerCase();
    return _alphabet[language]?.where((letter) =>
        letter.letter.toLowerCase().contains(lowerQuery) ||
        letter.description.toLowerCase().contains(lowerQuery)
    ).toList() ?? [];
  }
} 