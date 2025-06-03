// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/test_data_service.dart';
import 'services/gesture_data_service.dart';

void main() {
  runApp(SignLanguageApp());
}

class SignLanguageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Language App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Инициализируем сервисы
      await _initializeServices();

      // Даем немного времени для инициализации приложения
      await Future.delayed(Duration(seconds: 1));

      // Проверяем, авторизован ли пользователь
      final isAuth = await AuthService.isAuthenticated();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAuth ? MainScreen() : AuthScreen(),
          ),
        );
      }
    } catch (e) {
      print('Error initializing app: $e');

      if (mounted) {
        // В случае ошибки переходим на экран авторизации
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      }
    }
  }

  Future<void> _initializeServices() async {
    // Инициализируем сервис жестов
    final gestureService = GestureDataService();
    await gestureService.initializeGestures();

    // Инициализируем сервис тестов
    final testService = TestDataService();
    await testService.initializeTests();

    print('App services initialized successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип приложения
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.sign_language,
                size: 60,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 32),

            // Название приложения
            Text(
              'Изучение языка жестов',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Интерактивное обучение',
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple[400],
              ),
            ),

            SizedBox(height: 48),

            // Индикатор загрузки
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),

            SizedBox(height: 16),

            Text(
              'Инициализация...',
              style: TextStyle(
                color: Colors.deepPurple[300],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}