import 'package:flutter/material.dart';
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

  Future<void> _saveTest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // В реальному застосунку тут був би API-запит на збереження
        // Для прикладу просто робимо затримку
        await Future.delayed(Duration(seconds: 1));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Тест успішно додано!')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка при збереженні тесту: $e')),
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
        title: Text('Додати тест'),
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
                'Основна інформація',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Питання тесту',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Будь ласка, введіть питання';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Категорія',
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
                'Варіанти відповідей',
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
                    'Зберегти тест',
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
                labelText: 'Варіант ${index + 1}',
                hintText: isCorrect ? 'Правильна відповідь' : 'Варіант відповіді',
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
                  return 'Будь ласка, введіть варіант відповіді';
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