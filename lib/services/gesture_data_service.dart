// lib/services/gesture_data_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gesture.dart';

class GestureDataService {
  static final GestureDataService _instance = GestureDataService._internal();
  factory GestureDataService() => _instance;
  GestureDataService._internal();

  static const String _gesturesKey = 'gestures_data';
  List<Gesture> _gestures = [];

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
  Future<void> initializeGestures() async {
    final prefs = await SharedPreferences.getInstance();
    final gesturesJson = prefs.getString(_gesturesKey);

    if (gesturesJson != null) {
      // Загружаем сохраненные жесты
      try {
        final List<dynamic> jsonList = json.decode(gesturesJson);
        _gestures = jsonList.map((json) => Gesture.fromJson(json)).toList();
      } catch (e) {
        print('Error loading gestures: $e');
        _initializeDefaultGestures();
      }
    } else {
      // Инициализируем с тестовыми данными
      _initializeDefaultGestures();
      await _saveGestures();
    }
  }

  void _initializeDefaultGestures() {
    _gestures = [
      Gesture(
        id: '1',
        name: 'Привет',
        description: 'Жест приветствия. Поднимите руку с раскрытой ладонью и помашите ей.',
        imagePath: 'lib/assets/gestures/hello.png',
        category: 'greetings',
      ),
      Gesture(
        id: '2',
        name: 'Спасибо',
        description: 'Жест благодарности. Прикоснитесь пальцами к губам, затем опустите руку вперед.',
        imagePath: 'lib/assets/gestures/thank_you.png',
        category: 'basic',
      ),
      Gesture(
        id: '3',
        name: 'Пожалуйста',
        description: 'Жест вежливой просьбы. Положите открытую ладонь на грудь и сделайте круговое движение.',
        imagePath: 'lib/assets/gestures/please.png',
        category: 'basic',
      ),
      Gesture(
        id: '4',
        name: 'Да',
        description: 'Жест согласия. Покажите большой палец вверх или кивните головой.',
        imagePath: 'lib/assets/gestures/yes.png',
        category: 'basic',
      ),
      Gesture(
        id: '5',
        name: 'Нет',
        description: 'Жест отрицания. Покачайте головой или покажите указательным пальцем из стороны в сторону.',
        imagePath: 'lib/assets/gestures/no.png',
        category: 'basic',
      ),
      Gesture(
        id: '6',
        name: 'Хорошо',
        description: 'Жест одобрения. Сформируйте кольцо из большого и указательного пальца.',
        imagePath: 'lib/assets/gestures/ok.png',
        category: 'emotions',
      ),
      Gesture(
        id: '7',
        name: 'Плохо',
        description: 'Жест неодобрения. Покажите большой палец вниз.',
        imagePath: 'lib/assets/gestures/bad.png',
        category: 'emotions',
      ),
      Gesture(
        id: '8',
        name: 'Стоп',
        description: 'Жест остановки. Поднимите руку с открытой ладонью перед собой.',
        imagePath: 'lib/assets/gestures/stop.png',
        category: 'actions',
      ),
    ];
  }

  // Сохранение жестов в SharedPreferences
  Future<void> _saveGestures() async {
    final prefs = await SharedPreferences.getInstance();
    final gesturesJson = json.encode(_gestures.map((g) => g.toJson()).toList());
    await prefs.setString(_gesturesKey, gesturesJson);
  }

  // Получение всех жестов
  List<Gesture> getAllGestures() {
    return List.from(_gestures);
  }

  // Получение жеста по ID
  Gesture? getGestureById(String id) {
    try {
      return _gestures.firstWhere((gesture) => gesture.id == id);
    } catch (e) {
      return null;
    }
  }

  // Добавление нового жеста
  Future<void> addGesture(Gesture gesture) async {
    _gestures.add(gesture);
    await _saveGestures();
    _notifyListeners();
  }

  // Обновление жеста
  Future<void> updateGesture(Gesture updatedGesture) async {
    final index = _gestures.indexWhere((g) => g.id == updatedGesture.id);
    if (index != -1) {
      _gestures[index] = updatedGesture;
      await _saveGestures();
      _notifyListeners();
    }
  }

  // Удаление жеста
  Future<void> deleteGesture(String id) async {
    _gestures.removeWhere((gesture) => gesture.id == id);
    await _saveGestures();
    _notifyListeners();
  }

  // Фильтрация жестов по категории
  List<Gesture> getGesturesByCategory(String category) {
    if (category == 'all') {
      return getAllGestures();
    }
    return _gestures.where((gesture) => gesture.category == category).toList();
  }

  // Поиск жестов
  List<Gesture> searchGestures(String query) {
    if (query.isEmpty) {
      return getAllGestures();
    }

    final lowercaseQuery = query.toLowerCase();
    return _gestures.where((gesture) =>
    gesture.name.toLowerCase().contains(lowercaseQuery) ||
        gesture.description.toLowerCase().contains(lowercaseQuery) ||
        gesture.category.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Генерация уникального ID для нового жеста
  String _generateUniqueId() {
    final existingIds = _gestures.map((g) => int.tryParse(g.id) ?? 0).toList();
    final maxId = existingIds.isEmpty ? 0 : existingIds.reduce((a, b) => a > b ? a : b);
    return (maxId + 1).toString();
  }

  // Создание нового жеста с автоматическим ID
  Gesture createGesture({
    required String name,
    required String description,
    required String imagePath,
    required String category,
  }) {
    return Gesture(
      id: _generateUniqueId(),
      name: name,
      description: description,
      imagePath: imagePath,
      category: category,
    );
  }
}