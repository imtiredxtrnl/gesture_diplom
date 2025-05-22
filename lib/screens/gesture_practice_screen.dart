// lib/screens/gesture_practice_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GesturePracticeScreen extends StatefulWidget {
  final String gestureName;
  final String gestureDescription;

  const GesturePracticeScreen({
    Key? key,
    required this.gestureName,
    required this.gestureDescription,
  }) : super(key: key);

  @override
  State<GesturePracticeScreen> createState() => _GesturePracticeScreenState();
}

class _GesturePracticeScreenState extends State<GesturePracticeScreen> {
  CameraController? _controller;
  late WebSocketChannel _channel;
  String result = '';
  bool _sending = false;
  Timer? _practiceTimer;
  int _timeLeft = 60; // Таймер на 60 секунд
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8765'));
    _channel.stream.listen((message) {
      setState(() {
        // Обрабатываем полученные данные от сервера
        final response = json.decode(message);
        if (response.containsKey('gesture')) {
          result = response['gesture'];
        } else {
          result = 'Error: ${response['status']}';
        }
      });
    });
    _startPracticeTimer();
  }

  void _startPracticeTimer() {
    _isTimerRunning = true;
    _practiceTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _isTimerRunning = false;
          timer.cancel();
          _showPracticeComplete();
        }
      });
    });
  }

  void _showPracticeComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Практика завершена!'),
        content: Text('Время вышло. Хорошая работа!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Возвращаемся к списку жестов
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final controller = CameraController(cameras[0], ResolutionPreset.medium);
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _controller = controller; // Присваиваем только после успешной инициализации
    });
    _startFrameSendingLoop();
  }

  void _startFrameSendingLoop() {
    Timer.periodic(Duration(milliseconds: 300), (timer) async {
      if (_controller == null || !_controller!.value.isInitialized || _sending) return;
      _sending = true;
      try {
        final XFile picture = await _controller!.takePicture();
        final bytes = await picture.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Отправляем изображение на сервер в формате JSON
        final request = json.encode({
          'type': 'gesture',
          'image': base64Image,
        });
        _channel.sink.add(request);  // Отправка данных на сервер
      } catch (e) {
        print("Error taking or sending image: $e");
      }
      _sending = false;
    });
  }

  @override
  void dispose() {
    _practiceTimer?.cancel();
    _controller?.dispose();
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Практика жеста'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formattedTime,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о жесте
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Практикуем: ${widget.gestureName}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Описание: ${widget.gestureDescription}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                if (_isTimerRunning)
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.deepPurple, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Осталось времени: $_formattedTime',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Камера
          Expanded(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          // Результат распознавания
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Распознанный жест:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: result.isEmpty ? Colors.grey[100] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: result.isEmpty ? Colors.grey[300]! : Colors.blue[300]!,
                    ),
                  ),
                  child: Text(
                    result.isEmpty ? 'Ожидание распознавания...' : result,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: result.isEmpty ? Colors.grey[600] : Colors.blue[800],
                    ),
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