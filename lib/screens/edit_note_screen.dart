import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/note_service.dart';
import 'package:uuid/uuid.dart';

class EditNoteScreen extends StatefulWidget {
  final Map<String, dynamic>? note;
  final String language;
  const EditNoteScreen({Key? key, this.note, required this.language}) : super(key: key);

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _translatedController;
  late TextEditingController _translatedTitleController;
  List<String> imagePaths = [];
  List<Uint8List> imagePreviews = [];
  String selectedLanguage = 'uk';
  String targetLanguage = 'en';
  bool isSaving = false;
  bool isTranslating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?['title'] ?? '');
    _contentController = TextEditingController(text: widget.note?['content'] ?? '');
    _translatedController = TextEditingController();
    _translatedTitleController = TextEditingController();
    imagePaths = List<String>.from(widget.note?['imagePaths'] ?? []);
    selectedLanguage = widget.note?['language'] ?? widget.language;
    targetLanguage = selectedLanguage == 'uk' ? 'en' : 'uk';
  }

  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png'],
      withData: true,
    );
    if (result != null) {
      for (final file in result.files) {
        if (file.bytes != null) {
          final path = await NoteService.uploadImage(file.bytes!, file.name);
          setState(() {
            imagePaths.add(path);
            imagePreviews.add(file.bytes!);
          });
        }
      }
    }
  }

  void insertImageMarkup(int index) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.replaceRange(selection.start, selection.end, '[img:$index]');
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(offset: selection.start + '[img:$index]'.length);
    setState(() {});
  }

  Future<void> translateContent() async {
    setState(() => isTranslating = true);
    try {
      final translated = await NoteService.translateNoteText(
        _contentController.text,
        selectedLanguage,
        targetLanguage,
      );
      _translatedController.text = translated;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка перевода: $e')));
    }
    setState(() => isTranslating = false);
  }

  Future<void> saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    if (widget.note == null) {
      // Новый конспект: создаём сразу две локализации
      // 1. Создаём основной (на выбранном языке)
      final data = {
        'title': _titleController.text,
        'content': _contentController.text,
        'imagePaths': imagePaths,
        'language': selectedLanguage,
      };
      await NoteService.createNote(data);
      final allNotes = await NoteService.getAllNotes('all');
      final created = allNotes.lastWhere((n) => n['title'] == _titleController.text && n['content'] == _contentController.text && n['language'] == selectedLanguage, orElse: () => null);
      if (created != null && created['groupId'] != null) {
        String otherLang = selectedLanguage == 'uk' ? 'en' : 'uk';
        String translatedTitle = _translatedTitleController.text.isNotEmpty ? _translatedTitleController.text : _titleController.text;
        String translatedContent = _translatedController.text.isNotEmpty ? _translatedController.text : _contentController.text;
        if (_translatedController.text.isEmpty) {
          translatedContent = await NoteService.translateNoteText(_contentController.text, selectedLanguage, otherLang);
        }
        final data2 = {
          'title': translatedTitle,
          'content': translatedContent,
          'imagePaths': imagePaths,
          'language': otherLang,
          'groupId': created['groupId'],
        };
        await NoteService.createNote(data2);
      }
    } else {
      final data = {
        'title': _titleController.text,
        'content': _contentController.text,
        'imagePaths': imagePaths,
        'language': selectedLanguage,
      };
      if (widget.note != null && widget.note!["groupId"] != null) {
        data['groupId'] = widget.note!["groupId"];
      }
      await NoteService.updateNote(widget.note!['id'], data);
    }
    setState(() => isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.note == null ? 'Новий конспект' : 'Редагувати конспект')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Заголовок'),
                validator: (v) => v == null || v.isEmpty ? 'Введіть заголовок' : null,
              ),
              if (widget.note == null) ...[
                SizedBox(height: 8),
                TextFormField(
                  controller: _translatedTitleController,
                  decoration: InputDecoration(labelText: selectedLanguage == 'uk' ? 'Заголовок (English)' : 'Заголовок (Українська)'),
                ),
              ],
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLanguage,
                items: [
                  DropdownMenuItem(value: 'uk', child: Text('Українська')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) => setState(() {
                  selectedLanguage = v ?? 'uk';
                  targetLanguage = selectedLanguage == 'uk' ? 'en' : 'uk';
                }),
                decoration: InputDecoration(labelText: 'Мова'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text('Текст (використовуйте [img:N] для вставки зображень)')),
                  IconButton(
                    icon: Icon(Icons.translate),
                    tooltip: 'Перевести',
                    onPressed: isTranslating ? null : translateContent,
                  ),
                ],
              ),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(labelText: 'Текст оригіналу'),
                validator: (v) => v == null || v.isEmpty ? 'Введіть текст' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _translatedController,
                maxLines: 8,
                decoration: InputDecoration(labelText: 'Переклад'),
              ),
              SizedBox(height: 16),
              Text('Зображення (PNG, drag-n-drop або вибір):'),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ...List.generate(imagePreviews.length, (i) => Column(
                    children: [
                      Image.memory(imagePreviews[i], height: 60),
                      Text('[img:$i]'),
                      IconButton(
                        icon: Icon(Icons.add_photo_alternate),
                        tooltip: 'Вставить [img:$i]',
                        onPressed: () => insertImageMarkup(i),
                      ),
                    ],
                  )),
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate),
                    onPressed: pickImages,
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSaving ? null : saveNote,
                child: isSaving ? CircularProgressIndicator() : Text('Зберегти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 