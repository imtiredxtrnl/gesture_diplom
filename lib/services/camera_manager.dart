// lib/services/camera_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraManager {
  static final CameraManager _instance = CameraManager._internal();
  factory CameraManager() => _instance;
  CameraManager._internal();

  CameraController? _controller;
  int _referenceCount = 0;
  Completer<void>? _initCompleter;

  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  // Геттер для получения контроллера
  CameraController? get controller => _controller;

  Future<CameraController?> initializeCamera({
    CameraLensDirection preferredLensDirection = CameraLensDirection.front,
    ResolutionPreset resolution = ResolutionPreset.medium
  }) async {
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
    _initCompleter = null;
  }

  // Форсированное освобождение камеры
  void forceReleaseCamera() {
    debugPrint('CameraManager: forceReleaseCamera вызван');
    _disposeCamera();
  }

  // Получение изображения с камеры
  Future<XFile?> takePicture() async {
    if (!isInitialized) {
      debugPrint('CameraManager: Попытка сделать снимок с неинициализированной камерой');
      return null;
    }

    try {
      return await _controller!.takePicture();
    } catch (e) {
      debugPrint('CameraManager: Ошибка при захвате изображения: $e');

      // Если произошла ошибка, попробуем переинициализировать камеру
      if (e.toString().contains('closed') ||
          e.toString().contains('released') ||
          e.toString().contains('not initialized')) {
        debugPrint('CameraManager: Попытка переинициализировать камеру после ошибки');
        try {
          _disposeCamera();
          await initializeCamera();
          if (_controller != null && _controller!.value.isInitialized) {
            return await _controller!.takePicture();
          }
        } catch (reinitError) {
          debugPrint('CameraManager: Ошибка переинициализации камеры: $reinitError');
        }
      }

      return null;
    }
  }

  // Переключение между передней и задней камерой
  Future<bool> switchCamera() async {
    if (!isInitialized) {
      debugPrint('CameraManager: Камера не инициализирована для переключения');
      return false;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        debugPrint('CameraManager: Недостаточно камер для переключения');
        return false;
      }

      final currentLensDirection = _controller!.description.lensDirection;
      final newLensDirection = currentLensDirection == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;

      final newCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == newLensDirection,
        orElse: () => cameras.first,
      );

      // Сохраняем текущие настройки
      final currentResolution = _controller!.resolutionPreset;

      // Освобождаем текущий контроллер
      await _controller!.dispose();

      // Создаем новый контроллер
      _controller = CameraController(
        newCamera,
        currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Инициализируем новую камеру
      await _controller!.initialize();

      debugPrint('CameraManager: Камера переключена на ${newLensDirection.toString()}');
      return true;
    } catch (e) {
      debugPrint('CameraManager: Ошибка переключения камеры: $e');
      return false;
    }
  }

  // Получение списка доступных камер
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      debugPrint('CameraManager: Ошибка получения списка камер: $e');
      return [];
    }
  }

  // Проверка доступности камеры с определенным направлением
  Future<bool> isCameraAvailable(CameraLensDirection direction) async {
    final cameras = await getAvailableCameras();
    return cameras.any((camera) => camera.lensDirection == direction);
  }

  // Получение текущего направления камеры
  CameraLensDirection? get currentCameraDirection {
    return _controller?.description.lensDirection;
  }

  // Получение разрешения камеры
  Size? get previewSize {
    return _controller?.value.previewSize;
  }

  // Проверка, поддерживает ли устройство переключение камер
  Future<bool> get canSwitchCamera async {
    final cameras = await getAvailableCameras();
    return cameras.length > 1;
  }

  // Установка режима вспышки
  Future<bool> setFlashMode(FlashMode mode) async {
    if (!isInitialized) {
      debugPrint('CameraManager: Камера не инициализирована для установки вспышки');
      return false;
    }

    try {
      await _controller!.setFlashMode(mode);
      debugPrint('CameraManager: Режим вспышки установлен: $mode');
      return true;
    } catch (e) {
      debugPrint('CameraManager: Ошибка установки режима вспышки: $e');
      return false;
    }
  }

  // Установка режима экспозиции
  Future<bool> setExposureMode(ExposureMode mode) async {
    if (!isInitialized) {
      debugPrint('CameraManager: Камера не инициализирована для установки экспозиции');
      return false;
    }

    try {
      await _controller!.setExposureMode(mode);
      debugPrint('CameraManager: Режим экспозиции установлен: $mode');
      return true;
    } catch (e) {
      debugPrint('CameraManager: Ошибка установки режима экспозиции: $e');
      return false;
    }
  }

  // Пауза превью камеры
  Future<bool> pausePreview() async {
    if (!isInitialized) {
      debugPrint('CameraManager: Камера не инициализирована для паузы');
      return false;
    }

    try {
      await _controller!.pausePreview();
      debugPrint('CameraManager: Превью приостановлено');
      return true;
    } catch (e) {
      debugPrint('CameraManager: Ошибка приостановки превью: $e');
      return false;
    }
  }

  // Возобновление превью камеры
  Future<bool> resumePreview() async {
    if (!isInitialized) {
      debugPrint('CameraManager: Камера не инициализирована для возобновления');
      return false;
    }

    try {
      await _controller!.resumePreview();
      debugPrint('CameraManager: Превью возобновлено');
      return true;
    } catch (e) {
      debugPrint('CameraManager: Ошибка возобновления превью: $e');
      return false;
    }
  }

  // Получение состояния камеры
  CameraValue? get cameraValue {
    return _controller?.value;
  }

  // Проверка, записывается ли видео
  bool get isRecordingVideo {
    return _controller?.value.isRecordingVideo ?? false;
  }

  // Проверка, делается ли снимок
  bool get isTakingPicture {
    return _controller?.value.isTakingPicture ?? false;
  }

  // Получение текущего режима вспышки
  FlashMode? get currentFlashMode {
    return _controller?.value.flashMode;
  }

  // Получение текущего режима экспозиции
  ExposureMode? get currentExposureMode {
    return _controller?.value.exposureMode;
  }

  // Проверка готовности камеры для захвата изображения
  bool get isReadyForCapture {
    return isInitialized &&
        !isTakingPicture &&
        !isRecordingVideo &&
        _controller!.value.isInitialized;
  }

  // Получение статистики камеры
  Map<String, dynamic> getCameraStats() {
    if (!isInitialized) {
      return {
        'initialized': false,
        'reference_count': _referenceCount,
        'cameras_available': 0,
      };
    }

    return {
      'initialized': true,
      'reference_count': _referenceCount,
      'camera_direction': currentCameraDirection?.toString() ?? 'unknown',
      'preview_size': previewSize?.toString() ?? 'unknown',
      'is_recording': isRecordingVideo,
      'is_taking_picture': isTakingPicture,
      'is_ready_for_capture': isReadyForCapture,
      'flash_mode': currentFlashMode?.toString() ?? 'unknown',
      'exposure_mode': currentExposureMode?.toString() ?? 'unknown',
      'resolution': _controller?.resolutionPreset.toString() ?? 'unknown',
    };
  }

  // Получение информации о камере для отладки
  String getDebugInfo() {
    final stats = getCameraStats();
    return 'CameraManager Debug Info:\n' +
        stats.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
  }

  // Переинициализация камеры с теми же настройками
  Future<bool> reinitializeCamera() async {
    if (!isInitialized) {
      debugPrint('CameraManager: Камера не была инициализирована');
      return false;
    }

    try {
      final currentDirection = _controller!.description.lensDirection;
      final currentResolution = _controller!.resolutionPreset;

      _disposeCamera();

      final result = await initializeCamera(
        preferredLensDirection: currentDirection,
        resolution: currentResolution,
      );

      return result != null;
    } catch (e) {
      debugPrint('CameraManager: Ошибка переинициализации: $e');
      return false;
    }
  }

  // Проверка здоровья камеры
  bool get isCameraHealthy {
    return isInitialized &&
        _controller!.value.isInitialized &&
        !_controller!.value.hasError;
  }

  // Получение описания ошибки камеры
  String? get cameraError {
    return _controller?.value.errorDescription;
  }
}