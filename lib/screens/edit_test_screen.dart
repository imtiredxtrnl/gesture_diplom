// lib/screens/edit_test_screen.dart
import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/admin_service.dart';
import 'package:sign_language_app/l10n/app_localizations.dart';

class EditTestScreen extends StatefulWidget {
  final Test test;

  EditTestScreen({required this.test});

  @override
  _EditTestScreenState createState() => _EditTestScreenState();
}

class _EditTestScreenState extends State<EditTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  List<TextEditingController> _optionControllers = [];
  final AdminService _adminService = AdminService();

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

  static const int _minOptions = 2;
  static const int _maxOptions = 8;

  @override
  void initState() {
    super.initState();
    // Заполняем поля данными существующего теста
    _questionController.text = widget.test.question;
    _selectedCategory = widget.test.category;
    _correctOptionIndex = widget.test.correctOptionIndex;

    // Заполняем варианты ответов динамически
    _optionControllers = List.generate(
      widget.test.options.length < _minOptions ? _minOptions : widget.test.options.length,
      (i) => TextEditingController(
        text: i < widget.test.options.length ? widget.test.options[i] : '',
      ),
    );

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
    if (_optionControllers.length != widget.test.options.length) return true;
    for (int i = 0; i < _optionControllers.length; i++) {
      if (i >= widget.test.options.length || _optionControllers[i].text != widget.test.options[i]) {
        return true;
      }
    }
    return false;
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'basic':
        return 'basic';
      case 'greetings':
        return 'greetings';
      case 'questions':
        return 'questions';
      case 'emotions':
        return 'emotions';
      case 'actions':
        return 'actions';
      case 'family':
        return 'family';
      case 'food':
        return 'food';
      case 'numbers':
        return 'numbers';
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
      final options = _optionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      final response = await _adminService.updateTest(
        id: widget.test.id,
        question: _questionController.text.trim(),
        options: options,
        correctOptionIndex: _correctOptionIndex,
        category: _selectedCategory,
      );
      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.success),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response['message'] ?? AppLocalizations.of(context)!.error);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error + ': $e'),
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
        title: Text(AppLocalizations.of(context)!.unsaved_changes),
        content: Text(AppLocalizations.of(context)!.unsaved_changes_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.stay),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.exit_without_saving),
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
          title: Text(AppLocalizations.of(context)!.edit_test),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: Icon(Icons.save),
                onPressed: _isLoading ? null : _saveTest,
                tooltip: AppLocalizations.of(context)!.save,
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
              Text(AppLocalizations.of(context)!.saving_changes),
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
                                AppLocalizations.of(context)!.editing_test,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.test_id + ': ${widget.test.id}',
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
                  AppLocalizations.of(context)!.main_info,
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
                    labelText: AppLocalizations.of(context)!.test_question + ' *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.validation_test_question;
                    }
                    if (value.trim().length < 10) {
                      return AppLocalizations.of(context)!.validation_test_question_length;
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Категория
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.category + ' *',
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
                  AppLocalizations.of(context)!.answer_options,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                Column(
                  children: [
                    ...List.generate(_optionControllers.length, (index) => _buildOptionField(index)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: _optionControllers.length > _minOptions ? Colors.red : Colors.grey),
                          tooltip: AppLocalizations.of(context)!.remove_option,
                          onPressed: _optionControllers.length > _minOptions
                              ? () {
                                  setState(() {
                                    if (_optionControllers.length > _minOptions) {
                                      _optionControllers.last.dispose();
                                      _optionControllers.removeLast();
                                      if (_correctOptionIndex >= _optionControllers.length) {
                                        _correctOptionIndex = 0;
                                      }
                                    }
                                  });
                                  _onFieldChanged();
                                }
                              : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: _optionControllers.length < _maxOptions ? Colors.green : Colors.grey),
                          tooltip: AppLocalizations.of(context)!.add_option,
                          onPressed: _optionControllers.length < _maxOptions
                              ? () {
                                  setState(() {
                                    _optionControllers.add(TextEditingController());
                                    _optionControllers.last.addListener(_onFieldChanged);
                                  });
                                  _onFieldChanged();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 32),

                // Кнопки действий
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.cancel),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading || !_hasChanges ? null : _saveTest,
                        child: Text(AppLocalizations.of(context)!.save_changes),
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
                labelText: AppLocalizations.of(context)!.option + ' 	${index + 1}',
                hintText: isCorrect ? AppLocalizations.of(context)!.correct_answer : AppLocalizations.of(context)!.answer_option,
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
                if (_optionControllers.length <= _minOptions) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.validation_option;
                  }
                } else {
                  // Если больше двух, валидируем только первые два
                  if (index < 2 && (value == null || value.isEmpty)) {
                    return AppLocalizations.of(context)!.validation_option;
                  }
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