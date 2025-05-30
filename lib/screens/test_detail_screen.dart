import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/auth_service.dart';

class TestDetailScreen extends StatefulWidget {
  final Test test;

  TestDetailScreen({required this.test});

  @override
  _TestDetailScreenState createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  int? selectedOptionIndex;
  bool isSubmitted = false;
  bool isCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Тест'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Вопрос теста
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepPurple[200]!),
                      ),
                      child: Text(
                        widget.test.question,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 32),

                    // Информация о категории
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Категорія: ${widget.test.category}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                    Text(
                      'Оберіть правильну відповідь:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Варианты ответов
                    ...List.generate(
                      widget.test.options.length,
                          (index) => _buildOptionCard(index),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Результат проверки
            if (isSubmitted)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green[800] : Colors.red[800],
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isCorrect
                            ? 'Правильно! Ви успішно пройшли цей тест.'
                            : 'Неправильно. Спробуйте ще раз.',
                        style: TextStyle(
                          fontSize: 16,
                          color: isCorrect ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Кнопка проверки/завершения
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitted
                    ? () => Navigator.pop(context, isCorrect)
                    : selectedOptionIndex != null
                    ? _checkAnswer
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitted
                      ? Colors.grey[600]
                      : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isSubmitted ? 'Завершити' : 'Перевірити відповідь',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(int index) {
    final option = widget.test.options[index];
    final isSelected = selectedOptionIndex == index;
    final isCorrectOption = index == widget.test.correctOptionIndex;

    // Определение цвета карточки в зависимости от состояния
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey[300]!;

    if (isSubmitted) {
      if (isCorrectOption) {
        cardColor = Colors.green[50]!;
        borderColor = Colors.green[400]!;
      } else if (isSelected && !isCorrectOption) {
        cardColor = Colors.red[50]!;
        borderColor = Colors.red[400]!;
      }
    } else if (isSelected) {
      cardColor = Colors.deepPurple[50]!;
      borderColor = Colors.deepPurple[400]!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 4 : 2,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: isSubmitted ? null : () => _selectOption(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Номер варианта
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isSubmitted
                        ? (isCorrectOption ? Colors.green : Colors.red)
                        : Colors.deepPurple)
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Текст варианта
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: Colors.grey[800],
                    ),
                  ),
                ),

                // Иконки результата
                if (isSubmitted && isCorrectOption)
                  Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                if (isSubmitted && isSelected && !isCorrectOption)
                  Icon(Icons.cancel, color: Colors.red[600], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectOption(int index) {
    setState(() {
      selectedOptionIndex = index;
    });
  }

  void _checkAnswer() async {
    final isCorrectAnswer = selectedOptionIndex == widget.test.correctOptionIndex;

    setState(() {
      isSubmitted = true;
      isCorrect = isCorrectAnswer;
    });

    if (isCorrectAnswer) {
      // Сохраняем пройденный тест
      await AuthService.saveCompletedTest(widget.test.id);
    }
  }
}