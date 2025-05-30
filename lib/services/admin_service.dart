// lib/services/admin_service.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import '../models/gesture.dart';
import '../models/test_model.dart';
import '../models/alphabet_letter.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;

  WebSocketChannel? _channel;
  static final StreamController<Map<String, dynamic>> _responseController =
  StreamController<Map<String, dynamic>>.broadcast();

  static const String serverUrl = 'ws://10.0.2.2:8765';

  AdminService._internal();

  // Инициализация WebSocket соединения
  Future<void> _initWebSocket() async {
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
  Future<Map<String, dynamic>> _sendRequest(Map<String, dynamic> request) async {
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
      if (request['type'] == response['type'] ||
          response.containsKey('status') ||
          response.containsKey('gestures') ||
          response.containsKey('tests') ||
          response.containsKey('letters')) {
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

  // ============== GESTURE MANAGEMENT ==============

  Future<List<Gesture>> getAllGestures() async {
    final request = {
      'type': 'gesture',
      'action': 'get_all',
    };

    try {
      final response = await _sendRequest(request);
      if (response['status'] == 'success' && response['gestures'] != null) {
        return (response['gestures'] as List)
            .map((json) => Gesture.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting gestures: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createGesture({
    required String name,
    required String description,
    required String category,
    String imagePath = '',
  }) async {
    final request = {
      'type': 'gesture',
      'action': 'create',
      'name': name,
      'description': description,
      'category': category,
      'imagePath': imagePath,
    };

    return await _sendRequest(request);
  }

  Future<Map<String, dynamic>> updateGesture({
    required String id,
    required String name,
    required String description,
    required String category,
    String imagePath = '',
  }) async {
    final request = {
      'type': 'gesture',
      'action': 'update',
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'imagePath': imagePath,
    };

    return await _sendRequest(request);
  }

  Future<Map<String, dynamic>> deleteGesture(String id) async {
    final request = {
      'type': 'gesture',
      'action': 'delete',
      'id': id,
    };

    return await _sendRequest(request);
  }

  // ============== TEST MANAGEMENT ==============

  Future<List<Test>> getAllTests() async {
    final request = {
      'type': 'test',
      'action': 'get_all',
    };

    try {
      final response = await _sendRequest(request);
      if (response['status'] == 'success' && response['tests'] != null) {
        return (response['tests'] as List)
            .map((json) => Test.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting tests: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createTest({
    required String question,
    required List<String> options,
    required int correctOptionIndex,
    required String category,
    String imagePath = '',
  }) async {
    final request = {
      'type': 'test',
      'action': 'create',
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'category': category,
      'imagePath': imagePath,
    };

    return await _sendRequest(request);
  }

  Future<Map<String, dynamic>> updateTest({
    required String id,
    required String question,
    required List<String> options,
    required int correctOptionIndex,
    required String category,
    String imagePath = '',
  }) async {
    final request = {
      'type': 'test',
      'action': 'update',
      'id': id,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'category': category,
      'imagePath': imagePath,
    };

    return await _sendRequest(request);
  }

  Future<Map<String, dynamic>> deleteTest(String id) async {
    final request = {
      'type': 'test',
      'action': 'delete',
      'id': id,
    };

    return await _sendRequest(request);
  }

  // ============== ALPHABET MANAGEMENT ==============

  Future<List<AlphabetLetter>> getAllLetters({String language = 'all'}) async {
    final request = {
      'type': 'alphabet',
      'action': 'get_all',
      'language': language,
    };

    try {
      final response = await _sendRequest(request);
      if (response['status'] == 'success' && response['letters'] != null) {
        return (response['letters'] as List)
            .map((json) => AlphabetLetter.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting letters: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createLetter({
    required String letter,
    required String language,
    String imagePath = '',
  }) async {
    final request = {
      'type': 'alphabet',
      'action': 'create',
      'letter': letter,
      'language': language,
      'imagePath': imagePath,
    };

    return await _sendRequest(request);
  }

  Future<Map<String, dynamic>> updateLetter({
    required String id,
    required String letter,
    required String language,
    String imagePath = '',
  }) async {
    final request = {
      'type': 'alphabet',
      'action': 'update',
      'id': id,
      'letter': letter,
      'language': language,
      'imagePath': imagePath,
    };

    return await _sendRequest(request);
  }

  Future<Map<String, dynamic>> deleteLetter(String id) async {
    final request = {
      'type': 'alphabet',
      'action': 'delete',
      'id': id,
    };

    return await _sendRequest(request);
  }

  // Освобождение ресурсов
  void dispose() {
    _channel?.sink.close();
    _channel = null;
  }
}