// lib/screens/add_test_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/test_model.dart';
import '../services/admin_service.dart';

class AddTestScreen extends StatefulWidget {
  final Test? test; // Если не null, то редактируем существующий тест

  const AddTestScreen({Key? key, this.test}) : super(key: key);

  @override
  _AddTestScreenState createState() => _AddTestScreenState();
}

class _AddTestScreenState extends State<AddTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
      4, (_) => TextEditingController()
  );
  final AdminService _adminService = AdminService();

  String _selectedCategory = 'basic';
  int _correctOptionIndex = 0;
  File? _imageFile;
  bool _isLoading = false;

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

  final Map<String, String> _categoryLabels = {
    'basic': 'Базовые',
    'greetings': 'Приветствие',
    'questions': 'Вопросы',
    'emotions': 'Эмоции',
    'actions': 'Действия',
    'family': 'Семья',
    'food': 'Еда',
    'numbers': 'Числа',
  };

  @override
  void initState() {
    super.initState();
    if (widget.test != null) {
      // Заполняем поля для редактирования
      _questionController.text = widget.test!.question;
      _selectedCategory = widget.test!.category;
      _correctOptionIndex = widget.test!.correctOptionIndex;

      for (int i = 0; i < widget.test!.options.length && i < 4; i++) {
        _optionControllers[i].text = widget.test!.options[i];
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveTest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Проверяем, что все варианты ответов заполнены
    bool allOptionsFilled = _optionControllers.every((controller) =>
    controller.text.trim().isNotEmpty);

    if (!allOptionsFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, заполните все варианты ответов')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      List<String> options = _optionControllers
          .map((controller) => controller.text.trim())
          .toList();

      // Путь к изображению (в реальном приложении здесь был бы upload на сервер)
      String imagePath = widget.test?.imagePath ?? 'assets/tests/test_${DateTime.now().millisecondsSinceEpoch}.png';

      if (widget.test == null) {
        // Создаем новый тест
        result = await _adminService.createTest(
          question: _questionController.text.trim(),
          options: options,
          correctOptionIndex: _correctOptionIndex,
          category: _selectedCategory,
          imagePath: imagePath,
        );
      } else {
        // Обновляем существующий тест
        result = await _adminService.updateTest(
          id: widget.test!.id,
          question: _questionController.text.trim(),
          options: options,
          correctOptionIndex: _correctOptionIndex,
          category: _selectedCategory,
          imagePath: imagePath,
        );
      }

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.test == null
                ? 'Тест успешно добавлен!'
                : 'Тест успешно обновлен!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении теста: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test == null ? 'Добавить тест' : 'Редактировать тест'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Сохранение теста...'),
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
              _buildSectionTitle('Основная информация'),
              SizedBox(height: 16),

              // Вопрос теста
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Вопрос теста *',
                  hintText: 'Введите вопрос для теста',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.help_outline),
                ),
                maxLines: 2,
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
                  labelText: 'Категория',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_categoryLabels[category] ?? category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              SizedBox(height: 24),

              _buildSectionTitle('Изображение (необязательно)'),
              SizedBox(height: 16),

              // Изображение
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : widget.test?.imagePath?.isNotEmpty == true
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      widget.test!.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    ),
                  )
                      : _buildImagePlaceholder(),
                ),
              ),
              SizedBox(height: 24),

              _buildSectionTitle('Варианты ответов'),
              SizedBox(height: 16),

              // Варианты ответов
              ...List.generate(4, (index) => _buildOptionField(index)),

              SizedBox(height: 32),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.test == null ? 'Создать тест' : 'Сохранить изменения',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 32,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'Добавить изображение',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
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
              }
            },
            activeColor: Colors.green,
          ),
          Expanded(
            child: TextFormField(
              controller: _optionControllers[index],
              decoration: InputDecoration(
                labelText: 'Вариант ${index + 1}${isCorrect ? " (правильный)" : ""}',
                hintText: isCorrect ? 'Правильный ответ' : 'Вариант ответа',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isCorrect ? Colors.green : Colors.grey[300]!,
                    width: isCorrect ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isCorrect ? Colors.green : Colors.deepPurple,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Заполните вариант ответа';
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