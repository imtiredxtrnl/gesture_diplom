// lib/screens/camera_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/camera_manager.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  String _result = '';
  bool _sending = false;
  bool _isProcessing = false;
  Timer? _frameTimer;
  String _errorMessage = '';
  bool _isInitializing = true;

  // Используем CameraManager
  final CameraManager _cameraManager = CameraManager();

  @override
  void initState() {
    super.initState();
    print("CameraScreen: initState вызван");
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  // Новый метод для переинициализации камеры
  void reinitializeCamera() {
    print("CameraScreen: reinitializeCamera вызван");
    if (!_cameraManager.isInitialized) {
      _initializeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("CameraScreen: состояние жизненного цикла изменилось: $state");

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // При неактивном состоянии приостанавливаем отправку кадров
      _frameTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // При возобновлении запускаем отправку кадров снова
      if (_cameraManager.isInitialized) {
        _startFrameSendingLoop();
      } else {
        _initializeCamera();
      }
    }
  }

  void _connectWebSocket() {
    print("CameraScreen: підключення до WebSocket");
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8765'));
      _channel!.stream.listen(
            (message) {
          final response = json.decode(message);
          if (response.containsKey('gesture')) {
            setState(() {
              _result = _translateGesture(response['gesture']);
            });
          }
          _isProcessing = false;
        },
        onError: (error) {
          print("CameraScreen: помилка WebSocket: $error");
          setState(() {
            _errorMessage = 'Помилка зїднання: $error';
          });
        },
        onDone: () {
          print("CameraScreen: зїднання WebSocket зачинено");
        },
      );
    } catch (e) {
      print("CameraScreen: помилка при створені WebSocket: $e");
      setState(() {
        _errorMessage = 'помилка підключення: $e';
      });
    }
  }

  Future<void> _initializeCamera() async {
    print("CameraScreen: початок ініціалізації камери");
    setState(() {
      _isInitializing = true;
      _errorMessage = '';
    });

    try {
      // Инициализируем камеру
      await _cameraManager.initializeCamera();

      // Проверка, что виджет все еще в дереве после асинхронной операции
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });

      // Подключаемся к WebSocket и начинаем отправку кадров
      _connectWebSocket();
      _startFrameSendingLoop();
    } catch (e) {
      print("CameraScreen: помилка ініціалізації камери: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'помилка ініціалізації камери: $e';
          _isInitializing = false;
        });
      }
    }
  }

  void _startFrameSendingLoop() {
    print("CameraScreen: запуск відправки кадрів");

    // Останавливаем предыдущий таймер, если он есть
    _frameTimer?.cancel();

    // Создаем новый таймер для периодической отправки кадров
    _frameTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      // Проверяем, можно ли отправлять кадры
      if (!_cameraManager.isInitialized || _sending || _isProcessing || _channel == null) return;

      _sending = true;
      try {
        // Фиксируем текущий кадр с камеры
        final XFile? picture = await _cameraManager.takePicture();
        if (picture == null) {
          _sending = false;
          return;
        }

        final bytes = await picture.readAsBytes();
        // Кодируем изображение в base64 для отправки
        final base64Image = base64Encode(bytes);

        // Формируем и отправляем запрос на распознавание жеста
        final request = json.encode({
          'type': 'gesture',
          'image': base64Image,
        });

        _channel!.sink.add(request);
        _isProcessing = true;
      } catch (e) {
        print("CameraScreen: ошибка захвата или отправки изображения: $e");
        _isProcessing = false;
      }
      _sending = false;
    });
  }

  // Перевод англоязычных названий жестов на русский
  String _translateGesture(String gesture) {
    switch (gesture) {
      case 'No Hand':
        return 'Жест не виявлено';
      case 'Open Palm':
        return 'Відкрита ладонь';
      case 'Fist':
        return 'Кулак';
      case 'Thumbs Up':
        return 'Великий палець вгору';
      case 'Victory':
        return 'Жест перемоги';
      case 'Pointing':
        return 'Вказівний жест';
      case 'Rock':
        return 'Рок';
      case 'Unknown':
        return 'Невідомий жест';
      default:
        return gesture;
    }
  }

  // Очистка ресурсов
  void _cleanupResources() {
    print("CameraScreen: очистка ресурсов");
    _frameTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    print("CameraScreen: dispose вызван");
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _cleanupResources();
        return true;
      },
      child: Column(
        children: [
          // Превью камеры
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Основной контент (камера или сообщение об ошибке)
                if (_isInitializing)
                // Если камера инициализируется, показываем индикатор загрузки
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.deepPurple,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Ініціалізація камери...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_errorMessage.isNotEmpty)
                // Если есть ошибка, показываем её
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _initializeCamera,
                            child: Text('Спробувати знову'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_cameraManager.isInitialized)
                  // Если камера готова, показываем её
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _cameraManager.controller!.value.previewSize!.height,
                          height: _cameraManager.controller!.value.previewSize!.width,
                          child: CameraPreview(_cameraManager.controller!),
                        ),
                      ),
                    )
                  else
                  // Если ничего не готово, но нет ошибок, показываем сообщение
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Камера не ініціалізована',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializeCamera,
                            child: Text('Ініціалізувати камеру'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                // Рамка для позиционирования руки (показываем только если камера активна)
                if (_cameraManager.isInitialized)
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.7),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
              ],
            ),
          ),

          // Панель с результатом распознавания
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.deepPurple[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Роспізнаний жест:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _result,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}