// lib/screens/main_screen.dart - проверьте импорты в начале файла
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'gestures_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'admin_panel_screen.dart';
import 'auth_screen.dart';
// Убедитесь, что нет импортов старых practice_screen.dart или

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Проверяем статус пользователя
    if (AuthService.currentUser == null) {
      // Если пользователь не установлен, пробуем авторизоваться с сохраненными данными
      final credentials = await AuthService.loadUserCredentials();
      final username = credentials['username'];
      final password = credentials['password'];

      if (username != null && password != null) {
        try {
          final result = await AuthService.login(username, password);

          if (result['status'] != 'Login successful' && result['status'] != 'success') {
            // Если авторизация не удалась, перенаправляем на экран входа
            _redirectToAuth();
            return;
          }
        } catch (e) {
          print('Error logging in: $e');
          _redirectToAuth();
          return;
        }
      } else {
        // Нет сохраненных данных, перенаправляем на экран входа
        _redirectToAuth();
        return;
      }
    }

    bool isAdmin = AuthService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  void _redirectToAuth() {
    // Перенаправляем пользователя на экран авторизации
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen())
      );
    });
  }

  List<Widget> get _screens {
    final baseScreens = [
      CameraScreen(),
      GesturesScreen(),
      ProfileScreen(),
    ];

    // Добавляем экран админ-панели, если пользователь - админ
    if (_isAdmin) {
      return [...baseScreens, AdminPanelScreen()];
    }

    return baseScreens;
  }

  List<String> get _titles {
    final baseTitles = [
      'Камера',
      'Жести',
      'Профіль',
    ];

    // Добавляем название для админ-панели, если пользователь - админ
    if (_isAdmin) {
      return [...baseTitles, 'Адмін-панель'];
    }

    return baseTitles;
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Важно для более 3 элементов
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Камера',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sign_language),
            label: 'Жести',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профіль',
          ),
          if (_isAdmin)
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Адмін',
            ),
        ],
      ),
    );
  }
}