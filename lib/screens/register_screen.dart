import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'main_screen.dart';
import 'package:sign_language_app/l10n/app_localizations.dart';
import 'package:sign_language_app/services/auth_service.dart';

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
    final name = _nameController.text.trim();
    final confirmPassword = _confirmPasswordController.text;

    // Валидация полей
    if (email.isEmpty || password.isEmpty || name.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.validation_all_fields_required;
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.validation_passwords_do_not_match;
      });
      return;
    }

    // Установка состояния регистрации
    setState(() {
      _isRegistering = true;
      _errorMessage = AppLocalizations.of(context)!.registration_in_progress;
    });

    try {
      // Используем AuthService для регистрации
      final responseData = await AuthService.register(email, password, name);
      setState(() {
        _isRegistering = false;
      });
      if (responseData['status'] == 'Success' || responseData['status'] == 'success') {
        await Future.delayed(Duration(milliseconds: 500));
        final checkChannel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8765'));
        final checkData = json.encode({
          'type': 'auth',
          'action': 'login',
          'email': email,
          'password': password,
        });
        checkChannel.sink.add(checkData);
        final checkResp = await checkChannel.stream.first;
        checkChannel.sink.close();
        final checkResponse = json.decode(checkResp);
        if (checkResponse['status'] == 'Login successful' || checkResponse['status'] == 'success') {
          // Корректно авторизуем пользователя и сохраняем в кэш
          await AuthService.login(email, password);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
            (route) => false,
          );
        } else {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.registration_success + '\n' + (checkResponse['message'] ?? '');
          });
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? AppLocalizations.of(context)!.registration_error;
        });
      }
    } catch (e) {
      setState(() {
        _isRegistering = false;
        _errorMessage = AppLocalizations.of(context)!.connection_error_to_server + ': $e';
      });
      print("Error connecting to WebSocket server: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.registration),
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
                AppLocalizations.of(context)!.create_account,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.name,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirm_password,
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
                    Text(AppLocalizations.of(context)!.registration_in_progress),
                  ],
                ) :
                Text(AppLocalizations.of(context)!.register),
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