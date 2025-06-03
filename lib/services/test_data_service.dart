// lib/services/test_data_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_model.dart';

class TestDataService {
  static final TestDataService _instance = TestDataService._internal();
  factory TestDataService() => _instance;
  TestDataService._internal();

  static const String _testsKey = 'tests_data';
  List<Test> _tests = [];

  // Список слушателей для уведомления об изменениях
  final List<Function()> _listeners = [];

  // Добавление слушателя
  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  // Удаление слушателя
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  // Уведомление всех слушателей об изменениях
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Инициализация с тестовыми данными
  Future<void> initializeTests() async {
    final prefs = await SharedPreferences.getInstance();
    final testsJson = prefs.getString(_testsKey);

    if (testsJson != null) {
      // Загружаем сохраненные тесты
      try {
        final List<dynamic> jsonList = json.decode(testsJson);
        _tests = jsonList.map((json) => Test.fromJson(json)).toList();
      } catch (e) {
        print('Error loading tests: $e');
        _initializeDefaultTests();
      }
    } else {
      // Инициализируем с тестовыми данными
      _initializeDefaultTests();
      await _saveTests();
    }
  }

  void _initializeDefaultTests() {
    _tests = [
      Test(
        id: '1',
        question: 'Какой жест обозначает "Привет"?',
        options: [
          'Поднятая рука с раскрытой ладонью',
          'Сжатый кулак',
          'Указательный палец направлен вверх',
          'Две руки скрещены на груди'
        ],
        correctOptionIndex: 0,
        category: 'greetings',
      ),
      Test(
        id: '2',
        question: 'Какой жест обозначает "Спасибо"?',
        options: [
          'Сжатый кулак',
          'Рука прикладывается к губам и затем опускается вперед',
          'Руки скрещены над головой',
          'Большой палец вверх'
        ],
        correctOptionIndex: 1,
        category: 'basic',
      ),
      Test(
        id: '3',
        question: 'Какой жест означает "Да"?',
        options: [
          'Качание головой влево-вправо',
          'Кивание головой вверх-вниз',
          'Поднятие плеч',
          'Указание пальцем'
        ],
        correctOptionIndex: 1,
        category: 'basic',
      ),
      Test(
        id: '4',
        question: 'Какой жест означает "Нет"?',
        options: [
          'Качание головой влево-вправо',
          'Кивание головой вверх-вниз',
          'Поднятие плеч',
          'Большой палец вверх'
        ],
        correctOptionIndex: 0,
        category: 'basic',
      ),
      Test(
        id: '5',
        question: 'Какой жест обозначает "Пожалуйста"?',
        options: [
          'Рука прикладывается к груди и делает круговое движение',
          'Большой палец вверх',
          'Указательный палец вверх',
          'Две руки вместе'
        ],
        correctOptionIndex: 0,
        category: 'basic',
      ),
      Test(
        id: '6',
        question: 'Какой жест означает "Хорошо"?',
        options: [
          'Большой палец вниз',
          'Кольцо из большого и указательного пальца',
          'Сжатый кулак',
          'Открытая ладонь'
        ],
        correctOptionIndex: 1,
        category: 'emotions',
      ),
      Test(
        id: '7',
        question: 'Какой жест означает "Стоп"?',
        options: [
          'Указательный палец вверх',
          'Сжатый кулак',
          'Открытая ладонь перед собой',
          'Большой палец вниз'
        ],
        correctOptionIndex: 2,
        category: 'actions',
      ),
    ];
  }

  // Сохранение тестов в SharedPreferences
  Future<void> _saveTests() async {
    final prefs = await SharedPreferences.getInstance();
    final testsJson = json.encode(_tests.map((t) => t.toJson()).toList());
    await prefs.setString(_testsKey, testsJson);
  }

  // Получение всех тестов
  List<Test> getAllTests() {
    return List.from(_tests);
  }

  // Получение теста по ID
  Test? getTestById(String id) {
    try {
      return _tests.firstWhere((test) => test.id == id);
    } catch (e) {
      return null;
    }
  }

  // Добавление нового теста
  Future<void> addTest(Test test) async {
    _tests.add(test);
    await _saveTests();
    _notifyListeners();
  }

  // Обновление теста
  Future<void> updateTest(Test updatedTest) async {
    final index = _tests.indexWhere((t) => t.id == updatedTest.id);
    if (index != -1) {
      _tests[index] = updatedTest;
      await _saveTests();
      _notifyListeners();
    }
  }

  // Удаление теста
  Future<void> deleteTest(String id) async {
    _tests.removeWhere((test) => test.id == id);
    await _saveTests();
    _notifyListeners();
  }

  // Фильтрация тестов по категории
  List<Test> getTestsByCategory(String category) {
    if (category == 'all') {
      return getAllTests();
    }
    return _tests.where((test) => test.category == category).toList();
  }

  // Поиск тестов
  List<Test> searchTests(String query) {
    if (query.isEmpty) {
      return getAllTests();
    }

    final lowercaseQuery = query.toLowerCase();
    return _tests.where((test) =>
    test.question.toLowerCase().contains(lowercaseQuery) ||
        test.category.toLowerCase().contains(lowercaseQuery) ||
        test.options.any((option) => option.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  // Генерация уникального ID для нового теста
  String _generateUniqueId() {
    final existingIds = _tests.map((t) => int.tryParse(t.id) ?? 0).toList();
    final maxId = existingIds.isEmpty ? 0 : existingIds.reduce((a, b) => a > b ? a : b);
    return (maxId + 1).toString();
  }

  // Создание нового теста с автоматическим ID
  Test createTest({
    required String question,
    required List<String> options,
    required int correctOptionIndex,
    required String category,
  }) {
    return Test(
      id: _generateUniqueId(),
      question: question,
      options: options,
      correctOptionIndex: correctOptionIndex,
      category: category,
    );
  }

  // Получение статистики
  Map<String, int> getStatistics() {
    final stats = <String, int>{};

    stats['total'] = _tests.length;

    // Подсчет по категориям
    for (final test in _tests) {
      final category = test.category;
      stats[category] = (stats[category] ?? 0) + 1;
    }

    return stats;
  }

  // Получение категорий с количеством тестов
  Map<String, int> getCategoriesWithCount() {
    final categoriesCount = <String, int>{};

    for (final test in _tests) {
      final category = test.category;
      categoriesCount[category] = (categoriesCount[category] ?? 0) + 1;
    }

    return categoriesCount;
  }
}