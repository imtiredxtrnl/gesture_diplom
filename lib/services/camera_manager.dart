import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gesture.dart';
import '../services/camera_manager.dart';
class CameraManager {
  static final CameraManager _instance = CameraManager._internal();
  factory CameraManager() => _instance;
  CameraManager._internal();

  CameraController? _controller;
  int _referenceCount = 0;
  Completer<void>? _initCompleter;

  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  // Добавляем геттер для получения контроллера
  CameraController? get controller => _controller;

  Future<CameraController?> initializeCamera(
      {CameraLensDirection preferredLensDirection = CameraLensDirection.front,
        ResolutionPreset resolution = ResolutionPreset.medium}) async {

    // Если инициализация уже идёт, ждём её завершения
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      await _initCompleter!.future;
    }

    // Если контроллер уже инициализирован, просто увеличиваем счётчик
    if (isInitialized) {
      _referenceCount++;
      return _controller;
    }

    // Начинаем новую инициализацию
    _initCompleter = Completer<void>();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('CameraManager: Камеры не найдены!');
        _initCompleter!.complete();
        return null;
      }

      // Выбираем камеру с предпочтительным направлением объектива
      final camera = cameras.firstWhere(
            (camera) => camera.lensDirection == preferredLensDirection,
        orElse: () => cameras.first,
      );

      // Создаём новый контроллер
      final controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Инициализируем камеру
      await controller.initialize();

      // Сохраняем контроллер и увеличиваем счётчик ссылок
      _controller = controller;
      _referenceCount = 1;

      debugPrint('CameraManager: Камера успешно инициализирована!');
      _initCompleter!.complete();
      return _controller;
    } catch (e) {
      debugPrint('CameraManager: Ошибка инициализации камеры: $e');
      _initCompleter!.completeError(e);
      rethrow;
    }
  }

  void releaseCamera() {
    _referenceCount--;
    debugPrint('CameraManager: releaseCamera вызван, счётчик: $_referenceCount');

    // Освобождаем ресурсы только если никто больше не использует камеру
    if (_referenceCount <= 0) {
      _disposeCamera();
    }
  }

  void _disposeCamera() {
    debugPrint('CameraManager: _disposeCamera вызван');
    if (_controller != null) {
      _controller!.dispose().then((_) {
        debugPrint('CameraManager: Камера успешно освобождена');
      }).catchError((e) {
        debugPrint('CameraManager: Ошибка при освобождении камеры: $e');
      });
      _controller = null;
    }
    _referenceCount = 0;
  }

  // Форсированное освобождение камеры, вне зависимости от счётчика ссылок
  void forceReleaseCamera() {
    debugPrint('CameraManager: forceReleaseCamera вызван');
    _disposeCamera();
  }

  // Получение изображения с камеры
  Future<XFile?> takePicture() async {
    if (!isInitialized) {
      print('CameraManager: Попытка сделать снимок с неинициализированной камерой');
      return null;
    }

    try {
      return await _controller!.takePicture();
    } catch (e) {
      print('CameraManager: Ошибка при захвате изображения: $e');

      // Если произошла ошибка, попробуем переинициализировать камеру
      if (e.toString().contains('closed') || e.toString().contains('released')) {
        print('CameraManager: Попытка переинициализировать камеру после ошибки');
        try {
          _disposeCamera();
          await initializeCamera();
          if (_controller != null && _controller!.value.isInitialized) {
            return await _controller!.takePicture();
          }
        } catch (reinitError) {
          print('CameraManager: Ошибка переинициализации камеры: $reinitError');
        }
      }

      return null;
    }
  }
}