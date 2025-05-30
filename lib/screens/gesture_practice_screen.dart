// lib/screens/gesture_practice_screen.dart
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
  int _timeRemaining = 60; // Начальное время в секундах
  Timer? _countdownTimer;
  bool _isTimerRunning = false;

  // Для отслеживания ошибок
  String _errorMessage = '';
  bool _isInitializing = true;

  // Инструкции для жеста
  List<String> _instructions = [];
  int _currentInstructionIndex = 0;

  // Статистика практики
  int _totalAttempts = 0;
  int _correctAttempts = 0;

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
    switch(widget.gesture.name.toLowerCase()) {
      case "привет":
        _instructions = [
          "Поднимите руку на уровень плеча",
          "Разверните ладонь к камере",
          "Расправьте все пальцы",
          "Покачайте рукой из стороны в сторону"
        ];
        break;
      case "спасибо":
        _instructions = [
          "Поднесите ладонь к подбородку",
          "Коснитесь кончиками пальцев подбородка",
          "Опустите руку вперед и вниз",
          "Держите ладонь открытой"
        ];
        break;
      case "да":
        _instructions = [
          "Сожмите руку в кулак",
          "Поднимите большой палец вверх",
          "Держите руку перед собой",
          "Убедитесь что жест четко виден"
        ];
        break;
      case "нет":
        _instructions = [
          "Поднимите указательный палец",
          "Остальные пальцы согните в кулак",
          "Покачайте пальцем из стороны в сторону",
          "Держите руку на уровне груди"
        ];
        break;
      case "хорошо":
        _instructions = [
          "Соедините большой и указательный палец",
          "Сформируйте кольцо (знак ОК)",
          "Остальные пальцы держите прямо",
          "Покажите жест четко камере"
        ];
        break;
      case "пожалуйста":
        _instructions = [
          "Положите открытую ладонь на грудь",
          "Сделайте круговое движение",
          "Движение должно быть плавным",
          "Повторите несколько раз"
        ];
        break;
      default:
        _instructions = [
          "Изучите изображение жеста",
          "Повторите его перед камерой",
          "Держите правильное положение руки",
          "Выполняйте движения четко и медленно"
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
              _totalAttempts++;

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

    switch(widget.gesture.name.toLowerCase()) {
      case "привет":
        isMatch = detectedGesture == "Open Palm" || detectedGesture == "Pointing";
        break;
      case "спасибо":
        isMatch = detectedGesture == "Open Palm" || detectedGesture == "Pointing";
        break;
      case "пожалуйста":
        isMatch = detectedGesture == "Open Palm";
        break;
      case "да":
        isMatch = detectedGesture == "Thumbs Up";
        break;
      case "нет":
        isMatch = detectedGesture == "Pointing" || detectedGesture == "Victory";
        break;
      case "хорошо":
        isMatch = detectedGesture == "Victory" || detectedGesture == "Open Palm";
        break;
      case "плохо":
        isMatch = detectedGesture == "Fist" || detectedGesture == "Thumbs Up";
        break;
      case "стоп":
        isMatch = detectedGesture == "Open Palm";
        break;
      case "помощь":
        isMatch = detectedGesture == "Open Palm" || detectedGesture == "Victory";
        break;
      case "любовь":
        isMatch = detectedGesture == "Rock" || detectedGesture == "Victory";
        break;
      default:
      // Для неизвестных жестов принимаем любой распознанный жест кроме "No Hand"
        isMatch = detectedGesture != "No Hand" && detectedGesture != "Unknown";
    }

    setState(() {
      _isSuccess = isMatch;

      // Если жест правильный, увеличиваем счетчик успеха
      if (isMatch) {
        _successCounter++;
        _correctAttempts++;

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
        // При неправильном жесте не сбрасываем счетчик полностью, а уменьшаем на 1
        if (_successCounter > 0) {
          _successCounter = _successCounter - 1;
        }
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
      _timeRemaining = 60; // Сбрасываем таймер
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Поздравляем!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
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
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Правильных попыток:'),
                            Text('$_correctAttempts из $_totalAttempts',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Точность:'),
                            Text('${_totalAttempts > 0 ? ((_correctAttempts / _totalAttempts) * 100).toInt() : 0}%',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            child: Text('Завершить'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Сбрасываем счетчики и запускаем таймеры заново
              setState(() {
                _successCounter = 0;
                _currentInstructionIndex = 0;
                _totalAttempts = 0;
                _correctAttempts = 0;
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Время вышло'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.orange,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Время практики истекло. Хотите попробовать еще раз?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Правильных попыток:'),
                            Text('$_correctAttempts из $_totalAttempts',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Прогресс:'),
                            Text('$_successCounter/$_requiredSuccessCount',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            child: Text('Завершить'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Сбрасываем счетчики и запускаем таймеры заново
              setState(() {
                _successCounter = 0;
                _currentInstructionIndex = 0;
                _totalAttempts = 0;
                _correctAttempts = 0;
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
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                _showInfoDialog();
              },
            ),
          ],
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
              child: widget.gesture.imagePath.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.gesture.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.gesture,
                        color: Colors.grey[600], size: 40);
                  },
                ),
              )
                  : Icon(Icons.gesture,
                  color: Colors.grey[600], size: 40),
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
                color: _timeRemaining > 15 ? Colors.green[100] : Colors.red[100],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$_timeRemaining',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _timeRemaining > 15 ? Colors.green[800] : Colors.red[800],
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

    // Счетчик прогресса
    if (_cameraManager.isInitialized)
    Positioned(
    top: 20,
    left: 20,
    child: Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
    color: Colors.black54,
    borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
    'Прогресс: $_successCounter/$_requiredSuccessCount',
    style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    ),
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

    // Статистика практики
    Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: Colors.grey[50],
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
    _buildStatItem('Всего попыток', '$_totalAttempts', Colors.blue),
    _buildStatItem('Правильных', '$_correctAttempts', Colors.green),
    _buildStatItem('Точность', '${_totalAttempts > 0 ? ((_correctAttempts / _totalAttempts) * 100).toInt() : 0}%', Colors.orange),
    ],
    ),
    ),
    ],
    ),
    ),
    );
    }

  Widget _buildStatItem(String label, String value, MaterialColor color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Как практиковать'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Описание жеста:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(widget.gesture.description),
              SizedBox(height: 16),
              Text(
                'Инструкции:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              ...List.generate(_instructions.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. '),
                      Expanded(child: Text(_instructions[index])),
                    ],
                  ),
                );
              }),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Советы:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Держите руку в хорошо освещенном месте\n• Выполняйте жесты четко и медленно\n• Держите руку в рамке на экране\n• Нужно $_requiredSuccessCount правильных распознавания подряд',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Понятно'),
          ),
        ],
      ),
    );
  }
}