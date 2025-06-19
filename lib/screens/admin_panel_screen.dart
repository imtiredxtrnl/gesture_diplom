import 'package:flutter/material.dart';
import 'package:sign_language_app/l10n/app_localizations.dart';
import 'admin_gestures_screen.dart';
import 'admin_tests_screen.dart';
import 'admin_notes_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int? usersCount;
  int? completedNotesCount;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final channel = WebSocketChannel.connect(Uri.parse(
        Platform.isAndroid ? 'ws://10.0.2.2:8765' : 'ws://localhost:8765',
      ));
      channel.sink.add('{"type": "stats"}');
      final resp = await channel.stream.first;
      channel.sink.close();
      final data = jsonDecode(resp);
      if (data['status'] == 'success') {
        setState(() {
          usersCount = data['users_count'];
          completedNotesCount = data['completed_notes_count'];
        });
      }
    } catch (e) {
      setState(() {
        usersCount = null;
        completedNotesCount = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            _buildSectionTitle(context, 'statistics'),
            SizedBox(height: 16),
            _buildStatCard(
              'Пользователи',
              usersCount != null ? usersCount.toString() : '...',
              Icons.people,
              Colors.orange,
            ),
            SizedBox(height: 12),
            _buildStatCard(
              'Пройдено конспектов',
              completedNotesCount != null ? completedNotesCount.toString() : '...',
              Icons.menu_book,
              Colors.deepPurple,
            ),
            SizedBox(height: 24),
            _buildAdminCard(
              context,
              AppLocalizations.of(context)!.tests_management,
              AppLocalizations.of(context)!.tests_management_desc,
              Icons.quiz,
              Colors.green[700]!,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminTestsScreen()),
              ),
            ),
            SizedBox(height: 12),
            _buildAdminCard(
              context,
              AppLocalizations.of(context)!.notes_management,
              AppLocalizations.of(context)!.notes_management_desc,
              Icons.menu_book,
              Colors.deepPurple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminNotesScreen(language: Localizations.localeOf(context).languageCode),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String key) {
    String localized;
    switch (key) {
      case 'statistics':
        localized = AppLocalizations.of(context)!.statistics;
        break;
      case 'gestures_in_dict':
        localized = AppLocalizations.of(context)!.gestures_in_dict;
        break;
      case 'tests':
        localized = AppLocalizations.of(context)!.tests;
        break;
      default:
        localized = key;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        localized,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color[700], size: 28),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 