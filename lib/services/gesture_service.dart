import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gesture.dart';
import 'package:sign_language_app/services/auth_service.dart';
import '../models/user_model.dart';

class GestureService {
  static final GestureService _instance = GestureService._internal();
  factory GestureService() => _instance;

  WebSocketChannel? _channel;
  final _serverUrl = 'ws://10.0.2.2:8765';

  // Список всех доступных жестов с реальными путями к изображениям
  static final List<Gesture> _allGestures = [
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
    Gesture(
      id: '9',
      name: 'Помощь',
      description: 'Жест просьбы о помощи. Поднимите обе руки вверх.',
      imagePath: 'lib/assets/gestures/help.png',
      category: 'actions',
    ),
    Gesture(
      id: '10',
      name: 'Любовь',
      description: 'Жест выражения любви. Сложите руки в форме сердца.',
      imagePath: 'lib/assets/gestures/love.png',
      category: 'emotions',
    ),
  ];

  // Обработчики сообщений для WebSocket
  Function(String)? onError;
  Function(String, double)? onGestureRecognized;
  Function(String)? onStatusMessage;

  GestureService._internal();

  // Получение всех жестов
  List<Gesture> getAllGestures() {
    return List.from(_allGestures);
  }

  // Получение жеста по ID
  Gesture? getGestureById(String id) {
    try {
      return _allGestures.firstWhere((gesture) => gesture.id == id);
    } catch (e) {
      return null;
    }
  }

  // Получение жестов по категории
  List<Gesture> getGesturesByCategory(String category) {
    if (category == 'all') {
      return getAllGestures();
    }
    return _allGestures.where((gesture) => gesture.category == category).toList();
  }

  // Поиск жестов
  List<Gesture> searchGestures(String query) {
    if (query.isEmpty) {
      return getAllGestures();
    }

    final lowerQuery = query.toLowerCase();
    return _allGestures.where((gesture) =>
    gesture.name.toLowerCase().contains(lowerQuery) ||
        gesture.description.toLowerCase().contains(lowerQuery) ||
        gesture.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Получение изученных жестов из локального хранилища
  Future<List<String>> getLearnedGestureIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('learned_gestures') ?? [];
    } catch (e) {
      print('Error loading learned gestures: $e');
      return [];
    }
  }

  // Отметка жеста как изученного
  Future<bool> markGestureAsLearned(String gestureId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;
      if (user.completedGestures.contains(gestureId)) return false;
      final updatedGestures = List<String>.from(user.completedGestures)..add(gestureId);
      // Передаём все поля прогресса, чтобы не затирались остальные
      final response = await AuthService.updateUserProfile({
        'completedTests': user.completedTests,
        'completedGestures': updatedGestures,
        'completedNotes': user.completedNotes,
      });
      if (response['status'] == 'success' && response['user'] != null) {
        AuthService.currentUser = User.fromJson(response['user']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking gesture as learned: $e');
      return false;
    }
  }

  // Сброс прогресса изучения
  Future<bool> resetLearningProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('learned_gestures');
      return true;
    } catch (e) {
      print('Error resetting learning progress: $e');
      return false;
    }
  }

  // Получение статистики изучения
  Future<Map<String, int>> getLearningStatistics() async {
    try {
      final learnedGestures = await getLearnedGestureIds();
      final totalGestures = _allGestures.length;
      final learnedCount = learnedGestures.length;

      return {
        'total': totalGestures,
        'learned': learnedCount,
        'remaining': totalGestures - learnedCount,
      };
    } catch (e) {
      print('Error getting learning statistics: $e');
      return {'total': 0, 'learned': 0, 'remaining': 0};
    }
  }

  // Инициализация соединения с сервером
  Future<void> initialize() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));

      // Слушаем сообщения от сервера
      _channel!.stream.listen(
            (message) => _handleMessage(message),
        onError: (error) {
          if (onError != null) {
            onError!('Ошибка WebSocket: $error');
          }
        },
        onDone: () {
          if (onStatusMessage != null) {
            onStatusMessage!('Соединение закрыто');
          }
          _reconnect();
        },
      );

      if (onStatusMessage != null) {
        onStatusMessage!('Подключено к серверу');
      }
    } catch (e) {
      if (onError != null) {
        onError!('Ошибка подключения: $e');
      }
      _reconnect();
    }
  }

  // Обработка сообщений от сервера
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);

      if (data.containsKey('gesture')) {
        final gesture = data['gesture'];
        final confidence = data['confidence'] ?? 0.0;

        if (onGestureRecognized != null) {
          onGestureRecognized!(gesture, confidence);
        }
      } else if (data.containsKey('error') || data.containsKey('status')) {
        final statusMessage = data['error'] ?? data['status'] ?? 'Неизвестный статус';

        if (onStatusMessage != null) {
          onStatusMessage!(statusMessage);
        }
      }
    } catch (e) {
      if (onError != null) {
        onError!('Ошибка обработки сообщения: $e');
      }
    }
  }

  // Переподключение при потере соединения
  void _reconnect() {
    Future.delayed(Duration(seconds: 3), () {
      initialize();
    });
  }

  // Отправка изображения для распознавания жеста
  void recognizeGesture(String base64Image) {
    if (_channel == null) {
      if (onError != null) {
        onError!('Нет соединения с сервером');
      }
      return;
    }

    try {
      final request = json.encode({
        'type': 'gesture',
        'image': base64Image,
      });

      _channel!.sink.add(request);
    } catch (e) {
      if (onError != null) {
        onError!('Ошибка отправки изображения: $e');
      }
    }
  }

  // Отправка изображения для практики конкретного жеста
  void practiceGesture(String base64Image, String targetGesture) {
    if (_channel == null) {
      if (onError != null) {
        onError!('Нет соединения с сервером');
      }
      return;
    }

    try {
      final request = json.encode({
        'type': 'gesture',
        'image': base64Image,
        'practice_mode': true,
        'target_gesture': targetGesture,
      });

      _channel!.sink.add(request);
    } catch (e) {
      if (onError != null) {
        onError!('Ошибка отправки изображения: $e');
      }
    }
  }

  // Закрытие соединения
  void dispose() {
    _channel?.sink.close();
    _channel = null;
  }
}