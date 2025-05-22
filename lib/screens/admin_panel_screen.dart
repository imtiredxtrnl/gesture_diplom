import 'package:flutter/material.dart';
import 'admin_gestures_screen.dart';
import 'admin_alphabet_screen.dart';
import 'admin_tests_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Панель администратора',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          _buildSectionTitle('Управление контентом'),
          SizedBox(height: 16),
          _buildAdminCard(
            context,
            'Управление жестами',
            'Добавление, редактирование и удаление жестов',
            Icons.sign_language,
            Colors.purple[700]!,
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminGesturesScreen()),
            ),
          ),
          SizedBox(height: 12),
          _buildAdminCard(
            context,
            'Управление алфавитом',
            'Добавление и редактирование букв алфавита',
            Icons.text_fields,
            Colors.blue[700]!,
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminAlphabetScreen()),
            ),
          ),
          SizedBox(height: 12),
          _buildAdminCard(
            context,
            'Управление тестами',
            'Создание и редактирование тестов',
            Icons.quiz,
            Colors.green[700]!,
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminTestsScreen()),
            ),
          ),
          SizedBox(height: 24),
          _buildSectionTitle('Статистика'),
          SizedBox(height: 16),
          _buildStatCard('Всего пользователей', '24', Icons.people, Colors.orange),
          SizedBox(height: 12),
          _buildStatCard('Жестов в словаре', '48', Icons.category, Colors.teal),
          SizedBox(height: 12),
          _buildStatCard('Тестов', '15', Icons.assignment, Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
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