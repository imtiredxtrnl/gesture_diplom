// lib/screens/edit_gesture_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/gesture.dart';
import '../services/gesture_data_service.dart';

class EditGestureScreen extends StatefulWidget {
  final Gesture gesture;

  EditGestureScreen({required this.gesture});

  @override
  _EditGestureScreenState createState() => _EditGestureScreenState();
}

class _EditGestureScreenState extends State<EditGestureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final GestureDataService _gestureService = GestureDataService();

  String _selectedCategory = 'basic';
  File? _imageFile;
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
    // Заполняем поля данными существующего жеста
    _nameController.text = widget.gesture.name;
    _descriptionController.text = widget.gesture.description;
    _selectedCategory = widget.gesture.category;

    // Добавляем слушателей для отслеживания изменений
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = _nameController.text != widget.gesture.name ||
          _descriptionController.text != widget.gesture.description ||
          _selectedCategory != widget.gesture.category ||
          _imageFile != null;
    });
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
        _onFieldChanged();
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
      // Создаем обновленный жест
      final updatedGesture = widget.gesture.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        // В реальном приложении здесь была бы загрузка изображения
        imagePath: _imageFile != null
            ? 'lib/assets/gestures/${_nameController.text.toLowerCase().replaceAll(' ', '_')}.png'
            : widget.gesture.imagePath,
      );

      // Сохраняем изменения
      await _gestureService.updateGesture(updatedGesture);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Жест успешно обновлен!'),
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
          title: Text('Редактировать жест'),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: Icon(Icons.save),
                onPressed: _isLoading ? null : _saveGesture,
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
                // Информация о жесте
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Редактирование жеста',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ID: ${widget.gesture.id}',
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

                // Данные жеста
                Text(
                  'Данные жеста',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Название жеста
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Название жеста *',
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

                SizedBox(height: 16),

                // Описание жеста
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Описание жеста *',
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Текущее изображение и выбор нового
                Container(
                  height: 200,
                  decoration: BoxDecoration(
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
                      : widget.gesture.imagePath.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      widget.gesture.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    ),
                  )
                      : _buildImagePlaceholder(),
                ),

                SizedBox(height: 16),

                // Кнопка выбора изображения
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.image),
                    label: Text(_imageFile != null || widget.gesture.imagePath.isNotEmpty
                        ? 'Заменить изображение'
                        : 'Выбрать изображение'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

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
                        onPressed: _isLoading || !_hasChanges ? null : _saveGesture,
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

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'Изображение не выбрано',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Нажмите кнопку ниже для выбора',
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