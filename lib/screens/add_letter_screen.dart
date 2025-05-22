import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddLetterScreen extends StatefulWidget {
  final String language;

  AddLetterScreen({required this.language});

  @override
  _AddLetterScreenState createState() => _AddLetterScreenState();
}

class _AddLetterScreenState extends State<AddLetterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _letterController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  String get languageName => widget.language == 'uk' ? 'украинский' : 'английский';

  @override
  void dispose() {
    _letterController.dispose();
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

  Future<void> _saveLetter() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пожалуйста, выберите изображение жеста для буквы')),
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
          SnackBar(content: Text('Буква успешно добавлена!')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении буквы: $e')),
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
          title: Text('Добавить букву (${languageName})'),
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
    'Данные буквы',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    ),
    ),
    SizedBox(height: 16),
    TextFormField(
    controller: _letterController,
    decoration: InputDecoration(
    labelText: 'Буква',
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    maxLength: 1,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 24),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Пожалуйста, введите букву';
    }
    return null;
    },
    ),
    SizedBox(height: 24),
    Text(
    'Изображение жеста для буквы',
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
      SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _saveLetter,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Сохранить букву',
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
}