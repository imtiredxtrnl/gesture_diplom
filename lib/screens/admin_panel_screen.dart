import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'admin_gestures_screen.dart';
import 'admin_tests_screen.dart';

class AdminPanelScreen extends StatelessWidget {
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
              AppLocalizations.of(context)!.total_users,
              '1',
              Icons.people,
              Colors.orange,
            ),
            SizedBox(height: 12),
            _buildStatCard(
              AppLocalizations.of(context)!.gestures_in_dict,
              '5',
              Icons.category,
              Colors.teal,
            ),
            SizedBox(height: 12),
            _buildStatCard(
              AppLocalizations.of(context)!.tests,
              '5',
              Icons.assignment,
              Colors.indigo,
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