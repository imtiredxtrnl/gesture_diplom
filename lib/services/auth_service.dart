import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import '../models/user_model.dart';

class AuthService {
  static final storage = FlutterSecureStorage();
  static User? currentUser;
  static WebSocketChannel? _channel;
  static final StreamController<Map<String, dynamic>> _responseController =
  StreamController<Map<String, dynamic>>.broadcast();

  // URL сервера для WebSocket соединения
  static const String serverUrl = 'ws://10.0.2.2:8765';

  // Инициализация WebSocket соединения
  static Future<void> _initWebSocket() async {
    if (_channel == null) {
      try {
        _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
        _channel!.stream.listen(
              (message) {
            try {
              final response = json.decode(message);
              _responseController.add(response);
            } catch (e) {
              print('Error parsing response: $e');
            }
          },
          onError: (error) {
            print('WebSocket error: $error');
            _channel = null;
          },
          onDone: () {
            print('WebSocket connection closed');
            _channel = null;
          },
        );
      } catch (e) {
        print('Failed to connect to WebSocket: $e');
        _channel = null;
      }
    }
  }

  // Отправка запроса через WebSocket и ожидание ответа
  static Future<Map<String, dynamic>> _sendRequest(Map<String, dynamic> request) async {
    await _initWebSocket();

    if (_channel == null) {
      return {'status': 'error', 'message': 'Failed to connect to server'};
    }

    final completer = Completer<Map<String, dynamic>>();
    late StreamSubscription subscription;

    // Устанавливаем таймаут
    final timer = Timer(Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete({'status': 'error', 'message': 'Request timeout'});
      }
    });

    subscription = _responseController.stream.listen((response) {
      // Проверяем, является ли этот ответ для нашего запроса
      if (request['type'] == 'auth' && (response.containsKey('status') || response.containsKey('user'))) {
        timer.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      } else if (request['type'] == 'user' && response.containsKey('status')) {
        timer.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }
    });

    try {
      _channel!.sink.add(json.encode(request));
      return await completer.future;
    } catch (e) {
      timer.cancel();
      subscription.cancel();
      return {'status': 'error', 'message': 'Failed to send request: $e'};
    }
  }

  // Функция для проверки, авторизован ли пользователь
  static Future<bool> isAuthenticated() async {
    if (currentUser != null) {
      return true;
    }

    // Проверяем сохраненные учетные данные
    final credentials = await loadUserCredentials();
    final username = credentials['username'];
    final password = credentials['password'];

    if (username != null && password != null) {
      try {
        final result = await login(username, password);
        return result['status'] == 'Login successful' || result['status'] == 'success';
      } catch (e) {
        print('Error checking authentication: $e');
      }
    }

    return false;
  }

  // Функция для автоматической авторизации с сохраненными данными
  static Future<bool> autoLogin() async {
    final credentials = await loadUserCredentials();
    final username = credentials['username'];
    final password = credentials['password'];

    if (username != null && password != null) {
      try {
        final result = await login(username, password);
        return result['status'] == 'Login successful' || result['status'] == 'success';
      } catch (e) {
        print('Error auto-logging in: $e');
      }
    }

    return false;
  }

  // Функция регистрации
  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await _sendRequest({
      'type': 'auth',
      'action': 'register',
      'email': email,
      'password': password,
      'name': name,
      'role': 'user',
      'completedNotes': [],
      'completedTests': [],
      'completedGestures': [],
    });
    return response;
  }

  // Функция логина
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final request = {
      'type': 'auth',
      'action': 'login',
      'username': username,
      'password': password,
    };

    try {
      final responseData = await _sendRequest(request);
      if ((responseData['status'] == 'Login successful' || responseData['status'] == 'success') && responseData['user'] != null) {
        currentUser = User.fromJson(responseData['user']);
        await saveUserCredentials(username, password, currentUser!.role);
      }
      return responseData;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Сохранение данных пользователя в кэш
  static Future<void> saveUserCredentials(String username, String password, String role) async {
    await storage.write(key: 'username', value: username);
    await storage.write(key: 'password', value: password);
    await storage.write(key: 'role', value: role);
  }

  // Загрузка данных пользователя из кэша
  static Future<Map<String, String?>> loadUserCredentials() async {
    final username = await storage.read(key: 'username');
    final password = await storage.read(key: 'password');
    final role = await storage.read(key: 'role');
    return {'username': username, 'password': password, 'role': role};
  }

  // Проверка роли пользователя
  static bool isAdmin() {
    return currentUser?.role == 'admin';
  }

  // Удаление данных пользователя из кэша
  static Future<void> deleteUserCredentials() async {
    await storage.delete(key: 'username');
    await storage.delete(key: 'password');
    await storage.delete(key: 'role');
    currentUser = null;
    _channel?.sink.close();
    _channel = null;
  }

  // Обновление списка пройденных тестов
  static Future<bool> saveCompletedTest(String testId) async {
    if (currentUser == null) return false;

    try {
      if (!currentUser!.completedTests.contains(testId)) {
        List<String> updatedTests = List.from(currentUser!.completedTests)..add(testId);

        final request = {
          'type': 'user',
          'action': 'update_tests',
          'username': currentUser!.username,
          'completedTests': updatedTests,
        };

        final response = await _sendRequest(request);

        if (response['status'] == 'success') {
          // Обновление локального состояния
          currentUser = User(
            username: currentUser!.username,
            password: currentUser!.password,
            profileImage: currentUser!.profileImage,
            role: currentUser!.role,
            completedTests: updatedTests,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error saving completed test: $e');
      return false;
    }
  }

  // Обновление списка пройденных конспектов
  static Future<bool> saveCompletedNote(String noteId) async {
    if (currentUser == null) return false;

    try {
      if (!currentUser!.completedNotes.contains(noteId)) {
        List<String> updatedNotes = List.from(currentUser!.completedNotes ?? [])..add(noteId);

        final request = {
          'type': 'user',
          'action': 'update_profile',
          'username': currentUser!.username,
          'data': {
            'completedNotes': updatedNotes,
          },
        };

        final response = await _sendRequest(request);

        if (response['status'] == 'success') {
          // Обновление локального состояния
          currentUser = User(
            username: currentUser!.username,
            password: currentUser!.password,
            profileImage: currentUser!.profileImage,
            role: currentUser!.role,
            completedTests: currentUser!.completedTests,
            completedNotes: updatedNotes,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error saving completed note: $e');
      return false;
    }
  }

  // Обновление профиля пользователя
  static Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    if (currentUser == null) {
      return {'status': 'error', 'message': 'User not logged in'};
    }

    final request = {
      'type': 'user',
      'action': 'update_profile',
      'username': currentUser!.username,
      'data': userData,
    };

    try {
      final responseData = await _sendRequest(request);

      if (responseData['status'] == 'success' && responseData['user'] != null) {
        // Обновляем данные текущего пользователя
        currentUser = User.fromJson(responseData['user']);

        // Если имя пользователя изменилось, нужно обновить его в хранилище
        if (userData['username'] != null && userData['username'] != currentUser!.username) {
          await storage.write(key: 'username', value: userData['username']);
        }
      }

      return responseData;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Сброс прогресса тестов
  static Future<bool> resetCompletedTests(String username) async {
    try {
      final request = {
        'type': 'user',
        'action': 'reset_tests',
        'username': username,
      };

      final responseData = await _sendRequest(request);

      if (responseData['status'] == 'success') {
        // Обновляем данные текущего пользователя
        if (currentUser != null && currentUser!.username == username) {
          currentUser = User(
            username: currentUser!.username,
            password: currentUser!.password,
            profileImage: currentUser!.profileImage,
            role: currentUser!.role,
            completedTests: [],
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error resetting completed tests: $e');
      return false;
    }
  }

  // Освобождение ресурсов
  static void dispose() {
    _channel?.sink.close();
    _channel = null;
    _responseController.close();
  }
}