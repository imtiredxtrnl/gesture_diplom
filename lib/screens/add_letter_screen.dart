// lib/screens/add_letter_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/alphabet_letter.dart';
import '../services/admin_service.dart';

class AddLetterScreen extends StatefulWidget {
  final String language;
  final AlphabetLetter? letter; // Если не null, то редактируем существующую букву

  const AddLetterScreen({
    Key? key,
    required this.language,
    this.letter,
  }) : super(key: key);

  @override
  _AddLetterScreenState createState() => _AddLetterScreenState();
}

class _AddLetterScreenState extends State<AddLetterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _letterController = TextEditingController();
  final AdminService _adminService = AdminService();

  File? _imageFile;
  bool _isLoading = false;

  String get languageName => widget.language == 'uk' ? 'украинский' : 'английский';

  @override
  void initState() {
    super.initState();
    if (widget.letter != null) {
      // Заполняем поле для редактирования
      _letterController.text = widget.letter!.letter;
    }
  }

  @override
  void dispose() {
    _letterController.dispose();
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

  Future<void> _saveLetter() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      // Путь к изображению (в реальном приложении здесь был бы upload на сервер)
      String imagePath = widget.letter?.imagePath?.isNotEmpty == true
          ? widget.letter!.imagePath
          : 'assets/alphabet/${widget.language}/${_letterController.text.toLowerCase()}.png';

      if (widget.letter == null) {
        // Создаем новую букву
        result = await _adminService.createLetter(
          letter: _letterController.text.trim().toUpperCase(),
          language: widget.language,
          imagePath: imagePath,
        );
      } else {
        // Обновляем существующую букву
        result = await _adminService.updateLetter(
          id: widget.letter!.id,
          letter: _letterController.text.trim().toUpperCase(),
          language: widget.language,
          imagePath: imagePath,
        );
      }

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.letter == null
                ? 'Буква успешно добавлена!'
                : 'Буква успешно обновлена!'),
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
          content: Text('Ошибка при сохранении буквы: $e'),
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
        title: Text(widget.letter == null
            ? 'Добавить букву ($languageName)'
            : 'Редактировать букву ($languageName)'),
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
            Text('Сохранение буквы...'),
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
              _buildSectionTitle('Данные буквы'),
              SizedBox(height: 16),

              // Поле ввода буквы
              TextFormField(
                controller: _letterController,
                decoration: InputDecoration(
                  labelText: 'Буква *',
                  hintText: 'Введите букву',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.text_fields),
                  counterText: '', // Убираем счетчик символов
                ),
                maxLength: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  // Автоматически преобразуем в верхний регистр
                  if (value.isNotEmpty) {
                    final upperValue = value.toUpperCase();
                    if (value != upperValue) {
                      _letterController.value = _letterController.value.copyWith(
                        text: upperValue,
                        selection: TextSelection.collapsed(offset: upperValue.length),
                      );
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите букву';
                  }

                  // Проверяем для украинского алфавита
                  if (widget.language == 'uk') {
                    const ukrainianLetters = 'АБВГДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЬЮЯ';
                    if (!ukrainianLetters.contains(value.toUpperCase())) {
                      return 'Введите украинскую букву';
                    }
                  }
                  // Проверяем для английского алфавита
                  else if (widget.language == 'en') {
                    const englishLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                    if (!englishLetters.contains(value.toUpperCase())) {
                      return 'Введите английскую букву';
                    }
                  }

                  return null;
                },
              ),
              SizedBox(height: 24),

              _buildSectionTitle('Изображение жеста для буквы'),
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
                      : widget.letter?.imagePath?.isNotEmpty == true
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      widget.letter!.imagePath,
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
                'Нажмите на область выше, чтобы выбрать изображение жеста',
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
                  onPressed: _saveLetter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.letter == null ? 'Добавить букву' : 'Сохранить изменения',
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