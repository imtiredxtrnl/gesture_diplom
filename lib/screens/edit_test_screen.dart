// lib/screens/edit_test_screen.dart
import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/test_data_service.dart';

class EditTestScreen extends StatefulWidget {
  final Test test;

  EditTestScreen({required this.test});

  @override
  _EditTestScreenState createState() => _EditTestScreenState();
}

class _EditTestScreenState extends State<EditTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
      4, (_) => TextEditingController()
  );
  final TestDataService _testService = TestDataService();

  String _selectedCategory = 'basic';
  int _correctOptionIndex = 0;
  bool _isLoading = false;
  bool _hasChanges = false;

  final List<String> _categories = [
    'basic',
    'greetings',
    'questions',
    'emotions',
    'actions',
    'family',
    'food',
    'numbers',
  ];

  @override
  void initState() {
    super.initState();
    // Заполняем поля данными существующего теста
    _questionController.text = widget.test.question;
    _selectedCategory = widget.test.category;
    _correctOptionIndex = widget.test.correctOptionIndex;

    // Заполняем варианты ответов
    for (int i = 0; i < widget.test.options.length && i < 4; i++) {
      _optionControllers[i].text = widget.test.options[i];
    }

    // Добавляем слушателей для отслеживания изменений
    _questionController.addListener(_onFieldChanged);
    for (var controller in _optionControllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    _questionController.removeListener(_onFieldChanged);
    for (var controller in _optionControllers) {
      controller.removeListener(_onFieldChanged);
    }
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = _questionController.text != widget.test.question ||
          _selectedCategory != widget.test.category ||
          _correctOptionIndex != widget.test.correctOptionIndex ||
          _optionsChanged();
    });
  }

  bool _optionsChanged() {
    for (int i = 0; i < widget.test.options.length && i < 4; i++) {
      if (_optionControllers[i].text != widget.test.options[i]) {
        return true;
      }
    }
    return false;
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'basic':
        return 'Основные';
      case 'greetings':
        return 'Приветствия';
      case 'questions':
        return 'Вопросы';
      case 'emotions':
        return 'Эмоции';
      case 'actions':
        return 'Действия';
      case 'family':
        return 'Семья';
      case 'food':
        return 'Еда';
      case 'numbers':
        return 'Числа';
      default:
        return category;
    }
  }

  Future<void> _saveTest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Создаем список опций
      final options = _optionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (options.length < 2) {
        throw Exception('Необходимо минимум 2 варианта ответа');
      }

      if (_correctOptionIndex >= options.length) {
        throw Exception('Неверный индекс правильного ответа');
      }

      // Создаем обновленный тест
      final updatedTest = widget.test.copyWith(
        question: _questionController.text.trim(),
        category: _selectedCategory,
        options: options,
        correctOptionIndex: _correctOptionIndex,
      );

      // Сохраняем изменения
      await _testService.updateTest(updatedTest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тест успешно обновлен!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении теста: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Несохраненные изменения'),
        content: Text('У вас есть несохраненные изменения. Вы уверены, что хотите выйти без сохранения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ОСТАТЬСЯ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('ВЫЙТИ БЕЗ СОХРАНЕНИЯ'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Редактировать тест'),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: Icon(Icons.save),
                onPressed: _isLoading ? null : _saveTest,
                tooltip: 'Сохранить',
              ),
          ],
        ),
        body: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.deepPurple),
              SizedBox(height: 16),
              Text('Сохранение изменений...'),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о тесте
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Редактирование теста',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ID: ${widget.test.id}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Основная информация
                Text(
                  'Основная информация',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Вопрос теста
                TextFormField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    labelText: 'Вопрос теста *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Пожалуйста, введите вопрос';
                    }
                    if (value.trim().length < 10) {
                      return 'Вопрос должен содержать минимум 10 символов';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Категория
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Категория *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_getCategoryDisplayName(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _onFieldChanged();
                    }
                  },
                ),

                SizedBox(height: 24),

                // Варианты ответов
                Text(
                  'Варианты ответов',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                ...List.generate(4, (index) => _buildOptionField(index)),

                SizedBox(height: 32),

                // Кнопки действий
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text('Отмена'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading || !_hasChanges ? null : _saveTest,
                        child: Text('Сохранить изменения'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionField(int index) {
    final isCorrect = _correctOptionIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Radio<int>(
            value: index,
            groupValue: _correctOptionIndex,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _correctOptionIndex = value;
                });
                _onFieldChanged();
              }
            },
          ),
          Expanded(
            child: TextFormField(
              controller: _optionControllers[index],
              decoration: InputDecoration(
                labelText: 'Вариант ${index + 1}',
                hintText: isCorrect ? 'Правильный ответ' : 'Вариант ответа',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isCorrect ? Colors.green : Colors.grey,
                    width: isCorrect ? 2 : 1,
                  ),
                ),
              ),
              validator: (value) {
                if (index < 2 && (value == null || value.isEmpty)) {
                  return 'Первые два варианта обязательны';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}