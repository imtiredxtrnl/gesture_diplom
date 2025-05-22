import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/test_model.dart';

class AddTestScreen extends StatefulWidget {
  @override
  _AddTestScreenState createState() => _AddTestScreenState();
}

class _AddTestScreenState extends State<AddTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
      4, (_) => TextEditingController()
  );

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
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveTest() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пожалуйста, выберите изображение для теста')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // В реальном приложении здесь был бы API-запрос на сохранение
        // Для примера просто делаем задержку
        await Future.delayed(Duration(seconds: 1));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Тест успешно добавлен!')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении теста: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить тест'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Основная информация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Вопрос теста',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите вопрос';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
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
              Text(
                'Изображение',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Нажмите, чтобы выбрать изображение',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTest,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Сохранить тест',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
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
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите вариант ответа';
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