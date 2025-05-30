// lib/screens/add_gesture_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/gesture.dart';
import '../services/admin_service.dart';

class AddGestureScreen extends StatefulWidget {
  final Gesture? gesture; // Если не null, то редактируем существующий жест

  const AddGestureScreen({Key? key, this.gesture}) : super(key: key);

  @override
  _AddGestureScreenState createState() => _AddGestureScreenState();
}

class _AddGestureScreenState extends State<AddGestureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AdminService _adminService = AdminService();

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
    if (widget.gesture != null) {
      // Заполняем поля для редактирования
      _nameController.text = widget.gesture!.name;
      _descriptionController.text = widget.gesture!.description;
      _selectedCategory = widget.gesture!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

  Future<void> _saveGesture() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Для демо версии не требуем обязательное изображение
    /*if (_imageFile == null && widget.gesture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, выберите изображение жеста')),
      );
      return;
    }*/

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      // Путь к изображению (в реальном приложении здесь был бы upload на сервер)
      String imagePath = widget.gesture?.imagePath?.isNotEmpty == true
          ? widget.gesture!.imagePath
          : 'assets/gestures/${_nameController.text.toLowerCase().replaceAll(' ', '_')}.png';

      if (widget.gesture == null) {
        // Создаем новый жест
        result = await _adminService.createGesture(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          imagePath: imagePath,
        );
      } else {
        // Обновляем существующий жест
        result = await _adminService.updateGesture(
          id: widget.gesture!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          imagePath: imagePath,
        );
      }

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.gesture == null
                ? 'Жест успешно добавлен!'
                : 'Жест успешно обновлен!'),
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
          content: Text('Ошибка при сохранении жеста: $e'),
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
        title: Text(widget.gesture == null ? 'Добавить жест' : 'Редактировать жест'),
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
              _buildSectionTitle('Основная информация'),
              SizedBox(height: 16),

              // Название жеста
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название жеста *',
                  hintText: 'Введите название жеста',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.gesture),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите название жеста';
                  }
                  if (value.trim().length < 2) {
                    return 'Название должно содержать минимум 2 символа';
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
              SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание жеста *',
                  hintText: 'Опишите как выполняется жест',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
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

              _buildSectionTitle('Изображение жеста'),
              SizedBox(height: 16),

              // Изображение
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
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
                      : widget.gesture?.imagePath?.isNotEmpty == true
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      widget.gesture!.imagePath,
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
              SizedBox(height: 8),
              Text(
                'Нажмите на область выше, чтобы выбрать изображение',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveGesture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.gesture == null ? 'Добавить жест' : 'Сохранить изменения',
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
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'Выберите изображение жеста',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '(необязательно для демо)',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}