import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/test_model.dart';
import '../services/auth_service.dart';
import 'test_detail_screen.dart';
import '../services/admin_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TestsScreen extends StatefulWidget {
  @override
  _TestsScreenState createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  final AdminService _adminService = AdminService();
  List<Test> tests = [];
  bool isLoading = true;
  List<String> completedTests = [];

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() {
      isLoading = true;
    });
    try {
      final loadedTests = await _adminService.getAllTests();
      completedTests = AuthService.currentUser?.completedTests ?? [];
      setState(() {
        tests = loadedTests;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Помилка завантаження тестів: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tests),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tests.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.no_tests))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: tests.length,
        itemBuilder: (context, index) {
          final test = tests[index];
          final bool isCompleted = completedTests.contains(test.id);

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCompleted ? Colors.green : Colors.transparent,
                width: isCompleted ? 2 : 0,
              ),
            ),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestDetailScreen(test: test),
                  ),
                );

                if (result == true) {
                  // Тест був пройдений, оновлюємо UI
                  setState(() {
                    if (!completedTests.contains(test.id)) {
                      completedTests.add(test.id);
                    }
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCompleted ? Icons.quiz_outlined : Icons.quiz,
                        size: 30,
                        color: isCompleted ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.question,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.category + ': ${test.category}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (isCompleted)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                AppLocalizations.of(context)!.completed,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}