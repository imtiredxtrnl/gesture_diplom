import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.test),
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
                    Text(
                      widget.test.question,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.choose_correct_answer,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...List.generate(
                      widget.test.options.length,
                          (index) => _buildOptionCard(index),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (isSubmitted)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCorrect
                      ? AppLocalizations.of(context)!.correct
                      : AppLocalizations.of(context)!.incorrect,
                  style: TextStyle(
                    fontSize: 16,
                    color: isCorrect ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSubmitted
                  ? () => Navigator.pop(context, isCorrect)
                  : selectedOptionIndex != null
                  ? _checkAnswer
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isSubmitted ? AppLocalizations.of(context)!.finish : AppLocalizations.of(context)!.check_answer,
                style: TextStyle(fontSize: 16),
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

    // Визначення кольору картки залежно від стану
    Color cardColor = Colors.white;
    if (isSubmitted) {
      if (isCorrectOption) {
        cardColor = Colors.green[100]!;
      } else if (isSelected && !isCorrectOption) {
        cardColor = Colors.red[100]!;
      }
    } else if (isSelected) {
      cardColor = Colors.blue[50]!;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? (isSubmitted
              ? (isCorrectOption ? Colors.green : Colors.red)
              : Colors.blue)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isSubmitted ? null : () => _selectOption(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSubmitted && isCorrectOption)
                Icon(Icons.check_circle, color: Colors.green),
              if (isSubmitted && isSelected && !isCorrectOption)
                Icon(Icons.cancel, color: Colors.red),
            ],
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
      // Зберігаємо пройдений тест
      await AuthService.saveCompletedTest(widget.test.id);
    }
  }
}