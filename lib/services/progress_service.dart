import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/gesture.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;

  ProgressService._internal();

  // Ключи для SharedPreferences
  static const String _learnedGesturesKey = 'learned_gestures';
  static const String _sessionCountKey = 'session_count';
  static const String _accuracyKey = 'accuracy';

  // Сохранение изученного жеста
  Future<void> saveLearnedGesture(Gesture gesture, double accuracy) async {
    final prefs = await SharedPreferences.getInstance();

    // Загрузка существующих жестов
    final learnedGestures = await getLearnedGestures();

    // Проверка, есть ли уже этот жест
    final existingIndex = learnedGestures.indexWhere((g) => g.name == gesture.name);

    if (existingIndex >= 0) {
      // Обновляем существующий жест
      learnedGestures[existingIndex] = gesture.copyWith(isLearned: true);
    } else {
      // Добавляем новый жест
      learnedGestures.add(gesture.copyWith(isLearned: true));
    }

    // Сохраняем обновленный список
    final learnedGesturesJson = learnedGestures
        .map((g) => g.toJson())
        .toList();

    await prefs.setString(_learnedGesturesKey, json.encode(learnedGesturesJson));

    // Обновляем счетчик сессий
    final sessionCount = await getSessionCount();
    await prefs.setInt(_sessionCountKey, sessionCount + 1);

    // Обновляем среднюю точность
    final currentAccuracy = await getAverageAccuracy();
    final newAccuracy = (currentAccuracy * sessionCount + accuracy) / (sessionCount + 1);
    await prefs.setDouble(_accuracyKey, newAccuracy);
  }

  // Получение списка изученных жестов
  Future<List<Gesture>> getLearnedGestures() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_learnedGesturesKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final List jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => Gesture.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading learned gestures: $e');
      return [];
    }
  }

  // Получение количества сессий обучения
  Future<int> getSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionCountKey) ?? 0;
  }

  // Получение средней точности распознавания
  Future<double> getAverageAccuracy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_accuracyKey) ?? 0.0;
  }

  // Проверка, изучен ли жест
  Future<bool> isGestureLearned(String gestureName) async {
    final learnedGestures = await getLearnedGestures();
    return learnedGestures.any((g) => g.name == gestureName);
  }

  // Сброс всего прогресса (для тестирования)
  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_learnedGesturesKey);
    await prefs.remove(_sessionCountKey);
    await prefs.remove(_accuracyKey);
  }
}