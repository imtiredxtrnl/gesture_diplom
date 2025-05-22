import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  String _errorMessage = '';
  bool _isRegistering = false;

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    // Валидация полей
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Все поля обязательны для заполнения';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Пароли не совпадают';
      });
      return;
    }

    // Установка состояния регистрации
    setState(() {
      _isRegistering = true;
      _errorMessage = 'Регистрация...';
    });

    // Формирование данных для отправки
    final registerData = json.encode({
      'type': 'register',
      'email': email,
      'password': password,
      'name': name,
      'photo': '',
    });

    print("Sending registration data: $registerData");

    try {
      // Создаем новый канал для регистрации
      final registerChannel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8765'));

      // Отправляем запрос на регистрацию
      registerChannel.sink.add(registerData);

      // Слушаем ответ
      registerChannel.stream.listen((response) async {
        print("Received register response: $response");
        final responseData = json.decode(response);

        setState(() {
          _isRegistering = false;
        });

        if (responseData['status'] == 'Success') {
          // Показываем сообщение об успешной регистрации
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Регистрация успешна! Теперь вы можете войти.'))
          );

          // Возвращаемся на экран входа
          Navigator.pop(context);
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Ошибка регистрации';
          });
        }

        // Закрываем канал
        registerChannel.sink.close();
      }, onError: (error) {
        print("Register WebSocket error: $error");
        setState(() {
          _isRegistering = false;
          _errorMessage = 'Ошибка соединения: $error';
        });
        // Закрываем канал
        registerChannel.sink.close();
      }, onDone: () {
        if (_isRegistering) {
          setState(() {
            _isRegistering = false;
            _errorMessage = 'Соединение закрыто до получения ответа';
          });
        }
      });
    } catch (e) {
      setState(() {
        _isRegistering = false;
        _errorMessage = 'Ошибка соединения с сервером: $e';
      });
      print("Error connecting to WebSocket server: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Регистрация'),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Создание нового аккаунта',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Подтвердите пароль',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isRegistering ? null : _register,
                child: _isRegistering ?
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                    ),
                    SizedBox(width: 10),
                    Text('Регистрация...'),
                  ],
                ) :
                Text('Зарегистрироваться'),
              ),
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}