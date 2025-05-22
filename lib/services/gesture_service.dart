import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/gesture.dart';

class GestureService {
  static final GestureService _instance = GestureService._internal();
  factory GestureService() => _instance;

  WebSocketChannel? _channel;
  final _serverUrl = 'ws://10.0.2.2:8765';

  // Обработчики сообщений
  Function(String)? onError;
  Function(String, double)? onGestureRecognized;
  Function(String)? onStatusMessage;

  GestureService._internal();

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

  // Получение списка всех жестов
  Future<List<Gesture>> getAllGestures() async {
    if (_channel == null) {
      throw Exception('Нет соединения с сервером');
    }

    final completer = Completer<List<Gesture>>();

    try {
      // Подписываемся на одноразовое получение списка жестов
      final subscription = _channel!.stream.listen(
            (message) {
          try {
            final data = json.decode(message);

            if (data.containsKey('type') && data['type'] == 'dictionary_response' &&
                data.containsKey('gestures')) {
              final gestures = (data['gestures'] as List)
                  .map((json) => Gesture.fromJson(json))
                  .toList();

              completer.complete(gestures);
              subscription.cancel();
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError('Ошибка обработки ответа: $e');
            }
            subscription.cancel();
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError('Ошибка WebSocket: $error');
          }
          subscription.cancel();
        },
      );

      // Отправляем запрос на получение всех жестов
      final request = json.encode({
        'type': 'dictionary',
        'action': 'get_all',
      });

      _channel!.sink.add(request);

      // Устанавливаем таймаут
      Future.delayed(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.completeError('Превышено время ожидания');
          subscription.cancel();
        }
      });

      return completer.future;
    } catch (e) {
      throw Exception('Ошибка получения жестов: $e');
    }
  }

  // Закрытие соединения
  void dispose() {
    _channel?.sink.close();
    _channel = null;
  }
}