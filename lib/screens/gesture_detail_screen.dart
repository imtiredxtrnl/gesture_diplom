import 'package:flutter/material.dart';
import '../models/gesture.dart';
import '../services/gesture_service.dart';
import 'gesture_practice_screen.dart';
import 'dart:convert';
import 'package:sign_language_app/l10n/app_localizations.dart';
import 'package:sign_language_app/services/auth_service.dart';

class GestureDetailScreen extends StatefulWidget {
  final Gesture gesture;

  GestureDetailScreen({required this.gesture});

  @override
  _GestureDetailScreenState createState() => _GestureDetailScreenState();
}

class _GestureDetailScreenState extends State<GestureDetailScreen> {
  final GestureService _gestureService = GestureService();
  bool isLearned = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfLearned();
  }

  Future<void> _checkIfLearned() async {
    final user = AuthService.currentUser;
    setState(() {
      isLearned = user?.completedGestures.contains(widget.gesture.id) ?? false;
    });
  }

  Future<void> _markAsLearned() async {
    try {
      final success = await _gestureService.markGestureAsLearned(widget.gesture.id);
      if (success) {
        setState(() {
          isLearned = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.learned),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error + ': $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gesture.name),
        actions: [
          if (!isLoading && !isLearned)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _markAsLearned,
              tooltip: AppLocalizations.of(context)!.mark_as_learned,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение жеста
            Container(
              width: double.infinity,
              height: 300,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (widget.gesture.imageBase64?.isNotEmpty ?? false)
                    ? Image.memory(
                        base64Decode(widget.gesture.imageBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.gesture,
                                  size: 100,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.image_unavailable,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : widget.gesture.imagePath.isNotEmpty
                        ? Image.asset(
                            widget.gesture.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.gesture,
                                      size: 100,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!.image_unavailable,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.gesture,
                                  size: 100,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.image_unavailable,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ), // <-- конец ClipRRect
            ), // <-- конец Container с изображением
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок с категорией и статусом
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.gesture.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      if (isLearned)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.learned,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Категория
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getCategoryDisplayName(widget.gesture.category),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Описание
                  Text(
                    AppLocalizations.of(context)!.description,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.gesture.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Инструкции по выполнению
                  Text(
                    AppLocalizations.of(context)!.follow_instructions,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),

                  _buildInstructionSteps(),

                  SizedBox(height: 32),

                  // Кнопки действий
                  Column(
                    children: [
                      // Кнопка практики
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GesturePracticeScreen(
                                  gesture: widget.gesture,
                                ),
                              ),
                            );

                            // Если жест был изучен в процессе практики
                            if (result == true) {
                              _checkIfLearned();
                              Navigator.pop(context, true);
                            }
                          },
                          icon: Icon(Icons.camera_alt, size: 24),
                          label: Text(
                            AppLocalizations.of(context)!.practice_with_camera,
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Кнопка "Отметить как изученный" (если еще не изучен)
                      if (!isLearned)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _markAsLearned,
                            icon: Icon(Icons.check, size: 20),
                            label: Text(
                              AppLocalizations.of(context)!.mark_as_learned,
                              style: TextStyle(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[700],
                              side: BorderSide(color: Colors.green[300]!),
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
          ],
        ),
      ), // <-- закрываем children: [ ... ]
    ); // <-- закрываем Scaffold
  }

  Widget _buildInstructionSteps() {
    final steps = _getStepsForGesture(widget.gesture.name);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
        final color = colors[index % colors.length];

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      step['description']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, String>> _getStepsForGesture(String gestureName) {
    switch (gestureName) {
      case 'Привет':
        return [
          {
            'title': 'Подготовка',
            'description': 'Поднимите руку на уровень плеча с раскрытой ладонью.'
          },
          {
            'title': 'Позиция',
            'description': 'Разверните ладонь к собеседнику, пальцы направлены вверх.'
          },
          {
            'title': 'Движение',
            'description': 'Слегка покачайте рукой из стороны в сторону.'
          },
        ];
      case 'Спасибо':
        return [
          {
            'title': 'Начальная позиция',
            'description': 'Поднесите руку ко рту, кончики пальцев касаются губ.'
          },
          {
            'title': 'Движение',
            'description': 'Плавно опустите руку вперед и вниз.'
          },
          {
            'title': 'Завершение',
            'description': 'Закончите движение с раскрытой ладонью, направленной к собеседнику.'
          },
        ];
      case 'Да':
        return [
          {
            'title': 'Формирование жеста',
            'description': 'Сожмите руку в кулак и поднимите большой палец вверх.'
          },
          {
            'title': 'Позиция',
            'description': 'Держите руку перед собой на уровне груди.'
          },
        ];
      case 'Хорошо':
        return [
          {
            'title': 'Формирование кольца',
            'description': 'Соедините большой и указательный палец в кольцо.'
          },
          {
            'title': 'Позиция остальных пальцев',
            'description': 'Остальные три пальца выпрямите и разведите.'
          },
        ];
      default:
        return [
          {
            'title': 'Изучение',
            'description': 'Внимательно рассмотрите изображение жеста.'
          },
          {
            'title': 'Повторение',
            'description': 'Повторите позицию рук как показано на картинке.'
          },
          {
            'title': 'Практика',
            'description': 'Попрактикуйтесь перед камерой для проверки правильности.'
          },
        ];
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'basic':
        return 'Базовые';
      case 'greetings':
        return 'Приветствие';
      case 'emotions':
        return 'Эмоции';
      case 'actions':
        return 'Действия';
      default:
        return category;
    }
  }
}