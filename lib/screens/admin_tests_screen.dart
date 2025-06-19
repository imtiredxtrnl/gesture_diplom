import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/test_model.dart';
import 'add_test_screen.dart';
import '../services/admin_service.dart';
import 'package:sign_language_app/l10n/app_localizations.dart';
import 'edit_test_screen.dart';

class AdminTestsScreen extends StatefulWidget {
  @override
  _AdminTestsScreenState createState() => _AdminTestsScreenState();
}

class _AdminTestsScreenState extends State<AdminTestsScreen> {
  final AdminService _adminService = AdminService();
  List<Test> tests = [];
  bool isLoading = true;
  String searchQuery = '';

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

  List<Test> get filteredTests {
    if (searchQuery.isEmpty) {
      return tests;
    }
    return tests.where((test) =>
    test.question.toLowerCase().contains(searchQuery.toLowerCase()) ||
        test.category.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _showDeleteConfirmation(Test test) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete_test),
        content: Text(AppLocalizations.of(context)!.confirm_delete_test + ' "${test.question}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteTest(test);
    }
  }

  Future<void> _deleteTest(Test test) async {
    try {
      await _adminService.deleteTest(test.id);
      _loadTests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.success + ' "${test.question}"'),
            duration: Duration(seconds: 5),
          ),
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tests_management),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTests,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search_tests,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredTests.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.no_tests))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredTests.length,
              itemBuilder: (context, index) {
                final test = filteredTests[index];
                return _buildTestItem(test);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTestScreen()),
          );
          if (result == true) {
            _loadTests();
          }
        },
        child: Icon(Icons.add),
        tooltip: AppLocalizations.of(context)!.add_test,
      ),
    );
  }

  Widget _buildTestItem(Test test) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.quiz,
            color: Colors.grey[600],
          ),
        ),
        title: Text(
          test.question,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.category + ': ${test.category}'),
            SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.options + ': ${test.options.length}'),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditTestScreen(test: test)),
                );
                if (result == true) {
                  _loadTests();
                }
              },
              tooltip: AppLocalizations.of(context)!.edit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(test),
              tooltip: AppLocalizations.of(context)!.delete,
            ),
          ],
        ),
      ),
    );
  }
}