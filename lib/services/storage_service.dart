import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_model.dart';

class StorageService {
  static const String COMPLETED_TESTS_KEY = 'completed_tests';

  // Сохранение пройденного теста локально
  static Future<bool> saveCompletedTest(String testId, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> allCompletedTests = await _getCompletedTestsMap(prefs);

      // Получаем список пройденных тестов для данного пользователя
      List<String> userCompletedTests = allCompletedTests[username] != null
          ? List<String>.from(allCompletedTests[username])
          : [];

      // Если тест еще не отмечен как пройденный, добавляем его
      if (!userCompletedTests.contains(testId)) {
        userCompletedTests.add(testId);
        allCompletedTests[username] = userCompletedTests;

        // Сохраняем обновленный список
        await prefs.setString(COMPLETED_TESTS_KEY, json.encode(allCompletedTests));
        return true;
      }

      return false;
    } catch (e) {
      print('Error saving completed test: $e');
      return false;
    }
  }

  // Получение списка пройденных тестов для пользователя
  static Future<List<String>> getCompletedTests(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> allCompletedTests = await _getCompletedTestsMap(prefs);

      return allCompletedTests[username] != null
          ? List<String>.from(allCompletedTests[username])
          : [];
    } catch (e) {
      print('Error getting completed tests: $e');
      return [];
    }
  }

  // Вспомогательный метод для получения всех пройденных тестов
  static Future<Map<String, dynamic>> _getCompletedTestsMap(SharedPreferences prefs) async {
    final String? completedTestsJson = prefs.getString(COMPLETED_TESTS_KEY);

    if (completedTestsJson != null && completedTestsJson.isNotEmpty) {
      return json.decode(completedTestsJson);
    }

    return {};
  }

  // Сброс результатов тестов для пользователя
  static Future<bool> resetCompletedTests(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> allCompletedTests = await _getCompletedTestsMap(prefs);

      allCompletedTests[username] = [];

      await prefs.setString(COMPLETED_TESTS_KEY, json.encode(allCompletedTests));
      return true;
    } catch (e) {
      print('Error resetting completed tests: $e');
      return false;
    }
  }
}