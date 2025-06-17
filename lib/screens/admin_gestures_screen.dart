// lib/screens/admin_gestures_screen.dart
import 'package:flutter/material.dart';
import '../models/gesture.dart';
import '../services/admin_service.dart';
import 'add_gesture_screen.dart';
import 'edit_gesture_screen.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class AdminGesturesScreen extends StatefulWidget {
  @override
  _AdminGesturesScreenState createState() => _AdminGesturesScreenState();
}

class _AdminGesturesScreenState extends State<AdminGesturesScreen> {
  final AdminService _adminService = AdminService();
  List<Gesture> gestures = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGestures();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadGestures() async {
    setState(() {
      isLoading = true;
    });
    try {
      final loadedGestures = await _adminService.getAllGestures();
      setState(() {
        gestures = loadedGestures;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading gestures: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error_loading_gestures + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Gesture> get filteredGestures {
    if (searchQuery.isEmpty) {
      return gestures;
    }
    return gestures.where((gesture) =>
    gesture.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        gesture.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
        gesture.description.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'basic':
        return category;
      case 'greetings':
        return category;
      case 'questions':
        return category;
      case 'emotions':
        return category;
      case 'actions':
        return category;
      case 'family':
        return category;
      case 'food':
        return category;
      case 'numbers':
        return category;
      default:
        return category;
    }
  }

  Future<void> _deleteGesture(Gesture gesture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete_gesture),
        content: Text(AppLocalizations.of(context)!.confirm_delete_gesture + ' "${gesture.name}"?\n\n' + AppLocalizations.of(context)!.delete_gesture_cannot_be_undone),
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

    if (confirmed == true) {
      try {
        await _adminService.deleteGesture(gesture.id);
        _loadGestures();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.gesture + ' "${gesture.name}" ' + AppLocalizations.of(context)!.deleted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.error_deleting_gesture + ': $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.gestures_management),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadGestures,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search_gestures,
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Статистика
          if (!isLoading)
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.total_gestures + ': ${gestures.length}',
                    style: TextStyle(
                      color: Colors.deepPurple[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    Text(
                      ' • ' + AppLocalizations.of(context)!.found + ': ${filteredGestures.length}',
                      style: TextStyle(
                        color: Colors.deepPurple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

          SizedBox(height: 16),

          // Список жестов
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.loading_gestures),
                ],
              ),
            )
                : filteredGestures.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gesture_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    searchQuery.isNotEmpty
                        ? AppLocalizations.of(context)!.gestures_not_found
                        : AppLocalizations.of(context)!.no_gestures_to_display,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    SizedBox(height: 8),
                  if (searchQuery.isNotEmpty)
                    Text(
                      AppLocalizations.of(context)!.try_again_with_different_search,
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddGestureScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadGestures();
                      }
                    },
                    icon: Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.add_first_gesture),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadGestures,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredGestures.length,
                itemBuilder: (context, index) {
                  final gesture = filteredGestures[index];
                  return _buildGestureItem(gesture);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGestureScreen()),
          );
          if (result == true) {
            _loadGestures();
          }
        },
        child: Icon(Icons.add),
        tooltip: AppLocalizations.of(context)!.add_gesture,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGestureItem(Gesture gesture) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditGestureScreen(gesture: gesture),
            ),
          );
          if (result == true) {
            _loadGestures();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Изображение жеста или заглушка
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (gesture.imageBase64?.isNotEmpty ?? false)
                      ? Image.memory(
                          base64Decode(gesture.imageBase64!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.gesture,
                              size: 30,
                              color: Colors.grey[400],
                            );
                          },
                        )
                      : gesture.imagePath.isNotEmpty
                          ? Image.asset(
                              gesture.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.gesture,
                                  size: 30,
                                  color: Colors.grey[400],
                                );
                              },
                            )
                          : Icon(
                              Icons.gesture,
                              size: 30,
                              color: Colors.grey[400],
                            ),
                ),
              ),

              SizedBox(width: 12),

              // Информация о жесте
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            gesture.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getCategoryDisplayName(gesture.category),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.deepPurple[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      gesture.description.length > 60
                          ? '${gesture.description.substring(0, 60)}...'
                          : gesture.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.id + ': ${gesture.id}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Кнопки действий
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditGestureScreen(gesture: gesture),
                        ),
                      );
                      if (result == true) {
                        _loadGestures();
                      }
                    },
                    tooltip: AppLocalizations.of(context)!.edit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteGesture(gesture),
                    tooltip: AppLocalizations.of(context)!.delete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}