import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/gesture.dart';
import '../services/camera_manager.dart';
import '../services/gesture_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_language_app/l10n/app_localizations.dart';
import '../services/admin_service.dart';

class GesturePracticeScreen extends StatefulWidget {
  final Gesture? gesture;

  const GesturePracticeScreen({
    Key? key,
    this.gesture,
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

  // Используем CameraManager и GestureService
  final CameraManager _cameraManager = CameraManager();
  final GestureService _gestureService = GestureService();

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

  List<Gesture> _allGestures = [];
  Gesture? _currentGesture;

  @override
  void initState() {
    super.initState();
    print("GesturePracticeScreen: initState вызван для жеста ${widget.gesture?.name}");
    WidgetsBinding.instance.addObserver(this);
    _loadAllGestures();
  }

  Future<void> _loadAllGestures() async {
    final adminService = AdminService();
    final gestures = await adminService.getAllGestures();
    setState(() {
      _allGestures = gestures;
      // Найти жест с тем же id, что и был выбран ранее
      if (_currentGesture != null) {
        final match = gestures.firstWhere(
          (g) => g.id == _currentGesture!.id,
          orElse: () => gestures[0],
        );
        _currentGesture = match;
      } else {
        _currentGesture = gestures.isNotEmpty ? gestures[0] : null;
      }
    });
    if (_currentGesture != null) {
      _setInstructionsForGesture(_currentGesture!);
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _initializeCamera();
          _connectWebSocket();
        }
      });
    }
  }

  void _setInstructionsForGesture(Gesture gesture) {
    // Можно реализовать инструкции для каждого жеста, либо оставить универсальные
    _instructions = [
      "Изучите изображение жеста",
      "Повторите его перед камерой",
      "Удерживайте правильное положение руки"
    ];
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
              _detectedGesture = gesture;
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
    final locale = Localizations.localeOf(context).languageCode;
    final targetName = locale == 'en'
        ? _currentGesture?.nameEn ?? _currentGesture?.name
        : _currentGesture?.name;
    final altName = locale == 'en'
        ? _currentGesture?.name
        : _currentGesture?.nameEn;
    final detected = detectedGesture.trim().toLowerCase();
    final target = (targetName ?? '').trim().toLowerCase();
    final alt = (altName ?? '').trim().toLowerCase();
    print('Сравнение жестов: detected="$detected", target="$target", alt="$alt"');
    final isMatch = detected == target || (alt.isNotEmpty && detected == alt);
    setState(() {
      if (isMatch) {
        _successCounter++;
        _isSuccess = true;
        if (_currentInstructionIndex < _instructions.length - 1) {
          _currentInstructionIndex++;
        }
        if (_successCounter >= _requiredSuccessCount) {
          _showSuccessDialog();
          _pauseTimers();
        }
      } else {
        _isSuccess = false;
        // Сбрасываем счетчик только если был успех и теперь ошибка
        if (_successCounter > 0) {
          _successCounter = 0;
        }
        _currentInstructionIndex = 0;
      }
    });
  }

  // При смене жеста сбрасываем счетчик
  void _onGestureChanged(Gesture g) {
    setState(() {
      _currentGesture = g;
      _setInstructionsForGesture(g);
      _successCounter = 0;
      _currentInstructionIndex = 0;
      _isSuccess = false;
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
          'practice_mode': true,
          'target_gesture': _currentGesture?.name,
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
    // Отмечаем жест как изученный
    await _gestureService.markGestureAsLearned(_currentGesture?.id ?? '');

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
        title: Text(AppLocalizations.of(context)!.success),
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
              AppLocalizations.of(context)!.success_message(_currentGesture?.name ?? ''),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.gesture_marked_as_learned,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _cleanupResources(); // Освобождаем ресурсы перед возвратом
              Navigator.of(context).pop(); // Закрываем диалог
              Navigator.of(context).pop(true); // Возвращаемся на предыдущий экран с результатом
            },
            child: Text(AppLocalizations.of(context)!.return_to_dictionary),
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
            child: Text(AppLocalizations.of(context)!.try_again),
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
        title: Text(AppLocalizations.of(context)!.time_up),
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
              AppLocalizations.of(context)!.time_up_message,
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
            child: Text(AppLocalizations.of(context)!.return_to_dictionary),
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
            child: Text(AppLocalizations.of(context)!.try_again),
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
        return AppLocalizations.of(context)!.gesture_not_detected;
      case 'Open Palm':
        return AppLocalizations.of(context)!.open_palm;
      case 'Fist':
        return AppLocalizations.of(context)!.fist;
      case 'Thumbs Up':
        return AppLocalizations.of(context)!.thumbs_up;
      case 'Victory':
        return AppLocalizations.of(context)!.victory;
      case 'Pointing':
        return AppLocalizations.of(context)!.pointing;
      case 'Rock':
        return AppLocalizations.of(context)!.rock;
      case 'Unknown':
        return AppLocalizations.of(context)!.unknown_gesture;
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
          title: Text(AppLocalizations.of(context)!.gestures_practice),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _cleanupResources();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            if (_allGestures.length > 1)
              DropdownButton<Gesture>(
                value: _allGestures.contains(_currentGesture) ? _currentGesture : (_allGestures.isNotEmpty ? _allGestures[0] : null),
                onChanged: (g) {
                  if (g != null) _onGestureChanged(g);
                },
                items: _allGestures.map((g) {
                  final locale = Localizations.localeOf(context).languageCode;
                  final title = locale == 'en' ? g.nameEn ?? g.name : g.name;
                  return DropdownMenuItem(
                    value: g,
                    child: Text(title),
                  );
                }).toList(),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _currentGesture?.imagePath ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.gesture, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.show_gesture,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _currentGesture?.name ?? '',
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
                    AppLocalizations.of(context)!.step((_currentInstructionIndex + 1).toString(), _instructions.length.toString()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _instructions.isNotEmpty ? _instructions[_currentInstructionIndex] : AppLocalizations.of(context)!.follow_instructions,
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
                            AppLocalizations.of(context)!.initializing_camera,
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
                              child: Text(AppLocalizations.of(context)!.try_again),
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
                              AppLocalizations.of(context)!.camera_not_initialized,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initializeCamera,
                              child: Text(AppLocalizations.of(context)!.initialize_camera),
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
                              AppLocalizations.of(context)!.correct,
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
                          AppLocalizations.of(context)!.recognized_gesture,
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