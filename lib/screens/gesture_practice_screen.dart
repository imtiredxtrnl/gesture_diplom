import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/gesture.dart';
import '../services/camera_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GesturePracticeScreen extends StatefulWidget {
  final Gesture gesture;

  const GesturePracticeScreen({
    Key? key,
    required this.gesture,
  }) : super(key: key);

  @override
  _GesturePracticeScreenState createState() => _GesturePracticeScreenState();
}

class _GesturePracticeScreenState extends State<GesturePracticeScreen> with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  String _detectedGesture = 'Наведите камеру на жест';
  bool _sending = false;
  bool _isProcessing = false;
  Timer? _frameTimer;

  // Используем CameraManager
  final CameraManager _cameraManager = CameraManager();

  // Флаги для определения правильности жеста
  bool _isSuccess = false;
  int _successCounter = 0;
  int _requiredSuccessCount = 3; // Количество успешных распознаваний для завершения

  // Таймер для обучения
  int _timeRemaining = 30; // Начальное время в секундах
  Timer? _countdownTimer;
  bool _isTimerRunning = false;

  // Для отслеживания ошибок
  String _errorMessage = '';
  bool _isInitializing = true;

  // Инструкции для жеста
  List<String> _instructions = [];
  int _currentInstructionIndex = 0;

  @override
  void initState() {
    super.initState();
    print("GesturePracticeScreen: initState вызван");
    WidgetsBinding.instance.addObserver(this);
    _setInstructionsForGesture();

    // Отложим инициализацию камеры, чтобы экран успел построиться
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeCamera();
        _connectWebSocket();
      }
    });
  }

  void _setInstructionsForGesture() {
    // Задаем инструкции в зависимости от типа жеста
    switch(widget.gesture.name) {
      case "Привет":
        _instructions = [
          "Поднимите руку на уровень плеча",
          "Разверните ладонь к камере",
          "Расправьте все пальцы",
          "Покачайте рукой из стороны в сторону"
        ];
        break;
      case "Спасибо":
        _instructions = [
          "Поднесите ладонь к подбородку",
          "Коснитесь кончиками пальцев подбородка",
          "Опустите руку вперед и вниз"
        ];
        break;
      case "Да":
        _instructions = [
          "Сожмите руку в кулак",
          "Поднимите большой палец вверх",
          "Держите руку перед собой"
        ];
        break;
      case "Нет":
        _instructions = [
          "Поднимите указательный палец",
          "Остальные пальцы согните в кулак",
          "Покачайте пальцем из стороны в сторону"
        ];
        break;
      default:
        _instructions = [
          "Изучите изображение жеста",
          "Повторите его перед камерой",
          "Удерживайте правильное положение руки"
        ];
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("GesturePracticeScreen: состояние жизненного цикла изменилось: $state");

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // При неактивном состоянии приостанавливаем отправку кадров
      _pauseTimers();
    } else if (state == AppLifecycleState.resumed) {
      // При возобновлении запускаем отправку кадров снова
      if (_cameraManager.isInitialized) {
        _resumeTimers();
      } else {
        _initializeCamera();
      }
    }
  }

  void _connectWebSocket() {
    print("GesturePracticeScreen: подключение к WebSocket");
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8765'));
      _channel!.stream.listen(
            (message) {
          // Обработка входящих сообщений
          final response = json.decode(message);
          if (response.containsKey('gesture')) {
            setState(() {
              final gesture = response['gesture'];
              _detectedGesture = _translateGesture(gesture);

              // Проверяем соответствие распознанного жеста целевому
              _checkGestureMatch(gesture);
            });
          }
          // Разрешаем отправку следующего кадра
          _isProcessing = false;
        },
        onError: (error) {
          print("GesturePracticeScreen: ошибка WebSocket: $error");
          setState(() {
            _errorMessage = 'Ошибка соединения: $error';
          });
        },
        onDone: () {
          print("GesturePracticeScreen: соединение WebSocket закрыто");
          if (mounted) {
            setState(() {
              _errorMessage = 'Соединение закрыто';
            });
          }
        },
      );
    } catch (e) {
      print("GesturePracticeScreen: ошибка при создании WebSocket: $e");
      setState(() {
        _errorMessage = 'Ошибка подключения: $e';
      });
    }
  }

  void _checkGestureMatch(String detectedGesture) {
    // Примеры соответствия распознанных жестов и целевых
    bool isMatch = false;

    switch(widget.gesture.name) {
      case "Привет":
        isMatch = detectedGesture == "Open Palm";
        break;
      case "Спасибо":
        isMatch = detectedGesture == "Pointing";
        break;
      case "Пожалуйста":
        isMatch = detectedGesture == "Open Palm";
        break;
      case "Да":
        isMatch = detectedGesture == "Thumbs Up";
        break;
      case "Нет":
        isMatch = detectedGesture == "Fist";
        break;
      default:
        isMatch = false;
    }

    setState(() {
      _isSuccess = isMatch;

      // Если жест правильный, увеличиваем счетчик успеха
      if (isMatch) {
        _successCounter++;

        // Переходим к следующей инструкции
        if (_currentInstructionIndex < _instructions.length - 1) {
          _currentInstructionIndex++;
        }

        // Если набрали нужное количество успешных распознаваний, считаем практику завершенной
        if (_successCounter >= _requiredSuccessCount) {
          _showSuccessDialog();
          _pauseTimers();
        }
      } else {
        // При неправильном жесте сбрасываем счетчик
        _successCounter = 0;
      }
    });
  }

  Future<void> _initializeCamera() async {
    print("GesturePracticeScreen: начинаем инициализацию камеры");

    setState(() {
      _isInitializing = true;
      _errorMessage = '';
    });

    try {
      // Используем CameraManager для инициализации камеры
      await _cameraManager.initializeCamera();

      // Убедимся что виджет все еще в дереве после асинхронной операции
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });

      // Начинаем отправку кадров и запускаем таймер
      _startFrameSendingLoop();
      _startCountdownTimer();
    } catch (e) {
      print("GesturePracticeScreen: ошибка инициализации камеры: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка инициализации камеры: $e';
          _isInitializing = false;
        });
      }
    }
  }

  void _startFrameSendingLoop() {
    print("GesturePracticeScreen: запуск отправки кадров");

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
        print("GesturePracticeScreen: ошибка захвата или отправки изображения: $e");
        _isProcessing = false;

        // Если произошла серьёзная ошибка, попробуем переинициализировать камеру
        if (e.toString().contains('not initialized') ||
            e.toString().contains('camera closed') ||
            e.toString().contains('camera released')) {
          print("GesturePracticeScreen: попытка переинициализировать камеру");
          _initializeCamera();
        }
      }
      _sending = false;
    });
  }

  void _startCountdownTimer() {
    print("GesturePracticeScreen: запуск таймера обучения");

    // Останавливаем предыдущий таймер, если он есть
    _countdownTimer?.cancel();

    setState(() {
      _timeRemaining = 30; // Сбрасываем таймер
      _isTimerRunning = true;
    });

    // Создаем новый таймер обратного отсчета
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          // Время вышло
          _countdownTimer?.cancel();
          _isTimerRunning = false;
          _showTimeUpDialog();
        }
      });
    });
  }

  void _pauseTimers() {
    print("GesturePracticeScreen: остановка таймеров");
    _frameTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resumeTimers() {
    print("GesturePracticeScreen: возобновление таймеров");
    _startFrameSendingLoop();
    _startCountdownTimer();
  }

  // Очистка всех ресурсов
  void _cleanupResources() {
    print("GesturePracticeScreen: очистка всех ресурсов");
    _pauseTimers();
    _cameraManager.releaseCamera(); // Важно освободить ресурсы камеры
    _channel?.sink.close();
    _channel = null;
  }

  // Метод для обработки кнопки "Назад" на устройстве
  Future<bool> _onWillPop() async {
    print("GesturePracticeScreen: обработка кнопки 'Назад'");
    _cleanupResources();
    return true; // Разрешаем возврат назад
  }

  void _showSuccessDialog() async {
    // Инкрементируем счетчики статистики
    final prefs = await SharedPreferences.getInstance();
    final practiceCount = (prefs.getInt('practice_count') ?? 0) + 1;
    final correctGestures = (prefs.getInt('correct_gestures') ?? 0) + 1;

    await prefs.setInt('practice_count', practiceCount);
    await prefs.setInt('correct_gestures', correctGestures);

    // Используем правильный синтаксис showDialog
    showDialog(
      context: context,
      // Уберем параметр barrierDismissible, его нет в AlertDialog
      builder: (context) => AlertDialog(
        title: Text('Поздравляем!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Вы успешно выполнили жест "${widget.gesture.name}"!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _cleanupResources(); // Освобождаем ресурсы перед возвратом
              Navigator.of(context).pop(); // Закрываем диалог
              Navigator.of(context).pop(); // Возвращаемся на предыдущий экран
            },
            child: Text('Вернуться к словарю'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Сбрасываем счетчики и запускаем таймеры заново
              setState(() {
                _successCounter = 0;
                _currentInstructionIndex = 0;
              });
              _resumeTimers();
            },
            child: Text('Попробовать еще раз'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      // Уберем параметр barrierDismissible
      builder: (context) => AlertDialog(
        title: Text('Время вышло'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_off,
              color: Colors.orange,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Вы не успели выполнить жест. Хотите попробовать еще раз?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _cleanupResources(); // Освобождаем ресурсы перед возвратом
              Navigator.of(context).pop(); // Закрываем диалог
              Navigator.of(context).pop(); // Возвращаемся на предыдущий экран
            },
            child: Text('Вернуться к словарю'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Сбрасываем счетчики и запускаем таймеры заново
              setState(() {
                _successCounter = 0;
                _currentInstructionIndex = 0;
              });
              _resumeTimers();
            },
            child: Text('Попробовать еще раз'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Перевод англоязычных названий жестов на русский
  String _translateGesture(String gesture) {
    switch (gesture) {
      case 'No Hand':
        return 'Жест не обнаружен';
      case 'Open Palm':
        return 'Открытая ладонь';
      case 'Fist':
        return 'Кулак';
      case 'Thumbs Up':
        return 'Большой палец вверх';
      case 'Victory':
        return 'Жест победы';
      case 'Pointing':
        return 'Указательный жест';
      case 'Rock':
        return 'Рок';
      case 'Unknown':
        return 'Неизвестный жест';
      default:
        return gesture;
    }
  }

  @override
  void dispose() {
    print("GesturePracticeScreen: dispose вызван");
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Практика: ${widget.gesture.name}'),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          // Добавим кнопку для возврата назад с правильным освобождением ресурсов
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _cleanupResources();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Column(
          children: [
            // Отображение целевого жеста
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      widget.gesture.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported, color: Colors.grey);
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Покажите жест:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.gesture.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Таймер
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _timeRemaining > 10 ? Colors.green[100] : Colors.red[100],
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_timeRemaining',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _timeRemaining > 10 ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Инструкции для текущего шага
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              color: Colors.deepPurple[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Шаг ${_currentInstructionIndex + 1} из ${_instructions.length}:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _instructions[_currentInstructionIndex],
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

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
                            'Инициализация камеры...',
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
                              child: Text('Попробовать снова'),
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
                              'Камера не инициализирована',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initializeCamera,
                              child: Text('Инициализировать камеру'),
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
                          color: _isSuccess ? Colors.green.withOpacity(0.7) : Colors.deepPurple.withOpacity(0.7),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                  // Индикатор успеха (показываем только если жест распознан правильно)
                  if (_isSuccess && _cameraManager.isInitialized)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Правильно!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Отображение результата распознавания
            Container(
              padding: EdgeInsets.all(16),
              color: _isSuccess ? Colors.green[100] : Colors.grey[100],
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.info_outline,
                    color: _isSuccess ? Colors.green : Colors.grey,
                    size: 30,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Распознанный жест:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _detectedGesture,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isSuccess ? Colors.green[800] : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Счетчик успехов
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ...List.generate(_requiredSuccessCount, (index) =>
                            Container(
                              width: 15,
                              height: 15,
                              margin: EdgeInsets.only(right: index < _requiredSuccessCount - 1 ? 4 : 0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < _successCounter ? Colors.green : Colors.grey[300],
                              ),
                            ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}