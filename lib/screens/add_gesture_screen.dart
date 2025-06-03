// lib/screens/add_gesture_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/gesture.dart';
import '../services/gesture_data_service.dart';

class AddGestureScreen extends StatefulWidget {
  @override
  _AddGestureScreenState createState() => _AddGestureScreenState();
}

class _AddGestureScreenState extends State<AddGestureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final GestureDataService _gestureService = GestureDataService();

  String _selectedCategory = 'basic';
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
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выборе изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveGesture() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Создаем новый жест
      final newGesture = _gestureService.createGesture(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        // В реальном приложении здесь была бы загрузка изображения на сервер
        imagePath: _imageFile != null
            ? 'lib/assets/gestures/${_nameController.text.toLowerCase().replaceAll(' ', '_')}.png'
            : '',
      );

      // Сохраняем жест
      await _gestureService.addGesture(newGesture);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Жест "${newGesture.name}" успешно добавлен!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении жеста: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить жест'),
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
            Text('Сохранение жеста...'),
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
              // Заголовок секции
              Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    'Создание нового жеста',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Данные жеста
              Text(
                'Основная информация',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Название жеста
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название жеста *',
                  hintText: 'Например: Привет, Спасибо...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите название жеста';
                  }
                  if (value.trim().length < 2) {
                    return 'Название должно содержать минимум 2 символа';
                  }

                  // Проверяем, нет ли уже жеста с таким названием
                  final existingGestures = _gestureService.getAllGestures();
                  final duplicateName = existingGestures.any(
                        (gesture) => gesture.name.toLowerCase() == value.trim().toLowerCase(),
                  );
                  if (duplicateName) {
                    return 'Жест с таким названием уже существует';
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
                  }
                },
              ),

              SizedBox(height: 16),

              // Описание жеста
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание жеста *',
                  hintText: 'Подробное описание того, как выполнять жест...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите описание жеста';
                  }
                  if (value.trim().length < 10) {
                    return 'Описание должно содержать минимум 10 символов';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Изображение жеста
              Text(
                'Изображение жеста',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Добавьте изображение, демонстрирующее жест (необязательно)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),

              // Контейнер для изображения
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
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
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Нажмите, чтобы выбрать изображение',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'JPG, PNG до 5 МБ',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_imageFile != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Изображение выбрано',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      child: Text('Удалить'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],

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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveGesture,
                      child: _isLoading
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text('Создать жест'),
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

              SizedBox(height: 16),

              // Информационная подсказка
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Совет',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Создавайте четкие и понятные описания жестов. Это поможет пользователям лучше изучать язык жестов.',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}